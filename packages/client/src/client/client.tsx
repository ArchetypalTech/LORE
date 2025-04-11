import { useHead } from "@unhead/react";
import { APP_SEO } from "@/data/app.data";
import Terminal from "./terminal/Terminal";

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
			className="relative flex h-screen w-screen items-center justify-center "
		>
			<div className="crt buzzing flex h-full max-h-[70%] w-full items-center justify-center">
				<Terminal />
			</div>
		</div>
	);
};
