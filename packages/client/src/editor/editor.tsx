import "@styles/editor.css";
import { useHead } from "@unhead/react";
import { HousePlus, PersonStanding } from "lucide-react";
import { useEffect, useMemo, useState, useRef } from "react";
import { Toaster, toast } from "sonner";
import Terminal from "@/client/terminal/Terminal";
import { APP_EDITOR_SEO } from "@/data/app.data";
import { useDojoStore } from "@/lib/stores/dojo.store";
import { useUserStore } from "@/lib/stores/user.store";
import { useSyncEditorPermissions, useEditorStore } from "@/lib/stores/editor.store";
import { cn } from "@/lib/utils/utils";
import { EditorFooter } from "./components/EditorFooter";
import { EditorHeader } from "./components/EditorHeader";
import { EntityEditor } from "./components/EntityEditor";
import { HierarchyTree } from "./components/HierarchyTree";
import { Button } from "./components/ui/Button";
import { NoEntity } from "./components/ui/NoEntity";
import EditorData, { useEditorData } from "./data/editor.data";
import { Notifications } from "./lib/notifications";


type editorState = "not connected" | "loaded" | "empty" | "error";

export const Editor = () => {
	const {
		status: { status },
	} = useDojoStore();
	const { dark_mode } = useUserStore();
	const { dataPool, selectedEntity, isDirty } = useEditorData();
	const [editorState, setEditorState] = useState<editorState>("not connected");
	const { isEditor } = useSyncEditorPermissions();
	const {playTrailer, setIdleVideoPlaying } = useEditorStore();

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

	// --- IDLE VIDEO STATE ---
		const [isIdle, setIsIdle] = useState(false);
		const idleTimeoutRef = useRef<number | null>(null);
		const IDLE_DELAY = 1 * 30 * 1000; // 30 seconds (30000 ms)
		// 2 minutes (120000 ms)
		
		// helper: clear timer
		const clearIdleTimer = () => {
			if (idleTimeoutRef.current) {
				window.clearTimeout(idleTimeoutRef.current);
				idleTimeoutRef.current = null;
			}
		};
	
		// reset timer & cancel idle
		const resetIdleTimer = () => {
			clearIdleTimer();

			// If Trailer disabled → never enter idle mode
			// read latest store value
			if (!useEditorStore.getState().playTrailer) return;
	
			if (isIdle || useEditorStore.getState().idleVideoPlaying) {
				setIsIdle(false);
				setIdleVideoPlaying(false);
			}
	
			idleTimeoutRef.current = window.setTimeout(() => {
				console.log("Idle timer fired! Showing video");
				setIsIdle(true);
				setIdleVideoPlaying(true);
			}, IDLE_DELAY);
		};

	useEffect(() => {
		if (!isDirty) {
			toast.dismiss("editor-dirty");
		}
	}, [isDirty]);

	useEffect(() => {
		if (editorState === "not connected") {
			Notifications().startLoading();
		} else if (editorState === "loaded") {
			Notifications().finalizeLoading();
		}
	}, [editorState]);

	useEffect(() => {
		dataPool;
		const hasObjects = EditorData().getEntities().length > 0;
		if (status === "loading") {
			setEditorState("not connected");
			return;
		}
		if (hasObjects) {
			if (EditorData().selectedEntity === undefined) {
				// find first top-level entity
				const topLevelEntity = EditorData().getEntities().find((e) => e!.ChildToParent === undefined);
				EditorData().restoreSelectedEntity(topLevelEntity?.Entity?.inst);
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

	useEffect(() => {
		(async () => await EditorData().syncEntities())();
	}, []);

	useEffect(() => {
		if (!playTrailer) {
			setIsIdle(false);
			setIdleVideoPlaying(false);
		}
	}, [playTrailer, setIdleVideoPlaying]);
	

	const isLoaded = (editorState === "loaded");

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
					!isLoaded ? (
						<div className="flex grow flex-col w-full" style={{ height: "80%" }}>
							<NoEntity />
						</div>
					) : (
						<div className="relative grid grid-cols-5 gap-4">
							<HierarchyTree />
							<div className="use-editor-styles col-span-2">
								<EntityEditor key={selectedEntity} inst={selectedEntity!} />
							</div>
							<div
								className={cn(
									!dark_mode && "contrast-120 invert",
									"relative col-span-2 h-screen max-h-[calc(100vh-10rem)] opacity-50 hover:opacity-100",
								)}
							>
								<Terminal gameId={0} />
							</div>
						</div>
					)
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

	// ---------------------- IDLE DETECTION: listen to user activity ----------------------
		useEffect(() => {
			if (typeof window === "undefined") return;
	
			const onActivity = () => {
				resetIdleTimer();
			};
	
			// Attach to window/document as before
			window.addEventListener("mousemove", onActivity);
			window.addEventListener("keydown", onActivity);
			window.addEventListener("click", onActivity);
			window.addEventListener("touchstart", onActivity);
	
			// Start the timer
			resetIdleTimer();
	
			return () => {
				window.removeEventListener("mousemove", onActivity);
				window.removeEventListener("keydown", onActivity);
				window.removeEventListener("click", onActivity);
				window.removeEventListener("touchstart", onActivity);
	
				clearIdleTimer();
				setIdleVideoPlaying(false);
			};
		}, []);
	
		// If idle state changes locally, ensure store is in sync (extra safety)
		useEffect(() => {
			console.log("Idle state changed:", isIdle);
			setIdleVideoPlaying(isIdle);
		}, [isIdle, setIdleVideoPlaying]);

	const idleEditorVideoPlaying = useEditorStore((state) => state.idleVideoPlaying);
	return (
		<>
			<Toaster expand visibleToasts={4} position="top-left" />
			<div
				id="editor-root"
				className="fixed h-screen max-h-screen w-full overflow-scroll px-4 font-primary"
			>
				{/* Fullscreen idle video overlay — now in front of terminal */}
				{playTrailer && idleEditorVideoPlaying  && (
					<video
						autoPlay
						loop
						playsInline
						src="/video/ORugTrailer_NQ.mp4"
						className="fixed inset-0 w-screen h-screen object-cover z-[50]"
					/>
				)}
				<div className="relative mx-auto h-full max-w-screen">
					<EditorHeader />
					<div className="relative m-0 mx-auto p-0 h-full">
						{isEditor && editorContents}
					</div>
				</div>
			</div>
			{isEditor && isLoaded&& !idleEditorVideoPlaying && <EditorFooter />}
		</>
	);
};
