import path from "node:path";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { bgGreen, black } from "ansicolor";
import { defineConfig, loadEnv } from "vite";
import mkcert from "vite-plugin-mkcert";
import oxlintPlugin from "vite-plugin-oxlint";
import topLevelAwait from "vite-plugin-top-level-await";
import wasm from "vite-plugin-wasm";
import { patchBindings } from "./scripts/vite-fix-bindings";

//TODO: https://github.com/nksaraf/vinxi
// https://www.npmjs.com/package/wouter

export default defineConfig(async ({ mode }) => {
	process.env = { ...process.env, ...loadEnv(mode, process.cwd()) };
	console.log(`\n🧾 LORE IN (${mode}) MODE`);
	const isSlot = mode === "slot";
	if (isSlot)
		console.info(
			black(
				bgGreen(
					" Mkcert may prompt for sudo password to generate SSL certificates. ",
				),
			),
		);

	return {
		plugins: [
			oxlintPlugin(),
			isSlot &&
				mkcert({
					hosts: ["localhost"],
					autoUpgrade: true,
					savePath: path.resolve(__dirname, "ssl"),
				}),
			wasm(),
			topLevelAwait(),
			tailwindcss(),
			react(),
			patchBindings(),
		],
		build: {
			target: "esnext",
			sourcemap: true,
			// minify: false,
			// terserOptions: {
			// compress: false,
			// mangle: false,
			// },
			// rollupOptions: {
			// 	output: {
			// 		manualChunks: {
			// 			"@dojoengine/core": ["@dojoengine/core"],
			// 			"@dojoengine/sdk": ["@dojoengine/sdk"],
			// 			"@cartridge/controller": ["@cartridge/controller"],
			// 			starknet: ["starknet"],
			// 		},
			// 	},
			// },
		},
		server: {
			proxy: {
				"/katana": {
					target: process.env.VITE_KATANA_HTTP_RPC,
					changeOrigin: true,
				},
			},
			cors: false,
		},
		resolve: {
			alias: {
				"@": path.resolve(__dirname, "./src"),
				"@components": path.resolve(__dirname, "./src/components"),
				"@lib": path.resolve(__dirname, "./src/lib"),
				"@styles": path.resolve(__dirname, "./src/styles"),
				"@editor": path.resolve(__dirname, "./src/editor"),
				"@lore/contracts/manifest": isSlot
					? "@lore/contracts/manifest_slot.json"
					: "@lore/contracts/manifest_dev.json",
			},
		},
	};
});
