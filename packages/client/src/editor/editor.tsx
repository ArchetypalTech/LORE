import "@styles/editor.css";
import { useEffect, useMemo, useState } from "react";
import { RoomEditor } from "./components/RoomEditor";
import ObjectEditor from "./components/ObjectEditor";
import Notifications from "./components/Notifications";
import { EditorHeader } from "./components/EditorHeader";
import { useHead } from "@unhead/react";
import EditorStore from "./editor.store";
import { APP_EDITOR_SEO } from "@/data/app.data";
import EditorData, { useEditorData } from "./editor.data";
import type { T_Room } from "./lib/types";
import { tick } from "@/lib/utils/utils";
import { EditorFooter } from "./components/EditorFooter";
import { useDojoStore } from "@/lib/stores/dojo.store";
import { HierarchyTree } from "./components/HierarchyTree";
import { EntityEditor } from "./components/EntityEditor";
import Terminal from "@/client/terminal/Terminal";

type editorState = "not connected" | "loaded" | "empty" | "error";

export const Editor = () => {
	const {
		status: { status },
	} = useDojoStore();
	const { entities, selectedEntity, isDirty } = useEditorData();
	const [editorState, setEditorState] = useState<editorState>("not connected");

	const selectEntity = async (index: number) => {
		EditorData().set({
			selectedEntity: EditorData().getItem(index),
		});
		await tick();
		await selectObject(0);
	};

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
		EditorStore().notifications.clear();
	};

	useEffect(() => {
		const hasObjects = entities.length > 0;
		console.log(hasObjects, status);
		if (status === "loading") {
			setEditorState("not connected");
			return;
		}
		if (hasObjects) {
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
				return (
					<div className="flex">
						<div className="grid grid-cols-3 gap-4">
							<HierarchyTree />
							<EntityEditor />
							<div className="invert">
								<Terminal />
							</div>
						</div>
					</div>
				);
			case "empty":
				return (
					<div className="w-full h-full flex place-items-center place-content-center grow">
						<div className="flex w-30 ">
							<div className="flex flex-col grow">
								<h2 className="text-center mb-10 text-2xl">Empty World</h2>
								<button className="btn" onClick={EditorData().newRoom}>
									Create Room
								</button>
							</div>
						</div>
					</div>
				);
			case "error":
				return (
					<div className="w-full h-full flex place-items-center place-content-center grow">
						<div className="flex w-30 ">
							<div className="flex flex-col grow">
								<h2 className="text-center mb-10 text-2xl">Error</h2>
								<button className="btn" onClick={EditorData().newRoom}>
									Try again
								</button>
							</div>
						</div>
					</div>
				);
		}
	}, [editorState]);

	return (
		<div id="editor-root" className="relative h-full w-full flex flex-col">
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
