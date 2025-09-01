import fs from "node:fs";
import { resolve } from "node:path";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { bgGreen, black } from "ansicolor";
import { defineConfig, loadEnv } from "vite";
import mkcert from "vite-plugin-mkcert";
import oxlintPlugin from "vite-plugin-oxlint";
import wasm from "vite-plugin-wasm";
import { patchBindings } from "./scripts/vite-fix-bindings";

//TODO: https://github.com/nksaraf/vinxi
// https://www.npmjs.com/package/wouter

export default defineConfig(async ({ mode }) => {
	process.env = { ...process.env, ...loadEnv(mode, process.cwd()) };
	console.log(`\n🧾 LORE IN (${mode}) MODE`);
	const isSlot = mode === "slot";
	// if (isSlot) {
	// 	console.info(
	// 		black(
	// 			bgGreen(
	// 				" Mkcert may prompt for sudo password to generate SSL certificates. ",
	// 			),
	// 		),
	// 	);
	// }
	return {
		plugins: [
			oxlintPlugin(),
			mkcert({
				hosts: ["localhost", "127.0.0.1"],
				autoUpgrade: true,
				savePath: resolve(__dirname, "ssl"),
			}),
			wasm(),
			tailwindcss(),
			react(),
			patchBindings(),
		],
		build: {
			target: "esnext",
			sourcemap: true,
		},
		server: {
			https: true,
			proxy: {
				"/katana": {
					target: process.env.VITE_KATANA_HTTP_RPC,
					changeOrigin: true,
					rewrite: (path: string) => path.replace(/^\/katana/, ""),
				},
			},
			cors: false,
		},
		resolve: {
			alias: {
				"@": resolve(__dirname, "./src"),
				"@components": resolve(__dirname, "./src/components"),
				"@lib": resolve(__dirname, "./src/lib"),
				"@styles": resolve(__dirname, "./src/styles"),
				"@editor": resolve(__dirname, "./src/editor"),
				"@lore/contracts/manifest": isSlot
					? "@lore/contracts/manifest_slot.json"
					: "@lore/contracts/manifest_dev.json",
			},
		},
	};
});
