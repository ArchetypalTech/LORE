import { useMemo, useRef } from "react";
import { APP_EDITOR_DATA } from "@/data/app.data";
import { LORE_CONFIG } from "@/lib/config";
import WalletStore, { useWalletStore } from "@/lib/stores/wallet.store";
import { Config } from "../lib/config";
import { Button } from "./ui/Button";

export const EditorHeader = () => {
	const fileInputRef = useRef<HTMLInputElement>(null);
	const { isConnected } = useWalletStore();

	// Handler for file upload
	const handleImportConfig = () => {
		if (fileInputRef.current) {
			fileInputRef.current.click();
		}
	};

	const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
		if (e.target.files && e.target.files.length > 0) {
			const file = e.target.files[0];
			try {
				await Config().loadConfigFromFile(file);
			} catch (error) {
				console.error("Error loading file:", error);
			}
		}
	};

	// Handler for export config
	const handleExportConfig = async () => {
		await Config().saveConfigToFile();
	};

	// Handler for publish to contract
	const handlePublish = async () => {
		await Config().publishToContract();
	};

	const requireConnect = useMemo(() => {
		const useController = LORE_CONFIG.useController;
		return !isConnected && useController;
	}, [isConnected]);

	return (
		<div className="use-editor-styles relative ">
			<header className="flex flex-row justify-between gap-2 items-center pb-2 w-full lg:container">
				<div className="flex flex-row font-berkeley">
					<h1 className="text-xl font-bold font-berkeley">
						{APP_EDITOR_DATA.title}
					</h1>
					<div className="mx-1 text-[7pt]">
						({import.meta.env.MODE ? import.meta.env.MODE.toUpperCase() : "DEV"})
					</div>
				</div>
				<div className="flex grow" />
				<div className="flex gap-2">
					{requireConnect ? (
						<Button
							className="btn btn-sm btn-warning"
							onClick={async () => {
								await WalletStore().connectController();
							}}
						>
							Connect Controller
						</Button>
					) : (
						<>
							<input
								type="file"
								ref={fileInputRef}
								accept=".json"
								className="hidden"
								onChange={handleFileChange}
							/>
							<Button onClick={handleImportConfig}>Import Config</Button>
							<Button onClick={handleExportConfig}>Export Config</Button>
							<Button
								variant="hero"
								className="hover:textFreak"
								onClick={handlePublish}
							>
								🕊️ Publish
							</Button>
						</>
					)}
					{/* <button className="btn" onClick={() => UserStore().toggleDarkMode()}>
					{dark_mode ? "☀️" : "🌑"}
				</button> */}
				</div>
			</header>
		</div>
	);
};
