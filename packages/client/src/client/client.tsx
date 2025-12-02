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

	const idleVideoPlaying = useTerminalStore((state) => state.idleVideoPlaying);
	const { visible, location, exits, puzzles } = useUIPanelStore();

			return (
		<div
			id="client-root"
			className="relative flex h-screen w-screen max-h-[100dvh] items-center justify-center overflow-hidden"
		>

			{/* Idle video */}
			{idleVideoPlaying && (
				<video
					autoPlay
					loop
					playsInline
					src="/video/ORugTrailer_NQ.mp4"
					className="fixed inset-0 w-screen h-screen object-cover z-[50]"
				/>
			)}

			<div className="relative w-full h-full flex flex-col items-center justify-start overflow-hidden">

				{/* UIPanel (fixed height, scrollable, never overlaps) */}
				{visible && (
					<>
						<div className="z-40 w-full max-w-[900px] px-4 pt-4 flex-none max-h-[30vh] overflow-y-auto no-scrollbar">
							<UIPanel
								location={location}
								exits={exits}
								puzzles={puzzles}
							/>
						</div>

						{/* Permanent gap between panel and terminal */}
						<div className="h-3" />
					</>
				)}

				{/* Artwork background */}
				<div className="fixed z-[0] opacity-40 w-screen h-screen artwork-background">
					<img src={bg} alt="oruggin-background" />
				</div>

				{/* Terminal (fixed original size, never shrinks) */}
				<div className="crt buzzing flex-none w-full md:max-h-[70%] h-full flex items-center justify-center overflow-hidden">
					<Terminal />
				</div>
			</div>

			{/* Audio + Footer */}
			<div className="fixed hidden md:grid grid-cols-3 grid-cols-[.5fr 1fr .5fr] bottom-4 w-full px-4">
				<AudioControls />
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
					<AudioPlayer />
				</span>
			</div>
		</div>
	);
};