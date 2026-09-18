# Client-Side Command Validation — In-Browser Model Implementation Plan

Implements **Option C** from [command-validation-research.md](command-validation-research.md): run a small LLM entirely inside the player's browser (no server, no API key, no network call at inference time) to judge typo/synonym fallbacks and phrase messages. This doc exists for completeness and comparison — **it is not the recommended path**; see §7 for why, and see [command-validation-implementation-no-ai.md](command-validation-implementation-no-ai.md) (Option E, recommended) and [command-validation-implementation.md](command-validation-implementation.md) (Option A/D, cloud LLM via proxy) for the alternatives.

Reuses the dictionary cache and exact-match validator unchanged from both other implementation docs — only the fallback path differs.

---

## 1. Architecture overview

```
┌───────────────────────────────────────────────────────────┐
│ packages/client                                              │
│                                                                │
│  dictionaryCache.ts   (unchanged — Dict table, localStorage)  │
│         │                                                      │
│         ▼                                                      │
│  commandValidator.ts  (unchanged — tokenize + exact lookup)   │
│         │ miss                                                 │
│         ▼                                                      │
│  localModel/                                                   │
│    modelLoader.ts     (feature-detect WebGPU, load + cache     │
│                         model weights via browser storage)     │
│    inferenceWorker.ts (Web Worker — runs the model off the     │
│                         main thread)                           │
│    llmFallback.ts     (builds the prompt, calls the worker,    │
│                         parses the structured response)        │
│         │                                                      │
│         ▼                                                      │
│  commandHandler.ts (existing — sendCommand)                    │
└───────────────────────────────────────────────────────────┘
```

No new package, no proxy, no `ANTHROPIC_API_KEY` anywhere — the entire pipeline runs client-side. The tradeoff for removing the server is that the *model itself* becomes an asset the client has to load, cache, and run, which is a materially different kind of cost than a network call (see §7).

---

## 2. Library choice: WebLLM vs. transformers.js

| | WebLLM (`@mlc-ai/web-llm`) | transformers.js (`@huggingface/transformers`) |
|---|---|---|
| What it runs | Quantized chat/instruct LLMs (Llama, Phi, Gemma, Qwen family, 1B–8B params) | ONNX models — historically task-specific (classification, embeddings), now also some small instruct models |
| Backend | WebGPU only | WASM (universal) or WebGPU |
| Fit for "judge typo + phrase a sentence" | Good — this is exactly the generative, judgment-plus-phrasing task chat models are for | Workable with a small instruct model, but the library's sweet spot is narrower tasks; phrasing quality on a small ONNX instruct model is inconsistent |
| Browser support | Requires WebGPU — solid on desktop Chrome/Edge, partial on Firefox, inconsistent on Safari and much of mobile | WASM path works everywhere (slower); WebGPU path has the same gaps as WebLLM |

**Recommendation if pursuing this option at all: WebLLM**, because the feature as specified needs both a judgment call ("is this a typo/synonym?") and natural phrasing of a player-facing sentence — the task transformers.js is weakest at with small models. The rest of this doc assumes WebLLM; a transformers.js build-out would follow the same shape (worker isolation, feature detection, fallback) with a different loader/runtime API.

### Model selection

A small instruct model, quantized to 4-bit, e.g. `Llama-3.2-1B-Instruct-q4f16_1-MLC` or `Phi-3.5-mini-instruct-q4f16_1-MLC` (MLC's prebuilt model list — check `@mlc-ai/web-llm`'s `prebuiltAppConfig` for the current catalog of ready-to-serve model IDs). Smaller (1B) trades phrasing/judgment quality for a smaller download and faster inference; larger (3.5B–8B) is closer to the LLM-proxy plan's quality but pushes the download well past 2GB and inference latency up significantly on mid-range hardware.

---

## 3. Feature detection and graceful fallback

Not every browser/device can run this. `modelLoader.ts` must check for WebGPU support before attempting to load anything, and the feature must degrade to something reasonable when it isn't available — either the static templates from the no-AI plan, or simply skipping the fuzzy-fallback step and only using exact match.

```ts
// packages/client/src/lib/commandValidation/localModel/modelLoader.ts
export async function isLocalModelSupported(): Promise<boolean> {
  if (!("gpu" in navigator)) return false;
  try {
    const adapter = await (navigator as any).gpu.requestAdapter();
    return adapter !== null;
  } catch {
    return false;
  }
}
```

