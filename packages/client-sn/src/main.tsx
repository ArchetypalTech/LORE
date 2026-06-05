import "@/styles/index.css";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "@/App";
import { Providers } from "@/context/providers";

createRoot(document.getElementById("root")!).render(
	<StrictMode>
		<Providers>
			<App />
		</Providers>
	</StrictMode>,
);
