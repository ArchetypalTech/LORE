# Client-Side Command Validation — LLM Approach & Options

This document evaluates how to add LLM-assisted validation of player-typed commands ("kick the ball to the window") before they're sent to the contract, using [dictionary.cairo](../../packages/contracts/src/models/dictionary.cairo) as the source of truth for known verbs/nouns/directions. For the concrete LLM-based build-out see [command-validation-implementation.md](command-validation-implementation.md). **Option E below covers a zero-AI alternative** — its full build-out is [command-validation-implementation-no-ai.md](command-validation-implementation-no-ai.md).

---

## The actual problem being solved

The request breaks into two independent problems that are easy to conflate:

1. **Existence checking** — does the word "kick" exist in the dictionary as a `Verb`? Does "ball" exist as a `Noun`? This is a deterministic lookup against a table that already lives on-chain and is already queryable via Torii (`Dict` model, see [dictionary.cairo:11-19](../../packages/contracts/src/models/dictionary.cairo#L11-L19)).
2. **Message phrasing / fuzzy tolerance** — turning a failed lookup into a friendly sentence, and optionally recognizing that "kik" was probably supposed to be "kick".

Only problem 2 benefits from an LLM. Problem 1 is a hash-map lookup. Conflating them leads to routing every command through a network call to an LLM, which is slower, costs money per keystroke-adjacent action, and adds a point of failure to something that's currently instant and free.

**Recommendation: a fast deterministic path handles the common case, and the LLM is invoked only on a miss** — first to judge whether the miss is a likely typo/synonym, and to phrase the resulting message. This is elaborated in the implementation doc; the rest of this document focuses on the *why* and the *client-side constraints*.

---

## Constraint: this is a static SPA with no backend today

Checked the actual repo layout before proposing anything: `packages/` contains `client` (Vite React SPA), `contracts` (Cairo), and `starknet` (deploy scripts/bindings). There is no server package, and the client is built and served as static files (`"start": "serve -s /dist --port 8080"` in [package.json](../../packages/client/package.json)). `mprocs.local.yaml` / `mprocs.stage.yaml` only run `katana`, `torii`, `contracts`, and `client` — no application server.

This matters because the client already reads env vars through `envalid` with a `VITE_` prefix ([config.ts](../../packages/client/src/lib/config.ts)). **Anything under `import.meta.env.VITE_*` is inlined into the JS bundle at build time and is fully readable by anyone who opens dev tools or views the deployed bundle.** An Anthropic API key (or any LLM provider's key) placed in a `VITE_ANTHROPIC_API_KEY` would be exfiltrated by the first curious player, who could then run unlimited requests on the project's bill.

**Conclusion: an LLM call cannot be made directly from the browser with a real API key.** Something has to hold the credential server-side. This is the one non-negotiable architectural constraint and it shapes every option below.

---

## Options considered

### Option A — Add a small backend proxy that holds the API key (recommended)

A minimal server (new package, e.g. `packages/llm-proxy`, or a Cloudflare Worker / similar edge function) exposes one endpoint, e.g. `POST /validate-token`. The client sends only the ambiguous token(s) plus the relevant candidate list (verbs, or nouns — scoped by `TokenType`, not the whole dictionary); the server holds the Anthropic API key, calls the Claude API, and returns a small structured result.

**Pros:** key never leaves the server; the LLM call surface is minimal (a handful of words, not the whole conversation) so it's cheap and fast; this is the standard pattern for "LLM in a client app" and matches every serious per-request auth requirement (see `claude-api` skill: browser calls should never carry a real API key).

**Cons:** it's new infrastructure — a service to deploy, monitor, and secure (rate-limit, CORS) — where today there is none. This is real but small: the endpoint does one thing, takes trivial input, and can run on a free-tier edge function.

### Option B — Call the Claude API directly from the browser

Rejected outright. Even with a restricted/short-lived key, the `claude-api` skill's own guidance is explicit that browser-side calls need a server in the loop; Anthropic does not offer a "public, safely embeddable" client key model for this kind of always-on production feature the way e.g. Stripe's publishable keys work. Any key embedded in a Vite `VITE_*` var is extractable.

### Option C — Run a model entirely in-browser (WebLLM / transformers.js / similar)

Rejected for this feature. It avoids the key problem entirely (no network call at all), but:
- Ships megabytes of model weights to every player just to answer "is 'kick' a valid verb," a question a 50-line TypeScript function already answers from the cached dictionary.
- Quality of a browser-sized model on typo/synonym judgment is worse than a hosted frontier model, for a feature whose entire value is a well-phrased, well-judged fallback message.
- Doesn't help with phrasing quality either — the smaller the local model, the more generic/wrong the "friendly" message tends to read.

This would only make sense if the project had a broader roadmap need for offline/local inference elsewhere. It doesn't currently.

### Option D — Skip the LLM for existence-checking; use it only for phrasing + fuzzy fallback (adopted, layered on Option A)

This isn't a separate infrastructure option — it's the request-shaping decision that makes Option A cheap and fast:

- **Exact match found in cache** (the overwhelming majority of commands): resolve entirely client-side, zero network calls beyond the periodic dictionary sync. Instant.
- **Exact match missed**: call the Option A backend with just the missing word(s) + the relevant candidate list, ask the LLM to (a) judge if it's a near-miss typo/synonym of a known word, and (b) phrase the appropriate one of the three response messages the user specified (bad verb / bad subject / bad target).

This is the shape covered in the implementation doc.

### Option E — No AI model at all: algorithmic fuzzy matching (alternative to A/D)

Both problems from the opening section can be solved without an LLM or any network call:

- **Existence checking**: unchanged from Option D — deterministic lookup against the cached `Dict` table.
- **Fuzzy/typo tolerance**: instead of asking an LLM to judge whether "kik" is close to "kick," compute **edit distance** (Levenshtein / Damerau-Levenshtein) between the unrecognized word and every candidate word of the expected `TokenType`, and accept the closest match under a small distance threshold (e.g. distance ≤ 2, or scaled by word length). This is a well-understood, decades-old technique for exactly this kind of "did the user mistype a known word from a small closed vocabulary" problem, and it runs in microseconds against dictionaries of this size (the game's verb/noun list is small — see [dictionary.cairo:59-230](../../packages/contracts/src/models/dictionary.cairo#L59-L230)).
- **Synonym tolerance**: largely already handled *without any fuzzy logic at all* — the dictionary already registers multiple words at the same `n_value` as synonyms (e.g. `"quaff"`/`"drink"`, `"consume"`/`"eat"`, `"speak"`/`"talk"` all map to the same verb id in [dictionary.cairo:59-126](../../packages/contracts/src/models/dictionary.cairo#L59-L126)), and entity `alt_names` are registered as additional `Noun` dictionary entries at creation time ([designer.cairo:456-462](../../packages/contracts/src/systems/designer.cairo#L456-L462)). A synonym the dictionary doesn't know about isn't something an LLM should silently paper over either — it's a content gap the designer should close by adding an `alt_name`, which is the mechanism the game already has for exactly this.
- **Message phrasing**: fully covered by the static templates already specified for Option D (verb/subject/target failure cases) — none of the four required messages need generative phrasing, and the "did you mean X?" suggestion is a simple string template using the matched word, not a generated sentence.

**Pros:** no proxy, no API key, no hosting decision, no per-request cost, no network dependency, no latency — the entire validation path (including the fuzzy fallback) runs synchronously in the browser against the cached dictionary. Removes every concern raised in the "Constraint" section above, because there's no LLM call to secure. Deterministic and testable — the same input always produces the same output, which an LLM fallback does not guarantee.

**Cons:** edit-distance matching is purely syntactic — it won't infer a semantic synonym the dictionary doesn't already know about (e.g. it won't connect "hurl" to "throw" unless that mapping is curated in as an alt-word), where an LLM might. For this game's vocabulary — a small, curated, closed set that the designer already actively extends via `alt_names` — that's a reasonable trade: the "right" fix for an unrecognized synonym is adding it to the dictionary, not asking a model to guess at it, in a game whose accepted vocabulary is authoritative and versioned in code.

**This is the recommended default going forward** given the infrastructure cost the LLM-based approach (Options A/D) requires. See [command-validation-implementation-no-ai.md](command-validation-implementation-no-ai.md) for the full build-out. Options A/D remain documented above as the path to revisit if the game's command vocabulary grows large/open-ended enough that curated synonyms and edit-distance stop being sufficient.

---

## Model choice

*(Applies only if the LLM-based fallback — Options A/D — is chosen instead of Option E.)*

For the fallback classification+phrasing call: this is a small, low-latency, low-stakes classification task (a handful of words in, a short JSON + one sentence out) — a good fit for **Claude Haiku 4.5** (`claude-haiku-4-5`) on cost and latency grounds, since players will notice added delay on every failed command. Default guidance in this codebase's tooling is to use Opus 4.8 unless a cheaper/faster model is explicitly justified; this is exactly that case — recommend Haiku 4.5, but this is the user's call to confirm since it trades a small amount of judgment quality for speed and ~5x lower cost per request. Sonnet 5 is the middle ground if Haiku's typo/synonym judgment turns out too coarse in testing.

Either way, this should be a single non-streaming `messages.create()` call with a small `output_config.format` JSON schema (see implementation doc) — no tool use, no agent loop, no thinking needed for a task this narrow.

---

## Dictionary sync: what "every 12h" means in a browser

The dictionary only changes when a designer calls `create_entity` (which registers `alt_names` as `Noun` entries — [designer.cairo:456-462](../../packages/contracts/src/systems/designer.cairo#L456-L462)) or when new verbs are added to `_init_dictionary` in a contract upgrade. It does not change during normal gameplay. A literal cron-style "refresh every 12 hours" doesn't map cleanly onto a browser tab, which has no background execution when closed and no guaranteed uptime while open.

The practical equivalent: cache the full `Dict` table (already fetchable via the existing Dojo SDK query pattern seen in [dojo.store.ts:100-114](../../packages/client/src/lib/stores/dojo.store.ts#L100-L114)) in `localStorage` with a timestamp, and refresh it lazily — check staleness (`> 12h old`) once per app load / once per session, not on a running timer. This gets the same practical effect (never more than half a day stale, and typically much fresher since most sessions start with a fresh check) without any browser-background-process complexity. Details in the implementation doc.

---

## Summary recommendation

| Layer | Approach |
|---|---|
| Existence check (verb/subject/target) | Deterministic TS lookup against a client-cached copy of the `Dict` table. No LLM. |
| Dictionary freshness | Lazy staleness check against `localStorage` timestamp on app load, not a running timer. |
| Fuzzy/typo tolerance | LLM fallback, invoked only on a cache miss, scoped to the single missing token + same-`TokenType` candidates. |
| Message phrasing | Same LLM call as fuzzy tolerance produces the final message; exact-match failures can use static templates (no LLM needed) since the case is already fully known. |
| Where the LLM call runs | A new minimal backend/edge proxy that holds the API key — never the browser directly. |
| Model | Claude Haiku 4.5 by default for cost/latency; Sonnet 5 if judgment quality needs it. |

Main tradeoff to flag back to the user: this only works well if "exact-match-in-cache" covers the vast majority of real commands (true today, since gameplay verbs/nouns are a small closed-ish set) — if the game later leans into much more free-form input, the LLM's role would need to grow beyond a fallback.

**Note:** the table above describes the LLM-based path (Options A/D). See Option E above for the recommended zero-AI alternative — same existence-check row, but no proxy/API key/hosting and a static, algorithmic fuzzy-match fallback instead of an LLM call. Full build-out in [command-validation-implementation-no-ai.md](command-validation-implementation-no-ai.md).
