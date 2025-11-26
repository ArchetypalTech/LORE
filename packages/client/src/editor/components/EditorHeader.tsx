import { useMemo, useRef } from "react";
import { APP_EDITOR_DATA } from "@/data/app.data";
import { LORE_CONFIG } from "@/lib/config";
import WalletStore, { useWalletStore } from "@/lib/stores/wallet.store";
import { Config } from "../lib/config";
import { publishConfigToContract } from "../publisher";
import { Button } from "./ui/Button";
import { propertiesRegistered } from "../data/editor.data";
import { useEditorPermissions } from "@/lib/stores/editor.store";
import { useLocation } from "wouter";


export const EditorHeader = () => {
	const fileInputRef = useRef<HTMLInputElement>(null);
	const { isConnected } = useWalletStore();
	const { isAdmin, isEditor } = useEditorPermissions();
	const [_location, navigate] = useLocation();

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
		await publishConfigToContract();
	};

	const requireConnect = useMemo(() => {
		const useController = LORE_CONFIG.useController;
		return !isConnected && useController;
	}, [isConnected]);

	return (
  <div className="use-editor-styles relative pt-5 pb-2">
    <header className="mx-auto flex w-full flex-row items-center justify-between gap-2 pb-2 lg:container">
      
      {/* Left Section (Title + Mode) */}
      <div className="flex flex-row font-berkeley">
        <h1 className="rotate-[-1.65deg] font-berkeley font-bold text-xl">
          {APP_EDITOR_DATA.title}
        </h1>
        <div className="mx-1 text-[7pt]">
          (
            {import.meta.env.MODE ? import.meta.env.MODE.toUpperCase() : "DEV"}
            {isAdmin ? "/ADMIN" : isEditor ? "/EDITOR" : ""}
          )
        </div>
      </div>

      {/* Center Section (QR Code) */}
      <div className="flex grow items-center justify-center">
				<div className="flex flex-col items-center">
					<span className="text-sm font-semibold">Play game here:</span>
					<img
						src="/images/ORugQRcode.png"
						alt="QR Code"
						className="h-32 w-32 object-contain mt-1"
					/>
				</div>
			</div>

      {/* Right Section (Buttons) */}
      <div className="flex gap-2">
        {requireConnect ? (
          <Button
            className="btn btn-sm btn-warning"
            onClick={async () => {
              await WalletStore().connectController();
              let propertyRegistryFound = await propertiesRegistered();
              if (!propertyRegistryFound) {
                console.log("PropertyRegistry not found");
              } else {
                console.log("PropertyRegistry found");
              }
            }}
          >
            Connect Controller
          </Button>
        ) : !isEditor ? (
          <Button onClick={() => navigate("/")}>Go finish the game first</Button>
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
      </div>
			</header>
		</div>
	);
};