```ts
// packages/client/src/lib/commandValidation/localModel/modelLoader.ts (continued)
import { CreateMLCEngine, type MLCEngine } from "@mlc-ai/web-llm";

const MODEL_ID = "Llama-3.2-1B-Instruct-q4f16_1-MLC";
let enginePromise: Promise<MLCEngine> | null = null;

/** Lazily loads and caches the engine — first call triggers the (large) download. */
export function getEngine(onProgress?: (pct: number, text: string) => void): Promise<MLCEngine> {
  if (!enginePromise) {
    enginePromise = CreateMLCEngine(MODEL_ID, {
      initProgressCallback: (report) => onProgress?.(report.progress, report.text),
    });
  }
  return enginePromise;
}
```

WebLLM's engine already runs model execution in a worker internally when configured with `CreateWebWorkerMLCEngine` — using that variant (rather than the plain `CreateMLCEngine`, which runs on the main thread) is strongly recommended so a slow inference pass doesn't freeze the terminal UI. See the WebLLM docs for the worker-engine setup; the shape above is illustrative of the loading/caching pattern, not the final worker wiring.

---

## 4. When to trigger the download

This is a UX decision, not just a technical one — a multi-hundred-MB-to-multi-GB download cannot happen silently on first keystroke. Options, roughly in order of intrusiveness:

1. **Lazy, on first fallback need**: only start downloading the model the first time a command fails exact match. Show a loading indicator in the terminal ("thinking about that command...") while it loads, and fall back to a static message if the player doesn't want to wait or the load fails. Avoids the cost entirely for players who never mistype.
2. **Eager, on app load, backgrounded**: start the download as soon as the client boots, low-priority, so it's likely ready by the time it's needed. Costs bandwidth for every player regardless of whether they ever need the fallback.
3. **Opt-in setting**: a toggle ("enable smart typo suggestions") that's off by default, so the cost is only paid by players who explicitly want it.

Given the cost profile (§7), **(1) or (3)** are the only defensible choices — (2) means every player pays a multi-hundred-MB download for a feature most will never trigger.

---

## 5. Local inference call

Structurally the same prompt shape as the proxy-based plan's fallback call ([command-validation-implementation.md §2.2](command-validation-implementation.md)), but invoked against the local engine instead of a remote API, and without a JSON-schema-constrained response (WebLLM/local runtimes have much weaker structured-output guarantees than the Claude API's `output_config.format` — expect to parse a best-effort JSON blob defensively, or fall back to plain text and a simpler heuristic).

```ts
// packages/client/src/lib/commandValidation/localModel/llmFallback.ts
import { getEngine } from "./modelLoader";
import { wordsOfType } from "../dictionaryCache";
import type { ValidationResult } from "../commandValidator";

export async function askLocalModel(failure: Extract<ValidationResult, { ok: false }>) {
  const engine = await getEngine();
  const candidates = wordsOfType(failure.expectedType);

  const completion = await engine.chat.completions.create({
    messages: [{
      role: "user",
      content:
        `The player typed "${failure.word}", expected a ${failure.expectedType}. ` +
        `Known words: ${candidates.join(", ")}. Respond with ONLY a JSON object: ` +
        `{"matchedWord": string|null, "confidence": "high"|"low"|"none", "message": string}.`,
    }],
    temperature: 0, // most local runtimes still expose temperature; keep it near-deterministic
  });

  try {
    return JSON.parse(completion.choices[0].message.content ?? "{}");
  } catch {
    return null; // malformed output — fall back to the static template, same as the proxy plan's fail-open behavior
  }
}
```

**Defensive parsing is not optional here.** Small local models are far more prone to breaking format instructions than the hosted Claude API's schema-constrained output — always have a static-message fallback ready for parse failures, same as the proxy plan's network-failure fallback.

---

## 6. Wiring into the existing terminal flow

Same integration point as the other two plans — [commandHandler.ts:63](../../packages/client/src/lib/terminalCommands/commandHandler.ts#L63) — but gated by feature support and with a loading state:

```ts
if (!bypassSystem && !context.cmd.startsWith("_")) {
  const validation = validateLocally(command);
  if (!validation.ok) {
    let message = staticMessageFor(validation); // always have this ready first
    if (await isLocalModelSupported()) {
      addTerminalContent({ text: "...", format: "info", useTypewriter: false }); // loading indicator
      const result = await askLocalModel(validation).catch(() => null);
      if (result?.message) message = result.message;
    }
    addTerminalContent({ text: message, format: "error", useTypewriter: true });
    return;
  }
}
```

---

## 7. Pros and cons — in depth

### Pros

- **No server, no API key, no hosting decision.** Removes the entire proxy/deployment concern from the LLM-proxy plan — there's nothing to deploy, monitor, rate-limit, or pay a per-request bill for.
- **Works offline once cached.** After the first successful load, the model runs with no network dependency at all — consistent with a game that otherwise talks to Torii/Starknet, where "offline" isn't really achievable anyway, but the *validation feature specifically* would keep working through a network blip.
- **No data leaves the device.** Whatever the player types for validation purposes never crosses the network — a genuine privacy property the proxy plan doesn't have (though the proxy plan's exposure here is minimal already, since it only ever sends single ambiguous words, not full player state).
- **No per-request marginal cost.** Once the model is downloaded, running it costs the player's own compute — no ongoing Anthropic/API bill that scales with usage, unlike Option A/D.

