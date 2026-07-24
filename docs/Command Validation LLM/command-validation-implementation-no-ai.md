# Client-Side Command Validation — No-AI Implementation Plan

Implements **Option E** from [command-validation-research.md](command-validation-research.md): the same deterministic dictionary-lookup fast path as the LLM-based plan, but with the fallback (typo/synonym tolerance + message phrasing) done entirely with algorithmic edit-distance matching and static templates — no LLM, no proxy, no API key, no backend at all.

This entirely supersedes the infrastructure in [command-validation-implementation.md](command-validation-implementation.md) (§§2, 6, 8 there — the proxy package, env var, deployment decision) while reusing its dictionary-cache and parsing design almost verbatim. Read this doc standalone; it does not assume the other implementation doc was built.

---

## 1. Architecture overview

```
┌───────────────────────────────────────────────────┐
│ packages/client                                     │
│                                                       │
│  dictionaryCache.ts   (Dict table, localStorage)     │
│         │                                             │
│         ▼                                             │
│  commandValidator.ts  (tokenize + exact lookup)       │
│         │ miss                                        │
│         ▼                                             │
│  fuzzyMatch.ts         (edit distance vs candidates)  │
│         │                                             │
│         ▼                                             │
│  messages.ts           (static template lookup)      │
│         │                                             │
│         ▼                                             │
│  commandHandler.ts (existing — sendCommand)           │
└───────────────────────────────────────────────────┘
```

