# client-sn — Coding Standards

Standards for `packages/client-sn` — the React 19 + Vite frontend for the **L2 Starknet world** (`lore_sn`). This is a separate, independent client from `packages/client`; do **not** copy code from `packages/client`, and do **not** target the L3 `packages/contracts` (`lore`) world. client-sn always talks to `packages/starknet` via its `manifest_sepolia.json`.

## Core principle: pages stay thin, components do the work

Pages/screens should read like a table of contents — layout plus a handful of components. **Push all logic, hooks, and state into components.** If a page file contains hooks (`useState`, `useEffect`, `useAccount`, …) or inline event handlers beyond trivial layout, that logic belongs in a component.

The canonical example is `App.tsx`: it owns only the page layout and delegates all connection logic to `<ConnectButton />`. Follow that pattern everywhere.

```tsx
// ✅ Good — page is just composition
export default function App() {
	return (
		<main style={styles.main}>
			<h1 style={styles.title}>&gt;LORE</h1>
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
├── App.tsx          # Root page — layout + component composition only
├── main.tsx         # Entry point: createRoot → providers → <App />
├── components/      # All reusable UI + stateful widgets
├── context/         # React providers that wrap the app tree
├── hooks/           # Reusable React hooks
├── lib/             # Framework-agnostic helpers / pure utilities
└── dojo/            # Dojo / Starknet wiring — no React
```

Where things go:
- **`components/`** — every component, presentational or stateful. This is where most code lives.
- **`context/`** — only React context providers that wrap the tree in `main.tsx`.
- **`hooks/`** — reusable React hooks shared across components. A hook used by a single component can stay in that component's file.
- **`lib/`** — pure, framework-agnostic helpers and utilities (no JSX, no React).
- **`dojo/`** — framework-agnostic Starknet/Dojo config and connector setup. No JSX, no React hooks here. Constants like `NAMESPACE`, `RPC_URL`, `TORII_URL`, `WORLD_ADDRESS`, and the shared `controllerConnector` are sourced from here.

## Conventions

- **File naming**: component/provider files are `kebab-case.tsx` (`connect-button.tsx`, `starknet-provider.tsx`). Config/util files are `kebab-case.ts` or the established name (`dojoConfig.ts`).
- **Component naming**: named exports in `PascalCase` (`export function ConnectButton()`). The only `export default` is the page `App` (and any future page entry points).
- **Imports**: use the `@/` alias for everything under `src` (`@/components/connect-button`, `@/dojo/connector`). It maps to `src/` via `tsconfig.json` + `vite.config.ts`. Don't use long relative paths (`../../`).
- **Types**: `import type { … }` for type-only imports (matches the repo's Biome `useImportType` rule). TS is `strict` with `noUnusedLocals`/`noUnusedParameters` on — keep imports and params clean.
- **Styling**: current components use inline `Record<string, React.CSSProperties>` `styles` objects co-located at the bottom of the file. Keep a component's styles with the component (move them along when you extract a component). Match the existing approach unless a styling system is introduced project-wide.
- **Single source for connection**: there is one `controllerConnector` instance (`dojo/connector.ts`) used by both the provider and connect UI. Don't construct new connectors ad hoc.
- **Lint/format**: repo-wide Biome (tab indent, `indentWidth: 1`) + oxlint. Tabs, not spaces. Keep cognitive complexity low (Biome caps it) — extracting components is the primary way to stay under the cap.

## Adding a feature — checklist

1. Build it as a component in `components/` (named PascalCase export, kebab-case file).
2. Put any hooks/state/handlers in that component, not in the page.
3. Source Starknet/Dojo constants and the connector from `dojo/`; don't hardcode RPC/namespace/addresses in components.
4. Compose the component into the relevant page (`App.tsx` or a future page).
5. If it needs to wrap the whole tree (a provider), add it to `context/` and wire it in `main.tsx`.
6. Use `@/` imports; run `bun run build` (tsc + vite) from `packages/client-sn` to typecheck.
