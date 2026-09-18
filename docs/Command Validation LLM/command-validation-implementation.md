# Client-Side Command Validation — Implementation Plan

Implements the approach chosen in [command-validation-research.md](command-validation-research.md): a deterministic dictionary lookup as the fast path, with an LLM fallback (via a new minimal backend proxy) only when a token isn't found — for typo/synonym tolerance and for phrasing the player-facing message.

---

## 1. Architecture overview

```
┌─────────────────────────────┐        ┌──────────────────────────┐        ┌─────────────┐
│ packages/client              │        │ packages/command-proxy    │        │ Claude API   │
│                               │        │ (new — holds API key)     │        │              │
│  dictionaryCache.ts  ◄────────┼─torii──┤                            │        │              │
│  (Dict table, localStorage)  │        │  POST /validate-token      │───────►│ messages.create│
│                               │        │                            │◄───────┤ (Haiku 4.5)   │
│  commandValidator.ts          │───────►│                            │        └─────────────┘
│  (tokenize + lookup)         │  HTTPS │                            │
│                               │◄───────┤                            │
│  commandHandler.ts (existing) │        └──────────────────────────┘
└─────────────────────────────┘
```

- **Fast path** (dictionaryCache + commandValidator, both pure client-side TS): tokenize the command, look up each word against the cached `Dict` table. No network call. This handles the overwhelming majority of commands.
- **Fallback path** (only on a lookup miss): the client calls the new proxy with the missing word + candidate list; the proxy calls Claude and returns a small structured verdict + message.
- The proxy is the only thing that ever sees the Anthropic API key — never the browser (see research doc, "Constraint" section).

---

## 2. New package: the validation proxy

Add `packages/command-proxy` (name is a placeholder — pick whatever fits the monorepo's naming; the point is it's a new workspace member, not a modification of `packages/client`).

### 2.1 Why a new package instead of piggybacking on something existing

There is currently no backend package in this repo (`packages/client`, `packages/contracts`, `packages/starknet` — confirmed by reading `mprocs.local.yaml` / `mprocs.stage.yaml`, which only run `katana`, `torii`, `contracts`, `client`). This is genuinely new infrastructure. Keep it as small as possible: one route, no database, no session state — it exists purely to keep the API key off the client.

### 2.2 Minimal shape (Bun + Hono, matching the repo's existing Bun-based tooling)

```
packages/command-proxy/
  src/
    index.ts          // Hono app, single POST route
    schema.ts          // Zod request/response schemas
  package.json
  .env.example          // ANTHROPIC_API_KEY=
```

```ts
// packages/command-proxy/src/schema.ts
import { z } from "zod";

export const TokenTypeSchema = z.enum([
  "Verb", "Direction", "Article", "Preposition",
  "Pronoun", "Adjective", "Noun", "Quantifier", "Interrogative",
]); // mirrors TokenType in command_type.cairo, minus Unknown/System

export const ValidateRequestSchema = z.object({
  word: z.string().min(1).max(30),          // the token that missed an exact match
  expectedType: TokenTypeSchema,             // what role it needed to fill (Verb / Noun / Noun-as-target)
  candidates: z.array(z.string()).max(200),  // known words of that TokenType, from the client's cached dictionary
});

export const ValidateResponseSchema = z.object({
  matchedWord: z.string().nullable(), // best-guess known word if this looks like a typo/synonym, else null
  confidence: z.enum(["high", "low", "none"]),
  message: z.string(), // player-facing sentence, already phrased per the rules below
});
```

```ts
// packages/command-proxy/src/index.ts
import { Hono } from "hono";
import { cors } from "hono/cors";
import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { ValidateRequestSchema, ValidateResponseSchema } from "./schema";

const client = new Anthropic(); // reads ANTHROPIC_API_KEY from env — never sent to the browser
const app = new Hono();

app.use("/*", cors({ origin: [/* the deployed client origin(s) */] }));

app.post("/validate-token", async (c) => {
  const body = ValidateRequestSchema.safeParse(await c.req.json());
  if (!body.success) return c.json({ error: "invalid request" }, 400);
  const { word, expectedType, candidates } = body.data;

  const response = await client.messages.parse({
    model: "claude-haiku-4-5", // see research doc — cost/latency fit; bump to sonnet if judgment is too coarse
    max_tokens: 256,
    system:
      "You judge whether a player's typed word in a text-adventure game is a likely " +
      "typo or synonym of a known game word, and phrase a short, friendly in-universe " +
      "error message if not. Never invent a matchedWord that isn't in the candidates list.",
    messages: [{
      role: "user",
      content:
        `The player typed "${word}", expected to be a ${expectedType}. ` +
        `Known ${expectedType} words: ${candidates.join(", ")}. ` +
        `Is "${word}" a likely typo or synonym of one of these? If yes, set matchedWord ` +
        `to the exact known word and confidence to "high" (obvious typo) or "low" (plausible ` +
        `synonym, not certain). If no plausible match, matchedWord is null, confidence is "none", ` +
        `and message should tell the player their word isn't recognized, in one short sentence.`,
    }],
    output_config: { format: zodOutputFormat(ValidateResponseSchema) },
  });

  return c.json(response.parsed_output);
});

