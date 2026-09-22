# client-sn — Coding Standards

Standards for `packages/client-sn` — the React 19 + Vite frontend for the **L2 Starknet world** (`lore_sn`). This is a separate, independent client from `packages/client`; do **not** copy code from `packages/client`, and do **not** target the L3 `packages/contracts` (`lore`) world. client-sn always talks to `packages/starknet` via its `manifest_sepolia.json`.

## Core principle: pages stay thin, components do the work

Pages/screens should read like a table of contents — layout plus a handful of components. **Push all logic, hooks, and state into components.** If a page file contains hooks (`useState`, `useEffect`, `useAccount`, …) or inline event handlers beyond trivial layout, that logic belongs in a component.

The canonical example is `pages/store.tsx`: it owns only the page layout and delegates all connection logic to `<ConnectButton />`. Follow that pattern everywhere.

```tsx
// ✅ Good — page is just composition
export default function App() {
	return (
		<main className="page">
			<h1 className="page-title">&gt;LORE</h1>
			<ConnectButton />
		</main>
	);
}

// ❌ Bad — hooks + handlers + connection logic living in the page
export default function App() {
	const { connect } = useConnect();
	const { address } = useAccount();
	const [username, setUsername] = useState<string>();
	useEffect(() => { /* ... */ }, []);
	return <main>{/* inline buttons + handlers */}</main>;
}
```

Rules of thumb:
- A component owns one concern. If it grows two unrelated responsibilities, split it.
- A piece of UI used (or likely to be used) in more than one place is a component, not inline JSX.
- Stateful UI (anything with hooks) is almost always a component, not page-level code.
- Prefer composing small components over passing many props / deep conditionals.

## src structure

```
packages/client-sn/src/
├── App.tsx          # Route table (react-router) — routes only
├── main.tsx         # Entry point: createRoot → <BrowserRouter> → <App />
├── pages/           # One file per route (default export) — composition only
├── assets/          # Images imported from code (Vite-hashed)
├── components/      # All reusable UI + stateful widgets
├── context/         # React providers (Starknet/Torii) — wrapped around /store only
├── hooks/           # Reusable React hooks
├── lib/             # Framework-agnostic helpers / pure utilities
├── styles/          # index.css — Tailwind import + all shared CSS classes
└── dojo/            # Dojo / Starknet wiring — no React
```

Where things go:
- **`pages/`** — route entry points: `home` (`/`), `editor` (`/editor`), `walkthrough` (`/walkthrough`), `store` (`/store`). Website pages (`/`, `/editor`) render inside `<SiteLayout />` (nav, parallax background, footer).
- **`components/`** — every component, presentational or stateful. This is where most code lives.
- **`context/`** — React context providers. The Starknet/Torii stack (`<Providers>`) is mounted by `pages/store.tsx`, which is lazy-loaded so the website pages don't pull in the wasm/Starknet bundle.
- **`public/`** — static files served as-is (fonts, favicon, social preview images).
- **`hooks/`** — reusable React hooks shared across components. A hook used by a single component can stay in that component's file.
- **`lib/`** — pure, framework-agnostic helpers and utilities (no JSX, no React).
- **`styles/`** — `index.css` holds the Tailwind import and every shared CSS class. All styles live here; it's imported once in `main.tsx`.
- **`dojo/`** — framework-agnostic Starknet/Dojo config and connector setup. No JSX, no React hooks here. Constants like `NAMESPACE`, `RPC_URL`, `TORII_URL`, `WORLD_ADDRESS`, and the shared `controllerConnector` are sourced from here.

## Conventions

- **File naming**: component/provider files are `kebab-case.tsx` (`connect-button.tsx`, `starknet-provider.tsx`). Config/util files are `kebab-case.ts` or the established name (`dojoConfig.ts`).
- **Component naming**: named exports in `PascalCase` (`export function ConnectButton()`). The only `export default`s are `App` and the files in `pages/`.
- **Routing**: `react-router` v7 (declarative `<Routes>` in `App.tsx`). Internal links use `<Link to>`; external links stay plain `<a href>`.
- **Imports**: use the `@/` alias for everything under `src` (`@/components/connect-button`, `@/dojo/connector`). It maps to `src/` via `tsconfig.json` + `vite.config.ts`. Don't use long relative paths (`../../`).
- **Types**: `import type { … }` for type-only imports (matches the repo's Biome `useImportType` rule). TS is `strict` with `noUnusedLocals`/`noUnusedParameters` on — keep imports and params clean.
- **Styling**: **never use inline `style={{…}}` objects.** Style with Tailwind utilities written directly in `className`:
  - **Layout and one-off styling go in `className`**, as Tailwind utilities, on the element itself (`<div className="flex flex-1 flex-col items-end justify-center gap-3">`). Do **not** invent custom CSS classes (`.page`, `.page-col`, `.connect`, …) and `@apply` utilities into them — put the utilities on the element.
  - **`index.css` holds only the Tailwind import and element-level base defaults** (in `@layer base`): `body`, `button`, etc. styled by element selector so a plain element looks right with no `className`. A bare `<button>` is the canonical button. Keep this layer minimal — it's for global defaults, not layout.
  - **Don't author custom CSS classes at all unless explicitly requested.** If a variant is needed, prefer composing utilities in `className` (e.g. a text-link button is `className="bg-transparent px-2 py-1 text-sm underline …"`, not a `.btn-link` class). Only add a named class to `index.css` when the user asks for one.
  - **Approved exceptions (ported from the www-orug website):** the named classes `.link`, `.hl`, `.crt-text`, `.fade-in-out` in `index.css`, and the scroll-driven inline `style` in `components/background.tsx` (parallax positions). Don't add more without asking.
  - **Theme tokens** (in `@theme`): `primary` `#00bc7d`, `secondary` `#5ee9b5`, `black` `#1c1b22` (so `bg-black`/`text-black` are the site's dark tone), `accent` amber-200; fonts `font-primary` (Roboto Mono), `font-secondary` (Kode Mono).
- **Single source for connection**: there is one `controllerConnector` instance (`dojo/connector.ts`) used by both the provider and connect UI. Don't construct new connectors ad hoc.
- **Lint/format**: repo-wide Biome (tab indent, `indentWidth: 1`) + oxlint. Tabs, not spaces. Keep cognitive complexity low (Biome caps it) — extracting components is the primary way to stay under the cap.

## Adding a feature — checklist

1. Build it as a component in `components/` (named PascalCase export, kebab-case file).
2. Put any hooks/state/handlers in that component, not in the page.
3. Source Starknet/Dojo constants and the connector from `dojo/`; don't hardcode RPC/namespace/addresses in components.
4. Compose the component into the relevant page in `pages/` (new routes are added in `App.tsx`).
5. If it's a provider, add it to `context/` and mount it where it's needed (Starknet/Torii ones go in `<Providers>`, used by `/store`).
6. Use `@/` imports; run `bun run build` (tsc + vite) from `packages/client-sn` to typecheck.

## Environment

- `VITE_PROFILE` — Starknet profile (`dev` | `sepolia` | `mainnet`).
- `VITE_WALKTHROUGH_PIN_HASH` — SHA-256 hex of the `/walkthrough` PIN (`printf <pin> | shasum -a 256`). The check is client-side only (casual gate, not security). If unset, the walkthrough can't be unlocked.
- `VITE_WALKTHROUGH_EMBED` — URL of the video embedded on `/walkthrough` once unlocked. Kept out of the repo, but still inlined into the built JS.

All variables are documented in `.env.example`. Never commit real values — `.env` is gitignored.
