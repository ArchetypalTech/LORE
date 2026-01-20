import { useHead } from "@unhead/react";
import { APP_SEO } from "@/data/app.data";
import bg from "../assets/782.webp";
import AudioControls from "./terminal/AudioControls";
import AudioPlayer from "./terminal/AudioPlayer";
import Terminal from "./terminal/Terminal";
import { useTerminalStore } from "@lib/stores/terminal.store";
import { useUIPanelStore } from "@lib/stores/terminal.uiPanel.store";
import UIPanel from "./terminal/Terminal.uiPanel";
import "../styles/uiPanel.css";
import { useRightPanelStore } from "@lib/stores/rightPanel.store";
import { RightActionPanel } from "@lib/stores/rigthPanelAction";

export const Client = () => {
	useHead({
		title: APP_SEO.title,
		link: [{ rel: "icon", href: APP_SEO.icon }],
		meta: Object.entries(APP_SEO).map(([key, value]) => {
			if (key.startsWith("og")) {
				return {
					property: `og:${key.replace("og", "")}`,
					content: value,
				};
			}
			return {
				name: key,
				content: value,
			};
		}),
	});

	const { idleVideoPlaying, playTrailer } = useTerminalStore();
	const { visible } = useUIPanelStore();
	const { visible: rightPanelVisible } = useRightPanelStore();

	return (
		<div
			id="client-root"
			className="relative flex h-screen w-screen max-h-[100dvh] items-center justify-center overflow-hidden"
		>

			{/* Idle video */}
			{playTrailer && idleVideoPlaying && (
				<video
					autoPlay
					loop
					playsInline
					src="/video/ORugTrailer_NQ.mp4"
					className="fixed inset-0 w-screen h-screen object-cover z-[50]"
				/>
			)}

			<div
				className={`relative w-full h-full flex flex-col items-center overflow-hidden
					${visible ? "justify-start pb-32" : "justify-center pb-16"}`}
			>

				{visible && (
					<>
						<div className="z-40 w-full max-w-[900px] px-4 pt-4 flex-none max-h-[30vh] overflow-y-auto no-scrollbar">
							<UIPanel/>
						</div>
						<div className="flex-none h-3" />
					</>
				)}

				{/* Artwork background */}
				<div className="fixed z-[0] opacity-40 w-screen h-screen artwork-background">
					<img src={bg} alt="oruggin-background" />
				</div>

				{/* Terminal + Right Panel */}
				<div className="crt buzzing flex h-full md:max-h-[70%] w-full items-center justify-center">
					<div
						className={`flex h-full items-center transition-all duration-300 ease-out
							${rightPanelVisible ? "gap-4" : "gap-0"}`}
					>
						{/* Terminal */}
						<div
							className={`transition-all duration-300 ease-out
								${rightPanelVisible ? "-translate-x-8" : "translate-x-0"}`}
						>
							<Terminal />
						</div>

						{/* Right-side action panel */}
						{rightPanelVisible && (
							<div className="flex-none w-[80px] h-full flex items-center">
								<div className="bg-black/60 border border-amber-500 rounded-md p-2">
									<RightActionPanel />
								</div>
							</div>
						)}
					</div>
				</div>

			</div>

			{/* Audio + Footer */}
			<div className="fixed hidden items-center md:grid grid-cols-3 grid-cols-[.5fr 1fr .5fr] bottom-4 w-full px-4">
				<AudioControls></AudioControls>
				<p className="text-center text-xs text-amber-300">
					Liked the game? Leave a comment on our{" "}
					<a
						aria-label="leave a comment"
						className="comments underline"
						href="https://archetypaltech.itch.io/oruggin-trail"
					>
						Itch.io
					</a>{" "}
					page!
				</p>
				<span className="min-w-3">
					<AudioPlayer></AudioPlayer>
				</span>
			</div>
		</div>
	);
};
