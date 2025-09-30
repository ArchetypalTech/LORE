import { useHead } from "@unhead/react";
import { APP_SEO } from "@/data/app.data";
import Terminal from "./terminal/Terminal";
import bg from "../assets/782.webp";

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

	return (
		<div
			id="client-root"
			className="relative flex h-screen w-screen max-h-[100dvh] items-center justify-center "
		>
			<div className="fixed z-[0] opacity-40 w-screen h-screen max-h-[100dvh] artwork-background">
				<img src={bg} alt="oruggin-background" />
			</div>
			<div className="crt buzzing flex h-full max-h-[100dvh] md:max-h-[70%] w-full items-center justify-center">
				<Terminal />
			</div>
			<div className="fixed bottom-4 hidden md:block">
					<p className="text-center text-xs text-amber-300">Liked the game? Leave a comment on our <a aria-label="leave a comment" className="comments underline" href="https://archetypaltech.itch.io/oruggin-trail">Itch.io</a> page!</p>
			</div>
		</div>
	);
};
