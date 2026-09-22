import { Link } from "react-router";
import { Logo } from "@/components/logo";

const PLAY_HTTPS = "https://archetypaltech.itch.io/oruggin-trail";
const PRESS_HTTPS = "https://press.oruggintrail.com";
const WIKI_HTTPS = "https://wiki-host-lore.fly.dev/";

export function Nav() {
	return (
		<nav className="fixed top-0 z-1 flex w-screen bg-black p-4 text-primary">
			<div className="flex grow items-center justify-between md:grid md:grid-cols-[1fr_auto_1fr]">
				<div className="ml-4 flex items-center gap-24 md:place-content-start">
					<a className="link" aria-label="presskit for the game" href={PRESS_HTTPS}>
						PressKit
					</a>
					<a className="link" aria-label="play the game" href={PLAY_HTTPS}>
						Play
					</a>
					<Link className="link" aria-label="edit the game" to="/editor">
						Editor
					</Link>
					<Link className="link" aria-label="store" to="/store">
						Store
					</Link>
				</div>
				<div className="hidden md:flex md:items-end md:justify-center">
					<Link to="/" aria-label="home">
						<Logo className="size-[2.5em]" />
					</Link>
				</div>
				<div className="mr-4 place-content-end gap-24 md:flex">
					<a className="link" aria-label="wiki" href={WIKI_HTTPS}>
						Wiki
					</a>{" "}
					<Link className="link" aria-label="walkthrough" to="/walkthrough">
						Walkthrough
					</Link>{" "}
					<a
						href="#"
						target="_blank"
						aria-label="wallet connect"
						className="link disabled hidden md:block"
					>
						Connect Wallet
					</a>
				</div>
			</div>
		</nav>
	);
}
