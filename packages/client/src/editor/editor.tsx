import "@styles/editor.css";
import { useHead } from "@unhead/react";
import { HousePlus } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Toaster, toast } from "sonner";
import Terminal from "@/client/terminal/Terminal";
import { APP_EDITOR_SEO } from "@/data/app.data";
import { useDojoStore } from "@/lib/stores/dojo.store";
import { useUserStore } from "@/lib/stores/user.store";
import { cn } from "@/lib/utils/utils";
import { EditorFooter } from "./components/EditorFooter";
import { EditorHeader } from "./components/EditorHeader";
import { EntityEditor } from "./components/EntityEditor";
import { HierarchyTree } from "./components/HierarchyTree";
import { Button } from "./components/ui/Button";
import { NoEntity } from "./components/ui/NoEntity";
import EditorData, { useEditorData } from "./data/editor.data";

type editorState = "not connected" | "loaded" | "empty" | "error";

export const Editor = () => {
	const {
		status: { status },
	} = useDojoStore();
	const { dark_mode } = useUserStore();
	const { dataPool, selectedEntity, isDirty } = useEditorData();
	const [editorState, setEditorState] = useState<editorState>("not connected");

	useHead({
		title: APP_EDITOR_SEO.title,
		link: [{ rel: "icon", href: APP_EDITOR_SEO.icon() }],
		meta: Object.entries(APP_EDITOR_SEO).map(([key, value]) => {
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

	useEffect(() => {
		if (!isDirty) {
			toast.dismiss("editor-dirty");
		}
	}, [isDirty]);

	useEffect(() => {
		dataPool;
		const hasObjects = EditorData().getEntities().length > 0;
		if (status === "loading") {
			setEditorState("not connected");
			return;
		}
		if (hasObjects) {
			if (EditorData().selectedEntity === undefined) {
				EditorData().selectEntity(EditorData().getEntities()[0]?.Entity?.inst);
				setEditorState("loaded");
				return;
			}
			setEditorState("loaded");
			return;
		}
		if (status === "error") {
			setEditorState("error");
			return;
		}
		setEditorState("empty");
	}, [status, dataPool]);

	const editorContents = useMemo(() => {
		switch (editorState) {
			case "not connected":
				return (
					<div className="use-editor-styles relative flex h-full w-full items-center justify-center">
						<div className="mr-3 animate-spin">🥾</div>
						No Dojo connection
					</div>
				);
			case "loaded":
			case "empty":
				return (
					<div className="relative grid grid-cols-5 gap-4">
						<HierarchyTree />
						<div className="use-editor-styles col-span-2">
							{editorState !== "empty" ? (
								<EntityEditor key={selectedEntity} inst={selectedEntity!} />
							) : (
								<div className="flex grow flex-col">
									<NoEntity />
									<Button
										className="mx-auto max-w-30"
										onClick={() => EditorData().newEntity()}
									>
										<HousePlus /> New Entity
									</Button>
								</div>
							)}
						</div>
						<div
							className={cn(
								!dark_mode && "contrast-120 invert",
								"relative col-span-2 h-screen max-h-[calc(100vh-10rem)] opacity-50 hover:opacity-100",
							)}
						>
							<Terminal />
						</div>
					</div>
				);
			case "error":
				return (
					<div className="flex h-full w-full grow place-content-center place-items-center">
						<div className="flex w-30 ">
							<div className="flex grow flex-col text-center">
								<h2 className="mb-10 text-center text-2xl">Error</h2>
								Please check developer console log
							</div>
						</div>
					</div>
				);
		}
	}, [editorState, dark_mode, selectedEntity]);

	return (
		<>
			<Toaster expand visibleToasts={4} position="top-left" />
			<div
				id="editor-root"
				className="fixed h-screen max-h-screen w-full overflow-scroll px-4 font-atkinson"
			>
				<div className="relative mx-auto h-full max-w-[1200px]">
					<EditorHeader />
					<div className="relative m-0 mx-auto p-0 lg:container">
						{editorContents}
					</div>
				</div>
			</div>
			<EditorFooter />
		</>
	);
};
