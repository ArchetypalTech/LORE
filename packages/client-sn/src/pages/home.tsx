const PLAY_HTTPS = "https://archetypaltech.itch.io/oruggin-trail";
const DISCORD_HTTPS = "https://discord.gg/aEN5qkKaTh";
const MAILING_LIST_HTTPS =
	"https://email-client-2025.fly.dev/register/?campaign=archetypal&colour=white&bg=black";

export default function Home() {
	return (
		<main className="pb-36">
			<section className="grid size-full h-[80vh] place-content-center gap-12 px-4 font-primary text-primary md:px-24">
				<h1 className="text-6xl">The O'Ruggin Trail</h1>
				<div className="flex flex-row justify-between">
					<div className="flex text-8xl">
						<span>&gt;</span>
						<span className="crt-text fade-in-out">&#9608;</span>
					</div>
					<a
						className="w-fit min-w-[200px] self-center rounded-xl bg-primary px-4 py-2 text-center text-black text-xl transition-all duration-400 hover:text-secondary"
						aria-label="play the game"
						href={PLAY_HTTPS}
					>
						Play now! on Itch.io
					</a>
					<span className="w-[100px]" />
				</div>
				<div className="mt-12 flex flex-col gap-2">
					<p>
						<em>
							The world is bleak, society has crumbled, and those that have survived
							are struggling.
						</em>
					</p>
				</div>
				<div className="mb-4 flex flex-col items-center gap-2">
					<h3 className="text-center text-primary text-xl">Join the community</h3>
					<p>Access our Discord server for help and more!</p>
					<a
						className="w-fit min-w-[200px] rounded-xl bg-primary px-4 py-2 text-center text-black transition-all duration-400 hover:text-secondary"
						href={DISCORD_HTTPS}
					>
						Join
					</a>
				</div>
			</section>
			<section>
				<h3 className="mb-8 text-center text-primary text-xl">
					Signup to the mailing list
				</h3>
				<iframe
					title="Mailing list signup"
					scrolling="no"
					src={MAILING_LIST_HTTPS}
					className="mx-auto h-[45dvh] min-h-[30em] w-full min-w-[400px] max-w-[50vw] rounded-[1em] border-[0.125em] border-primary bg-black"
				/>
			</section>
		</main>
	);
}
