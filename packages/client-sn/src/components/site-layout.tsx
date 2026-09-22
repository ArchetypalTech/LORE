import { useEffect } from "react";
import { Outlet, useLocation } from "react-router";
import { Background } from "@/components/background";
import { Footer } from "@/components/footer";
import { Nav } from "@/components/nav";

/** Shared chrome for the website pages: nav, parallax background and footer. */
export function SiteLayout() {
	const { pathname } = useLocation();

	// biome-ignore lint/correctness/useExhaustiveDependencies: scroll to top on every route change
	useEffect(() => {
		window.scrollTo(0, 0);
	}, [pathname]);

	return (
		<>
			<Nav />
			<Background />
			<Outlet />
			<Footer />
		</>
	);
}