export default app;
```

This is illustrative, not final — exact framework choice (Hono vs. plain Bun `serve` vs. a Cloudflare Worker) is a deployment-target decision (see §6), not a design decision. The request/response schema and the "server holds the key, client sends only the miss" shape is what matters.

### 2.3 What the proxy is deliberately *not* doing

- Not proxying the whole command — only the single ambiguous token + a scoped candidate list. Keeps the prompt small (cheap, fast) and keeps the LLM from ever seeing full player input unnecessarily.
- Not doing the exact-match check — that already happened client-side before this endpoint is ever called.
- No auth/session handling — this is a stateless, low-value endpoint (worst case someone spams it and burns a bit of Haiku budget); rate-limit at the edge (Cloudflare/host-level) rather than building app-level auth for it.

---

## 3. Client: dictionary cache

New file: `packages/client/src/lib/commandValidation/dictionaryCache.ts`

Responsibilities:
- Fetch all `Dict` rows via the existing Dojo SDK query pattern (same shape as [dojo.store.ts:100-114](../../packages/client/src/lib/stores/dojo.store.ts#L100-L114), which already does `getDojoSdk().getEntities({ query })`).
- Store as a `Map<string, TokenTypeEnum>` (lowercased word → type) plus a `savedAt` timestamp, persisted to `localStorage`.
- On app load, if `Date.now() - savedAt > 12h` (or the cache is empty), refetch. Otherwise use the cached copy immediately — no blocking network call on every load.

```ts
// packages/client/src/lib/commandValidation/dictionaryCache.ts
import { getDojoSdk } from "@lib/stores/dojo.store";
import type { Dict } from "@lib/dojo_bindings/typescript/models.gen";

const STORAGE_KEY = "lore.dictionary.v1";
const TTL_MS = 12 * 60 * 60 * 1000;

type DictCache = { savedAt: number; entries: Record<string, string> }; // word -> tokenType

let inMemory: DictCache | null = null;

export async function ensureDictionaryFresh(): Promise<void> {
  const cached = loadFromStorage();
  if (cached && Date.now() - cached.savedAt < TTL_MS) {
    inMemory = cached;
    return;
  }
  await refreshDictionary();
}

async function refreshDictionary(): Promise<void> {
  const sdk = getDojoSdk();
  // query shape mirrors dojo.store.ts's existing getEntities() usage for the Dict model
  const rows: Dict[] = await fetchAllDictRows(sdk);
  const entries: Record<string, string> = {};
  for (const row of rows) {
    entries[row.word.toLowerCase()] = String(row.tokenType);
  }
  const cache: DictCache = { savedAt: Date.now(), entries };
  inMemory = cache;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(cache));
}

export function lookupWord(word: string): string | undefined {
  return inMemory?.entries[word.toLowerCase()];
}

export function wordsOfType(tokenType: string): string[] {
  if (!inMemory) return [];
  return Object.entries(inMemory.entries)
    .filter(([, t]) => t === tokenType)
    .map(([w]) => w);
}

