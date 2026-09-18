import { useState } from "react";
import type { BigNumberish } from "starknet";
import EditorData, { useEditorData } from "../data/editor.data";
import type { EntityCollection } from "../lib/types";
import { Button } from "./ui/Button";
import { CollapsibleComponent } from "./CollapsibleComponent";

type SimLogEntry = {
	inst: BigNumberish;
	entityName: string;
	trailId?: bigint;
	editorLabel: string;
	routedTo: "queue" | "direct";
	time: string;
};

/**
 * Dev-only simulation panel for Option D. Fabricates fake "incoming" entity edits and
 * routes them through the real trail-aware dojoSync pipeline — exactly what would happen
 * if another editor's change arrived over the Torii subscription. Nothing here ever calls
 * the contract: simulated edits only ever touch local store state (dataPool/syncPool),
 * and Accept/Dismiss on the resulting queue entries (in the Remote Changes panel below)
 * are pure local-state operations too.
 */
export const CollaborationTestPanel = () => {
	const { dataPool, activeTrailId } = useEditorData();
	const [log, setLog] = useState<SimLogEntry[]>([]);

	const runSimulation = () => {
		const entities = [...dataPool.values()] as EntityCollection[];

		const inActiveTrail = activeTrailId !== undefined
			? entities.filter((e) => e.Entity && BigInt(e.Entity.trail_id ?? 0) === activeTrailId)
			: [];
		const outsideActiveTrail = entities.filter(
			(e) => e.Entity && (activeTrailId === undefined || BigInt(e.Entity.trail_id ?? 0) !== activeTrailId),
		);

		const plan: { entity: EntityCollection; label: string }[] = [];
		if (inActiveTrail[0]) plan.push({ entity: inActiveTrail[0], label: "Simulated Editor B" });
		if (inActiveTrail[1]) plan.push({ entity: inActiveTrail[1], label: "Simulated Editor C" });
		if (outsideActiveTrail[0]) plan.push({ entity: outsideActiveTrail[0], label: "Simulated Editor D (other trail)" });

		if (plan.length === 0) {
			setLog((prev) => [
				{
					inst: "0",
					entityName: "—",
					editorLabel: "—",
					routedTo: "direct",
					time: new Date().toLocaleTimeString(),
				},
				...prev,
			]);
			return;
		}

		const results: SimLogEntry[] = [];
		for (const { entity, label } of plan) {
			const inst = entity.Entity!.inst;
			const result = EditorData().simulateRemoteEntityEdit(inst, label);
			if (!result) continue;
			results.push({
				inst: result.inst,
				entityName: result.entityName,
				trailId: result.trailId,
				editorLabel: label,
				routedTo: result.routedTo,
				time: new Date().toLocaleTimeString(),
			});
		}
		setLog((prev) => [...results, ...prev]);
	};

	return (
		<CollapsibleComponent title="🧪 Test Collaborative">
			<div className="flex flex-col gap-2 text-xs">
				<p className="opacity-70">
					Simulates incoming edits from other editors — purely local, nothing is sent to the
					contract. Edits to entities in the active trail land in the Remote Changes queue below
					for you to Accept or Dismiss; edits to other trails apply immediately, same as today.
				</p>

				{activeTrailId === undefined && (
					<p className="rounded bg-yellow-50 border border-yellow-300 px-2 py-1">
						No active trail selected — every simulated edit will apply directly. Pick a trail
						above to see the review queue in action.
					</p>
				)}

				<div className="flex gap-2">
					<Button onClick={runSimulation}>Simulate Incoming Changes</Button>
					{log.length > 0 && (
						<Button size="sm" variant="ghost" onClick={() => setLog([])}>
							Clear log
						</Button>
					)}
				</div>

				{log.length > 0 && (
					<div className="flex flex-col gap-1 max-h-40 overflow-y-auto">
						{log.map((entry, i) => (
							<div
								key={`${String(entry.inst)}-${entry.time}-${i}`}
								className="flex items-center justify-between gap-2 rounded border border-gray-200 px-2 py-1"
							>
								<span className="opacity-50">{entry.time}</span>
								<span className="truncate flex-1">
									{entry.entityName} ← {entry.editorLabel}
								</span>
								<span
									className={
										entry.routedTo === "queue"
											? "rounded bg-amber-200 px-1 text-[10px] uppercase"
											: "rounded bg-green-200 px-1 text-[10px] uppercase"
									}
								>
									{entry.routedTo === "queue" ? "queued for review" : "applied directly"}
								</span>
							</div>
						))}
					</div>
				)}
			</div>
		</CollapsibleComponent>
	);
};