Everything runs synchronously in the browser, entirely from the cached dictionary. There is no network call anywhere in this pipeline beyond the existing periodic dictionary sync (same as the LLM plan's §3). No new package, no new env var, no new deployment target.

---

## 2. Client: dictionary cache

Identical to §3 of [command-validation-implementation.md](command-validation-implementation.md) — reuse that design verbatim:

`packages/client/src/lib/commandValidation/dictionaryCache.ts`

- Fetch all `Dict` rows via the existing Dojo SDK query pattern ([dojo.store.ts:100-114](../../packages/client/src/lib/stores/dojo.store.ts#L100-L114)).
- Store as `word (lowercased) -> tokenType` plus a `savedAt` timestamp, persisted to `localStorage`.
- Lazy 12h staleness check on app load (`ensureDictionaryFresh()`), not a running timer.

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
  const rows: Dict[] = await fetchAllDictRows(sdk); // same Torii query pattern as dojo.store.ts
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

`ensureDictionaryFresh()` is called once at client startup, same as the LLM plan.

---

## 3. Client: the validator (exact match — unchanged from the LLM plan)

`packages/client/src/lib/commandValidation/commandValidator.ts`

Same parsing shape and precedence as the LLM-based plan §4.1: strip articles, identify verb / subject / (optional) target by position relative to the first preposition, check verb first, then subject, then target.

```ts
// packages/client/src/lib/commandValidation/commandValidator.ts
import { lookupWord } from "./dictionaryCache";

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

---

## 4. Fuzzy matcher (replaces the LLM fallback entirely)

New file: `packages/client/src/lib/commandValidation/fuzzyMatch.ts`

A plain Damerau-Levenshtein edit-distance implementation (transposition-aware, so "kcik" → "kick" — an adjacent-letter swap — is a single edit, not two) plus a threshold, run against the same-`TokenType` candidate list from the dictionary cache. No third-party dependency needed — the algorithm is ~20 lines and keeping it in-repo avoids adding a package for something this small.

```ts
// packages/client/src/lib/commandValidation/fuzzyMatch.ts
import { wordsOfType } from "./dictionaryCache";

/** Damerau-Levenshtein edit distance (insertions, deletions, substitutions, adjacent transpositions). */
function editDistance(a: string, b: string): number {
  const d: number[][] = Array.from({ length: a.length + 1 }, () => new Array(b.length + 1).fill(0));
  for (let i = 0; i <= a.length; i++) d[i][0] = i;
  for (let j = 0; j <= b.length; j++) d[0][j] = j;

  for (let i = 1; i <= a.length; i++) {
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      d[i][j] = Math.min(
        d[i - 1][j] + 1,       // deletion
        d[i][j - 1] + 1,       // insertion
        d[i - 1][j - 1] + cost, // substitution
      );
      if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) {
        d[i][j] = Math.min(d[i][j], d[i - 2][j - 2] + cost); // transposition
      }
    }
  }
  return d[a.length][b.length];
}

/** Distance threshold scales with word length so short words aren't over-matched. */
function thresholdFor(word: string): number {
  if (word.length <= 3) return 1;
  if (word.length <= 6) return 2;
  return 3;
}

export type FuzzyMatch = { word: string; distance: number; confidence: "high" | "low" };

/** Best candidate of the given TokenType within threshold, or null if nothing close enough. */
export function fuzzyMatch(word: string, expectedType: "Verb" | "Noun"): FuzzyMatch | null {
  const candidates = wordsOfType(expectedType);
  const threshold = thresholdFor(word);

  let best: FuzzyMatch | null = null;
  for (const candidate of candidates) {
    const distance = editDistance(word, candidate);
    if (distance > threshold) continue;
    if (!best || distance < best.distance) {
      best = { word: candidate, distance, confidence: distance <= 1 ? "high" : "low" };
    }
  }
  return best;
}
```

**Threshold tuning**: `thresholdFor()` above is a starting point (distance 1 for ≤3-letter words, 2 for ≤6, 3 above), not a tuned constant — see §7 for how to validate it against the real dictionary before shipping, since a threshold that's too loose will "correct" genuinely different short words into each other (e.g. "go" → "do" at distance 1 is plausible; too aggressive a threshold on longer words risks false positives across an unrelated pair).

**Ties**: if two candidates are equally close, this returns whichever was encountered first in `wordsOfType()`'s iteration order — acceptable for a "suggestion," not a silent auto-correct (see §5), but worth knowing if a test asserts a specific word.

---

## 5. Message templates (static — no generation of any kind)

New file: `packages/client/src/lib/commandValidation/messages.ts`

```ts
// packages/client/src/lib/commandValidation/messages.ts
import type { ValidationResult } from "./commandValidator";
import { fuzzyMatch } from "./fuzzyMatch";

export function messageFor(failure: Extract<ValidationResult, { ok: false }>, fullCommand: string): string {
  const match = fuzzyMatch(failure.word, failure.expectedType);
  if (match && match.confidence === "high") {
    const corrected = fullCommand.replace(failure.word, match.word);
    return `Did you mean "${corrected}"?`;
  }

  switch (failure.reason) {
    case "unknown_verb":
      return "The action you're trying to execute is not possible. How about you try another verb?";
    case "unknown_subject":
      return `You're trying to ${failure.word || "do something"} something that doesn't exist. Try with a valid object.`;
    case "unknown_target":
      return "Your target doesn't exist.";
  }
}
```

This directly matches the four cases from the original spec:
- Verb missing (subject/target fine) → "not possible... try another verb" template.
- Verb fine, subject missing, target fine → "trying to `{verb}` something that doesn't exist... try with a valid object."
- Verb fine, subject fine, target missing → "your target doesn't exist."
- Any of the above, but the missing word is a **high-confidence** edit-distance match (distance ≤ 1) → "Did you mean...?" suggestion instead, offering the corrected full command.

`low`-confidence fuzzy matches (distance 2–3) intentionally fall through to the static "not recognized" message rather than suggesting a shaky guess — only near-certain typos (distance ≤ 1, i.e. one letter off or one transposition) get the "did you mean" treatment. This mirrors the confidence gating in the LLM-based plan (§5 there) but with a fixed, inspectable rule instead of a model's judgment call.

---

## 6. Wiring into the existing terminal flow

Integration point: [commandHandler.ts:63](../../packages/client/src/lib/terminalCommands/commandHandler.ts#L63), right before `SystemCalls.execCommand(command, game_id)` — same location as the LLM-based plan, but the call is synchronous (no `await`, no network, no fail-open branch needed since there's nothing that can fail):

```ts
// inside sendCommand(), before the SystemCalls.execCommand(...) call
import { validateLocally } from "@lib/commandValidation/commandValidator";
import { messageFor } from "@lib/commandValidation/messages";

if (!bypassSystem && !context.cmd.startsWith("_")) {
  const validation = validateLocally(command);
  if (!validation.ok) {
    addTerminalContent({
      text: messageFor(validation, command),
      format: "error",
      useTypewriter: true,
    });
    return; // don't send the transaction
  }
}
```

Keep this scoped to non-system, non-`_`-prefixed commands, same gating already used at [commandHandler.ts:36](../../packages/client/src/lib/terminalCommands/commandHandler.ts#L36) and [commandHandler.ts:48](../../packages/client/src/lib/terminalCommands/commandHandler.ts#L48) — system commands aren't player vocabulary and shouldn't go through this pipeline.

Dictionary initialization: call `ensureDictionaryFresh()` once during client startup, same as the LLM plan.

---

## 7. Testing plan

1. **Unit tests for `commandValidator.ts`** — identical cases to the LLM plan: unknown verb / unknown subject / unknown target / valid simple / valid complex, given a mocked dictionary cache.
2. **Unit tests for `fuzzyMatch.ts`** — this is the part that needs the most scrutiny since it's a hand-rolled algorithm with a tunable threshold:
   - Known-typo cases return the right word at `confidence: "high"` (e.g. `"kcik"` → `"kick"`, `"exmine"` → `"examine"`).
   - Genuinely unrelated short words do **not** match (e.g. `"cat"` should not fuzzy-match `"eat"` at the ≤3-letter threshold — validate the threshold table doesn't over-trigger on the game's actual short-word list, which is small enough to enumerate: `"go"`, `"in"`, `"up"`, `"l"`, `"x"`, `"i"`, etc. from [dictionary.cairo](../../packages/contracts/src/models/dictionary.cairo)).
   - Run the matcher against every pair of words *already in* the real dictionary (`_init_dictionary()` in dictionary.cairo) and assert no two distinct real words fall within each other's threshold — this is the concrete regression test that catches a too-loose threshold before it ships (e.g. if `"in"` and `"on"` ever end up within distance 1 of each other at the 3-letter tier, that's a bug to fix in `thresholdFor()`, not a runtime surprise).
3. **Unit tests for `messages.ts`** — assert exact string output for all four spec cases, plus the high/low confidence branch.
4. **Manual verification** (per the repo's `/verify` skill): run `bun run dev` via `mprocs.local.yaml`, type each of the four example commands plus a couple of deliberate typos ("kcik the ball to the window") into the terminal UI, confirm message text and that a fully valid command still reaches `SystemCalls.execCommand` unchanged.

---

## 8. File checklist

New:
- `packages/client/src/lib/commandValidation/dictionaryCache.ts`
- `packages/client/src/lib/commandValidation/commandValidator.ts`
- `packages/client/src/lib/commandValidation/fuzzyMatch.ts`
- `packages/client/src/lib/commandValidation/messages.ts`

Edited:
- `packages/client/src/lib/terminalCommands/commandHandler.ts` — validation call before `SystemCalls.execCommand`

Not needed (unlike the LLM-based plan): no new package, no `VITE_COMMAND_PROXY_URL` env var, no `config_profiles.ts` change, no proxy deployment, no `mprocs` changes.

---

## 9. When to revisit the LLM-based plan instead

This algorithmic approach is bounded by the dictionary's size and the designer's diligence in adding `alt_names`/synonyms. Revisit [command-validation-implementation.md](command-validation-implementation.md) if:
- The vocabulary grows large enough that edit-distance false-positive/negative rates become a real problem (hundreds+ of verbs/nouns with many near-neighbors).
- The design intent shifts toward accepting much more free-form, natural-language player input rather than a curated command vocabulary — at that point genuine language understanding, not typo-correction, is the actual requirement, and that's a different feature.
