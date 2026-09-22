import { useEffect, useState } from "react";
import backgroundFar from "@/assets/background-far.webp";
import backgroundNear from "@/assets/background-near.webp";

/** Scroll offset that accelerates the further the page is scrolled. */
function useParallaxOffset() {
	const [offset, setOffset] = useState(0);
	useEffect(() => {
		const update = () =>
			setOffset(-(window.scrollY * (window.scrollY / window.innerHeight)));
		update();
		window.addEventListener("scroll", update, { passive: true });
		window.addEventListener("resize", update);
		return () => {
			window.removeEventListener("scroll", update);
			window.removeEventListener("resize", update);
		};
	}, []);
	return offset;
}

/** Two fixed, repeating image layers that scroll at different speeds behind the page. */
export function Background() {
	const offset = useParallaxOffset();
	// Inline styles are the exception here: the positions are driven by scroll.
	return (
		<>
			<div
				className="-z-1 fixed h-screen w-screen bg-repeat-y opacity-15"
				style={{
					backgroundImage: `url(${backgroundFar})`,
					backgroundPosition: `0px ${offset / 1.5}px`,
				}}
			/>
			<div
				className="-z-1 fixed h-screen w-screen bg-repeat-y opacity-55"
				style={{
					backgroundImage: `url(${backgroundNear})`,
					backgroundPosition: `-50% ${offset / 4}px`,
				}}
			/>
		</>
	);
}
