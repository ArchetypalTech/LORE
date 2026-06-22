import { useMemo } from "react";
import EditorData, { useEditorData } from "../data/editor.data";
import type { ChangeSet } from "../lib/types";
import { publishConfigToContract } from "../publisher";
import { Button } from "./ui/Button";
import { CollapsibleComponent } from "./CollapsibleComponent";

const entityLabel = (c: ChangeSet) =>
	EditorData().getEntity(c.inst)?.Entity?.name ?? String(c.inst);

const componentNames = (c: ChangeSet) => Object.keys(c.object).join(", ");

/**
 * Option D staging panel — shows changeSet/stagedChanges filtered to the active
 * collaboration trail (or everything, when no trail is selected). Publishing only
 * sends what's in stagedChanges, leaving the rest of the changeSet untouched.
 */
export const StagingPanel = () => {
	const { changeSet, stagedChanges, activeTrailId } = useEditorData();

	const forActiveTrail = (items: ChangeSet[]) =>
		activeTrailId === undefined
			? items
			: items.filter((c) => {
				const entity = EditorData().getEntity(c.inst);
				return BigInt(entity?.Entity?.trail_id ?? 0) === activeTrailId;
			});

	const unstaged = useMemo(() => forActiveTrail(changeSet), [changeSet, activeTrailId]);
	const staged = useMemo(() => forActiveTrail(stagedChanges), [stagedChanges, activeTrailId]);

	const allCount = unstaged.length + staged.length;

	return (
		<CollapsibleComponent title={`Staging (${unstaged.length} unstaged / ${staged.length} staged)`}>
			<div className="flex flex-col gap-3 text-xs">
				<section className="flex flex-col gap-1">
					<div className="flex items-center justify-between">
						<h4 className="font-semibold">Unstaged changes ({unstaged.length})</h4>
						{unstaged.length > 0 && (
							<div className="flex gap-1">
								<Button size="sm" onClick={() => EditorData().stageChanges()}>
									Stage all
								</Button>
								<Button size="sm" variant="destructive" onClick={() => EditorData().discardChanges(unstaged.map((c) => c.inst))}>
									Discard all
								</Button>
							</div>
						)}
					</div>
					{unstaged.length === 0 && <p className="opacity-50">Nothing to stage.</p>}
					{unstaged.map((c, i) => (
						<div key={`${String(c.inst)}-${c.type}-${i}`} className="flex items-center justify-between gap-2 rounded border border-gray-200 px-2 py-1">
							<span className="truncate">{entityLabel(c)}</span>
							<span className="rounded bg-gray-200 px-1 text-[10px] uppercase">{c.type}</span>
							<span className="truncate opacity-50">{componentNames(c)}</span>
							<div className="flex gap-1">
								<Button size="sm" onClick={() => EditorData().stageChanges([c.inst])}>
									Stage
								</Button>
								<Button size="sm" variant="destructive" onClick={() => EditorData().discardChanges([c.inst])}>
									Discard
								</Button>
							</div>
						</div>
					))}
				</section>

				<section className="flex flex-col gap-1">
					<div className="flex items-center justify-between">
						<h4 className="font-semibold">Staged ({staged.length})</h4>
						{staged.length > 0 && (
							<Button size="sm" variant="destructive" onClick={() => EditorData().discardChanges(staged.map((c) => c.inst))}>
								Discard all
							</Button>
						)}
					</div>
					{staged.length === 0 && <p className="opacity-50">Nothing staged yet.</p>}
					{staged.map((c, i) => (
						<div key={`${String(c.inst)}-${c.type}-${i}`} className="flex items-center justify-between gap-2 rounded border border-gray-200 px-2 py-1">
							<span className="truncate">{entityLabel(c)}</span>
							<span className="rounded bg-gray-200 px-1 text-[10px] uppercase">{c.type}</span>
							<div className="flex gap-1">
								<Button size="sm" onClick={() => EditorData().unstageChanges([c.inst])}>
									Unstage
								</Button>
								<Button size="sm" variant="destructive" onClick={() => EditorData().discardChanges([c.inst])}>
									Discard
								</Button>
							</div>
						</div>
					))}
					<Button
						disabled={staged.length === 0}
						onClick={() => publishConfigToContract()}
						variant="hero"
					>
						Publish staged ({staged.length})
					</Button>
				</section>

				{allCount > 0 && (
					<Button variant="destructive" onClick={() => EditorData().discardChanges()}>
						Discard all changes ({allCount})
					</Button>
				)}
			</div>
		</CollapsibleComponent>
	);
};
