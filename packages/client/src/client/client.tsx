import { useHead } from "@unhead/react";
import { APP_SEO } from "@/data/app.data";
import bg from "../assets/782.webp";
import AudioControls from "./terminal/AudioControls";
import AudioPlayer from "./terminal/AudioPlayer";
import Terminal from "./terminal/Terminal";
import { useTerminalStore } from "@lib/stores/terminal.store";

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

	return (
		<div
			id="client-root"
			className="relative flex h-screen w-screen max-h-[100dvh] items-center justify-center"
		>
				{/* Fullscreen idle video overlay — now in front of terminal */}
				{idleVideoPlaying && (
					<video
						autoPlay
						loop
						playsInline
						src="/video/ORugTrailer_NQ.mp4"
						className="fixed inset-0 w-screen h-screen object-cover z-[50]"
					/>
				)}
			<div className="fixed z-[0] opacity-40 w-screen h-screen artwork-background">
				<img src={bg} alt="oruggin-background" />
			</div>
			<div className="crt buzzing flex h-full md:max-h-[70%] w-full items-center justify-center">
				<Terminal />
			</div>
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
