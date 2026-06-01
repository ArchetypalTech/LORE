import { resolve } from "node:path";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import mkcert from "vite-plugin-mkcert";
import topLevelAwait from "vite-plugin-top-level-await";
import wasm from "vite-plugin-wasm";

export default defineConfig({
	plugins: [
		react(),
		tailwindcss(),
		wasm(),
		topLevelAwait(),
		mkcert({
			hosts: ["localhost", "127.0.0.1"],
			autoUpgrade: true,
			savePath: resolve(__dirname, "ssl"),
		}),
	],
	resolve: {
		alias: {
			"@": resolve(__dirname, "./src"),
		},
	},
	server: {
		// mkcert plugin populates cert/key; an empty object enables HTTPS.
		https: {},
		port: 5175,
		// Allow importing manifests/bindings from the @lore/starknet workspace package.
		fs: { allow: [resolve(__dirname, "..", "..")] },
	},
	build: {
		target: "esnext",
	},
});
