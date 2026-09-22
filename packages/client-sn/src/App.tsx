import { lazy, Suspense } from "react";
import { Navigate, Route, Routes } from "react-router";
import { SiteLayout } from "@/components/site-layout";
import Editor from "@/pages/editor";
import Home from "@/pages/home";
import Walkthrough from "@/pages/walkthrough";

// The store pulls in the Starknet/Torii providers (and their wasm), so it only loads on /store.
const Store = lazy(() => import("@/pages/store"));

export default function App() {
	return (
		<Routes>
			<Route element={<SiteLayout />}>
				<Route index element={<Home />} />
				<Route path="editor" element={<Editor />} />
			</Route>
			<Route path="walkthrough" element={<Walkthrough />} />
			<Route
				path="store"
				element={
					<Suspense fallback={null}>
						<Store />
					</Suspense>
				}
			/>
			<Route path="*" element={<Navigate to="/" replace />} />
		</Routes>
	);
}
