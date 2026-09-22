import { Logo } from "@/components/logo";

export function Footer() {
	return (
		<footer>
			<div className="grid grid-cols-3 p-8 font-secondary text-secondary text-xs">
				<div className="grid grid-cols-2">
					<div className="flex flex-col justify-end gap-1">
						We are all connected by stories
					</div>
					<div className="flex flex-col gap-1" />
				</div>
				<div className="grid place-content-center gap-1">
					<div className="flex flex-col items-center gap-2">
						<a href="https://archetypaltech.com" aria-label="Archetypal home">
							<Logo className="size-[2em]" />
						</a>
						<p>
							&copy; {new Date().getFullYear()} ArchetypalTech. All rights reserved.
						</p>
					</div>
				</div>
				<div className="grid grid-cols-2">
					<div className="flex flex-col items-end gap-1" />
					<div className="flex flex-col items-end justify-end gap-1">
						<a href="https://semaeopus.com/privacy" className="link w-fit">
							Privacy policy
						</a>
						<a href="https://unsubscribe.semaeopus.com" className="link w-fit">
							Unsubscribe
						</a>
					</div>
				</div>
			</div>
		</footer>
	);
}