### Cons

- **Large one-time download per player**, not per deploy — every player who triggers (or eagerly pre-loads) the fallback pays a 500MB–2GB+ download, on a project that is otherwise a lightweight browser game. This is the single biggest cost of this option and it's paid in the player's bandwidth and time, not the project's budget — arguably a worse trade for a casual/quick-to-load game than a small server bill would be.
- **Inconsistent browser/device support.** WebGPU is not universal — meaningfully weaker on mobile browsers and Safari — so this option needs a real fallback path (§3) for a non-trivial fraction of players, which means building and maintaining *two* validation experiences (model-backed and static) rather than one.
- **Weaker output quality than a hosted model, for both halves of the task.** The models small enough to be practical in-browser (1B–3B params, heavily quantized) make noticeably worse typo/synonym judgment calls and produce blander, more repetitive phrasing than Claude Haiku/Sonnet — the exact two things this feature exists to get right. This is a genuine quality regression versus Option A/D, not just an infrastructure tradeoff.
- **Weaker structured-output guarantees.** Unlike the Claude API's `output_config.format` (schema-validated JSON), local runtimes typically only support prompting the model to emit JSON — no schema enforcement — so response parsing has to be defensive (§5), and malformed/unparseable output will happen more often than with a hosted model.
- **New engineering surface with no equivalent in the other two plans**: a model loader with progress UI, a Web Worker to keep inference off the main thread, feature detection, and a fallback UX for unsupported browsers/devices. None of this exists in the no-AI plan (Option E) at all, and the proxy plan (Option A/D) trades it for a much smaller "deploy and secure one HTTP endpoint" surface.
- **Device resource cost paid by every engaged player**: memory for the loaded model, GPU/CPU time per inference, and battery drain on mobile — ongoing costs that don't show up on a bill but are real costs imposed on players, for a feature that's a fallback path most commands never hit.
- **Slower in practice than it sounds.** Inference on a 1–3B model via WebGPU on a mid-range laptop or phone can take longer than round-tripping to a hosted Haiku call over the network, especially before the model is warmed up — "no network call" doesn't reliably mean "faster."

### Net assessment

Every cost listed above exists to solve a problem — "is this word close to a known word, and how should the message read" — that a 20-line edit-distance function already solves for free, instantly, with no browser-compatibility surface at all (Option E). Option C would only become the right call if the project independently needed local/offline LLM inference for some *other* reason and this feature could ride along on that investment; as a standalone justification for shipping an in-browser model, it doesn't hold up against either alternative.

---

## 8. Testing plan

1. **Feature detection**: unit test `isLocalModelSupported()` against mocked `navigator.gpu` present/absent/adapter-null cases.
2. **Fallback path**: verify that when `isLocalModelSupported()` is false, or `askLocalModel()` throws/returns unparseable output, the static message from `staticMessageFor()` is shown — this is the path most players and CI will actually exercise, since CI runners typically have no WebGPU.
3. **Manual verification only, on real hardware**: model quality, load time, and inference latency cannot be meaningfully asserted in an automated test — this needs hands-on checking on at least one desktop (WebGPU-supported) and one mobile (likely unsupported, confirming graceful fallback) browser before shipping.
4. **Do not gate CI on model-backed behavior** — treat everything past feature detection as manually verified, same spirit as the `/verify` skill's guidance to check real behavior by hand when automated coverage can't reach it.

---

## 9. File checklist

New:
- `packages/client/src/lib/commandValidation/dictionaryCache.ts` (unchanged, shared with the other plans)
- `packages/client/src/lib/commandValidation/commandValidator.ts` (unchanged, shared with the other plans)
- `packages/client/src/lib/commandValidation/localModel/modelLoader.ts`
- `packages/client/src/lib/commandValidation/localModel/inferenceWorker.ts`
- `packages/client/src/lib/commandValidation/localModel/llmFallback.ts`
- `packages/client/src/lib/commandValidation/messages.ts` (static fallback templates, reused from the no-AI plan)

Edited:
- `packages/client/src/lib/terminalCommands/commandHandler.ts` — validation call with loading state + fallback gating
- `packages/client/package.json` — add `@mlc-ai/web-llm` dependency

Not needed (unlike the LLM-proxy plan): no new package, no `ANTHROPIC_API_KEY`, no `VITE_COMMAND_PROXY_URL`, no proxy deployment.
