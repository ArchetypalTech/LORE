import "@styles/editor.css";
import Terminal from "@/client/terminal/Terminal";
import { APP_EDITOR_SEO } from "@/data/app.data";
import type { Entity } from "@/lib/dojo_bindings/typescript/models.gen";
import { useDojoStore } from "@/lib/stores/dojo.store";
import { useUserStore } from "@/lib/stores/user.store";
import { cn } from "@/lib/utils/utils";
import { useHead } from "@unhead/react";
import { HousePlus } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Toaster, toast } from "sonner";
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
										onClick={() => EditorData().newEntity()}
									>
										<HousePlus /> New Entity
									</Button>
								</div>
							)}
						</div>
						<div
							className={cn(
								!dark_mode && "invert contrast-120",
								"relative col-span-2 h-screen max-h-[calc(100vh-10rem)] hover:opacity-100 opacity-50",
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
