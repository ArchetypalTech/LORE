import { LORE_CONFIG } from "@lib/config";
import EditorData from "../data/editor.data";

export const EditorFooter = () => {
	return (
		<footer className="fixed bottom-0 use-editor-styles gap-2 mt-4 mb-1 flex items-center p-4 not-dark:bg-transparent w-full justify-center rounded-2xl">
			<div className="lg:container flex flex-row justify-between w-full gap-2 items-center">
				<div className="flex grow" />
				<div className="flex gap-2">
					<a
						href={`${LORE_CONFIG.endpoints.torii.http}/sql`}
						target="_blank"
						rel="noopener noreferrer"
						className="hover:underline text-xs textFreak"
					>
						<button className="btn btn-sm btn-success">Torii SQL</button>
					</a>
				</div>
				<div className="flex gap-2">
					<button
						className="btn btn-sm btn-success"
						onClick={() => {
							EditorData().logPool();
						}}
					>
						Console Log DataPool
					</button>
				</div>
			</div>
		</footer>
	);
};