function loadFromStorage(): DictCache | null {
  const raw = localStorage.getItem(STORAGE_KEY);
  return raw ? (JSON.parse(raw) as DictCache) : null;
}
```

`ensureDictionaryFresh()` is called once at app startup (wherever `LORE_CONFIG` / the Dojo SDK is initialized), not on every command.

---

## 4. Client: the validator

New file: `packages/client/src/lib/commandValidation/commandValidator.ts`

### 4.1 Parsing shape

The player-facing spec distinguishes **simple** commands (verb + subject, e.g. "use the door") from **complex** ones (verb + subject + preposition + target, e.g. "kick the ball to the window"). This mirrors the shape the contract's own lexer already builds (`Command.tokens`, `TokenType` in [command_type.cairo](../../packages/contracts/src/types/command_type.cairo)) — the client validator does not need to replicate the full server tokenizer, just enough to identify which word is the verb, which is the (first) noun after it, and which is the noun after a preposition, ignoring articles.

```ts
// packages/client/src/lib/commandValidation/commandValidator.ts
import { lookupWord, wordsOfType } from "./dictionaryCache";

const ARTICLES = new Set(["a", "an", "the"]);
const PREPOSITIONS = new Set(["in", "on", "with", "at", "to", "into", "out", "from", "off", "for", "by", "of"]);

export type ValidationResult =
  | { ok: true }
  | { ok: false; reason: "unknown_verb" | "unknown_subject" | "unknown_target"; word: string; expectedType: "Verb" | "Noun" };

export function parseCommandShape(command: string) {
  const words = command.trim().toLowerCase().split(/\s+/).filter((w) => !ARTICLES.has(w));
  const verb = words[0];
  const prepositionIndex = words.findIndex((w) => PREPOSITIONS.has(w));
  const subject = prepositionIndex === -1 ? words[1] : words.slice(1, prepositionIndex).pop();
  const target = prepositionIndex === -1 ? undefined : words.slice(prepositionIndex + 1).pop();
  return { verb, subject, target, isComplex: prepositionIndex !== -1 };
}

export function validateLocally(command: string): ValidationResult {
  const { verb, subject, target, isComplex } = parseCommandShape(command);

  if (!verb || lookupWord(verb) !== "Verb") {
    return { ok: false, reason: "unknown_verb", word: verb ?? "", expectedType: "Verb" };
  }
  if (!subject || lookupWord(subject) !== "Noun") {
    return { ok: false, reason: "unknown_subject", word: subject ?? "", expectedType: "Noun" };
  }
  if (isComplex && (!target || lookupWord(target) !== "Noun")) {
    return { ok: false, reason: "unknown_target", word: target ?? "", expectedType: "Noun" };
  }
  return { ok: true };
}
```

Order matters and matches the user's spec directly: verb checked first, then subject, then target — each failure short-circuits with the specific reason, so "verb exists, subject doesn't, target does" correctly reports `unknown_subject` rather than a generic failure.

### 4.2 The fallback call

```ts
// packages/client/src/lib/commandValidation/llmFallback.ts
import { wordsOfType } from "./dictionaryCache";
import type { ValidationResult } from "./commandValidator";

const PROXY_URL = LORE_CONFIG.env.VITE_COMMAND_PROXY_URL; // new env var, see §6

