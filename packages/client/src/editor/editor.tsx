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
import { Notifications as NotificationStore } from "./lib/notifications";
import Notifications from "./components/Notifications";

type editorState = "not connected" | "loaded" | "empty" | "error";

export const Editor = () => {
	const {
		status: { status },
	} = useDojoStore();
	const { dark_mode } = useUserStore();
	const { entities, selectedEntity } = useEditorData();
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

	const handleDismissNotification = () => {
		NotificationStore().clear();
	};

	useEffect(() => {
		const hasObjects = EditorData().getEntities().length > 0;
		if (status === "loading") {
			setEditorState("not connected");
			return;
		}
		if (hasObjects) {
			if (EditorData().selectedEntity === undefined) {
				EditorData().selectEntity(entities[0].inst);
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
	}, [status, entities]);

	const editorContents = useMemo(() => {
		switch (editorState) {
			case "not connected":
				return (
					<div className="relative w-full h-full flex items-center justify-center">
						<div className="animate-spin mr-3">🥾</div>
						No Dojo connection
					</div>
				);
			case "loaded":
			case "empty":
				return (
					<div className="relative grid grid-cols-5 gap-4">
						<HierarchyTree />
						<div className="col-span-2">
							{editorState !== "empty" ? (
								<EntityEditor key={selectedEntity} inst={selectedEntity!} />
							) : (
								<div className="flex flex-col grow">
									<h2 className="text-center mb-10 text-2xl">Empty World</h2>
									<button
										className="btn"
										onClick={() => EditorData().newEntity({} as Entity)}
									>
										Create Entity
									</button>
								</div>
							)}
						</div>
						<div
							className={cn(
								!dark_mode && "invert",
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
		<div
			id="editor-root"
			className="relative max-h-screen h-screen w-full flex flex-col font-atkinson"
		>
			<Notifications onDismiss={handleDismissNotification} />
			<div className="h-full w-full lg:container flex flex-col gap-2 mx-auto">
				<EditorHeader />
				{editorContents}
				<div className="flex grow" />
				<EditorFooter />
			</div>
		</div>
	);
};
