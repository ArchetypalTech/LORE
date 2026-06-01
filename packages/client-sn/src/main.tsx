import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { StarknetProvider } from "@/context/starknet-provider";
import App from "@/App";
import "@/styles/index.css";

createRoot(document.getElementById("root")!).render(
	<StrictMode>
		<StarknetProvider>
			<App />
		</StarknetProvider>
	</StrictMode>,
);
