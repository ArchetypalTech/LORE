import "@styles/editor.css";
import { useEffect, useMemo, useState } from "react";
import { EditorHeader } from "./components/EditorHeader";
import { useHead } from "@unhead/react";
import { APP_EDITOR_SEO } from "@/data/app.data";
import EditorData, { useEditorData } from "./data/editor.data";
import { cn } from "@/lib/utils/utils";
import { EditorFooter } from "./components/EditorFooter";
import { useDojoStore } from "@/lib/stores/dojo.store";
import { HierarchyTree } from "./components/HierarchyTree";
import { EntityEditor } from "./components/EntityEditor";
import Terminal from "@/client/terminal/Terminal";
import { useUserStore } from "@/lib/stores/user.store";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { toast, Toaster } from "sonner";
import { Button } from "./components/ui/Button";
import { NoEntity } from "./components/ui/NoEntity";
import { HousePlus } from "lucide-react";

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
		console.log(hasObjects, EditorData().getEntities());
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
					<div className="use-editor-styles relative w-full h-full flex items-center justify-center">
						<div className="animate-spin mr-3">🥾</div>
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
								<div className="flex flex-col grow">
									<NoEntity />
									<Button
										className="max-w-30 mx-auto"
										onClick={() => EditorData().newEntity({} as Entity)}
									>
										<HousePlus /> New Entity
									</Button>
								</div>
							)}
						</div>
						<div
							className={cn(
								!dark_mode && "invert grayscale-100 contrast-120",
								"relative col-span-2 h-[700px] hover:opacity-100 opacity-50",
							)}
						>
							<Terminal />
						</div>
					</div>
				);
			case "error":
				return (
					<div className="w-full h-full flex place-items-center place-content-center grow">
						<div className="flex w-30 ">
							<div className="flex flex-col grow text-center">
								<h2 className="text-center mb-10 text-2xl">Error</h2>
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
				className="fixed max-h-screen h-screen w-full font-atkinson overflow-scroll px-4"
			>
				<div className="relative h-full max-w-[1200px] mx-auto">
					<EditorHeader />
					<div className="relative lg:container mx-auto p-0 m-0">
						{editorContents}
					</div>
				</div>
			</div>
			<EditorFooter />
		</>
	);
};