export async function askLlmFallback(failure: Extract<ValidationResult, { ok: false }>) {
  const res = await fetch(`${PROXY_URL}/validate-token`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      word: failure.word,
      expectedType: failure.expectedType,
      candidates: wordsOfType(failure.expectedType),
    }),
  });
  if (!res.ok) return null; // fail open to the static message — see §5
  return res.json() as Promise<{ matchedWord: string | null; confidence: "high" | "low" | "none"; message: string }>;
}
```

**Fail-open on proxy error**: if the proxy is down or the request errors, fall back to the static template message (§5) rather than blocking the player from acting. This is a UX assist, not a security or correctness gate — the contract still does its own validation server-side regardless of what this feature says.

---

## 5. Message templates

Static templates cover the exact-failure case without needing the LLM at all (only the *typo-suggestion* case genuinely needs the model's judgment):

| Case | Message |
|---|---|
| Unknown verb | "The action you're trying to execute is not possible. How about you try another verb?" |
| Unknown subject (verb + target both valid) | `"You're trying to {verb} something that doesn't exist to the {target}. Try with a valid object."` |
| Unknown target (verb + subject both valid) | `"Your target doesn't exist."` |
| Unknown verb+subject+target, but LLM found a high-confidence typo match | Show the corrected word inline, e.g. `"Did you mean 'kick the ball'?"` and optionally auto-substitute before sending. |
| Unknown verb+subject+target, LLM found no match | Static "unknown word" message for whichever slot failed, same as the no-LLM row above. |

`confidence: "low"` results are surfaced as a suggestion ("Did you mean...?") rather than auto-corrected — only `"high"` confidence should offer to resubmit automatically, and even then only with explicit confirmation. Never silently rewrite what the player typed.

---

## 6. Wiring into the existing terminal flow

Integration point: [commandHandler.ts:63](../../packages/client/src/lib/terminalCommands/commandHandler.ts#L63), right before `SystemCalls.execCommand(command, game_id)`.

```ts
// inside sendCommand(), before the SystemCalls.execCommand(...) call
if (!bypassSystem && !context.cmd.startsWith("_")) {
  const validation = validateLocally(command);
  if (!validation.ok) {
    const fallback = await askLlmFallback(validation);
    const message = fallback?.matchedWord
      ? `Did you mean "${command.replace(validation.word, fallback.matchedWord)}"?`
      : (fallback?.message ?? staticMessageFor(validation));
    addTerminalContent({ text: message, format: "error", useTypewriter: true });
    return; // don't send the transaction
  }
}
```

Keep this scoped to non-system, non-`_`-prefixed commands (same gating the file already uses at [commandHandler.ts:36](../../packages/client/src/lib/terminalCommands/commandHandler.ts#L36) and [commandHandler.ts:48](../../packages/client/src/lib/terminalCommands/commandHandler.ts#L48)) — system commands (`_connect_wallet`, `g_*`) aren't player vocabulary and shouldn't go through this pipeline.

Dictionary initialization: call `ensureDictionaryFresh()` once during client startup (alongside where `LORE_CONFIG`/Dojo SDK is set up), so the cache is ready before the first command is typed.

---

## 7. New env var

Add to `packages/client/src/lib/config.ts`'s `cleanEnv` block:

```ts
VITE_COMMAND_PROXY_URL: url({ default: undefined }),
```

...and to each `.env` / profile config (`config_profiles.ts`) per environment (local/stage/slot), pointing at wherever the proxy is deployed. The proxy itself needs `ANTHROPIC_API_KEY` set server-side only (never `VITE_`-prefixed, never in the client's env).

---

## 8. Deployment of the proxy — open decision

Not resolved by this plan; pick one before implementation starts:

- **Cloudflare Worker** — simplest, near-zero infra to maintain, fits a single-route stateless proxy well, cheap.
- **Small Bun server** co-deployed alongside wherever `packages/client`'s stage/slot builds are hosted, added as a new `mprocs` process for local dev (`bun run dev` under the new package) and a corresponding stage/slot entry.

Either works; the code in §2 is framework-light enough to port. Recommend starting with whichever the team already has hosting credentials/experience with, since this endpoint has minimal requirements (one route, no state, no database).

---

## 9. Testing plan

1. **Unit tests for `commandValidator.ts`** (no network, no LLM): given a mocked dictionary cache, assert `validateLocally()` returns the correct `reason` for each of: unknown verb, unknown subject, unknown target, all-valid simple command, all-valid complex command. This directly covers the four cases in the user's spec.
2. **Unit tests for `dictionaryCache.ts`**: staleness logic (mock `Date.now()`, verify refetch triggers past 12h and not before), storage round-trip.
3. **Proxy endpoint test**: given a fixed `candidates` list, assert the schema-validated response shape; a couple of fixed-fixture cases (obvious typo → high confidence; nonsense word → `none`) run against the real model in CI sparingly (LLM calls are nondeterministic — assert shape/schema, not exact wording).
4. **Manual verification** (per the repo's `/verify` skill guidance): run the dev stack (`bun run dev` via `mprocs.local.yaml`), type each of the four example commands from the user's spec into the terminal UI, confirm the exact message text shown matches the intended phrasing, and confirm a fully valid command still reaches `SystemCalls.execCommand` unchanged (no regression to the happy path).

---

## 10. File checklist

New:
- `packages/command-proxy/` (new workspace package — server, schema, package.json, env example)
- `packages/client/src/lib/commandValidation/dictionaryCache.ts`
- `packages/client/src/lib/commandValidation/commandValidator.ts`
- `packages/client/src/lib/commandValidation/llmFallback.ts`

Edited:
- `packages/client/src/lib/terminalCommands/commandHandler.ts` — validation call before `SystemCalls.execCommand`
- `packages/client/src/lib/config.ts` — `VITE_COMMAND_PROXY_URL`
- `packages/client/src/lib/config_profiles.ts` — per-profile proxy URL
- `mprocs.local.yaml` (and stage/slot equivalents) — new `command-proxy` process for local dev
