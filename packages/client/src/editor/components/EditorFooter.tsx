import { LORE_CONFIG } from "@lib/config";
import EditorData from "../data/editor.data";
import { Button } from "./ui/Button";

export const EditorFooter = () => {
	return (
		<footer className="fixed bottom-0 mt-4 mb-1 flex w-screen items-center justify-center gap-2 rounded-2xl not-dark:bg-transparent px-4 py-4">
			<div className="r-4 relative flex w-full max-w-[1200px] flex-row items-center justify-between gap-2 ">
				<div className="flex grow" />
				<div className="flex gap-2">
					<a
						href={`${LORE_CONFIG.endpoints.torii.http}/sql`}
						target="_blank"
						rel="noopener noreferrer"
						className="textFreak text-xs hover:underline"
					>
						<Button variant="secondary">Torii SQL</Button>
					</a>
				</div>
				<div className="flex gap-2">
					<Button
						variant="destructive"
						onClick={() => {
							EditorData().resetChanges();
						}}
					>
						♻️ Sync Editor
					</Button>
					<Button
						variant="secondary"
						onClick={() => {
							EditorData().logPool();
						}}
					>
						Console Log DataPool
					</Button>
				</div>
			</div>
		</footer>
	);
};
