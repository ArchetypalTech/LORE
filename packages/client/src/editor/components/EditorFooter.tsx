import { LORE_CONFIG } from "@lib/config";
import EditorData from "../data/editor.data";
import { Button } from "./ui/Button";

export const EditorFooter = () => {
	return (
		<footer className="fixed bottom-0 gap-2 mt-4 mb-1 flex items-center py-4 not-dark:bg-transparent w-screen justify-center rounded-2xl px-4">
			<div className="relative r-4 flex flex-row justify-between w-full gap-2 items-center max-w-[1200px] ">
				<div className="flex grow" />
				<div className="flex gap-2">
					<a
						href={`${LORE_CONFIG.endpoints.torii.http}/sql`}
						target="_blank"
						rel="noopener noreferrer"
						className="hover:underline text-xs textFreak"
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
