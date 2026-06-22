import { useMemo } from "react";
import EditorData, { useEditorData } from "../data/editor.data";

/**
 * Lets the user pick the trail they are actively collaborating on.
 * Setting activeTrailId scopes the staging panel and remote-update queue to that trail —
 * everything else keeps syncing directly, same as before Option D.
 */
export const TrailSelector = () => {
	const { dataPool, activeTrailId } = useEditorData();

	const trails = useMemo(() => {
		const seen = new Map<string, { trailId: bigint; label: string }>();
		for (const value of dataPool.values()) {
			const entity = value as { Trail?: { trail_id: unknown }; Entity?: { name?: string } };
			if (!entity?.Trail) continue;
			const trailId = BigInt(entity.Trail.trail_id as never);
			const key = trailId.toString();
			if (!seen.has(key)) {
				seen.set(key, { trailId, label: entity.Entity?.name || `Trail ${key}` });
			}
		}
		return [...seen.values()].sort((a, b) => a.label.localeCompare(b.label));
	}, [dataPool]);

	return (
		<div className="flex items-center gap-2 text-xs">
			<label htmlFor="trail-selector" className="font-semibold whitespace-nowrap">
				Collaboration trail:
			</label>
			<select
				id="trail-selector"
				className="rounded border border-gray-300 bg-white px-2 py-1"
				value={activeTrailId?.toString() ?? ""}
				onChange={(e) =>
					EditorData().setActiveTrailId(e.target.value ? BigInt(e.target.value) : undefined)
				}
			>
				<option value="">No active trail (all updates apply directly)</option>
				{trails.map((t) => (
					<option key={t.trailId.toString()} value={t.trailId.toString()}>
						{t.label}
					</option>
				))}
			</select>
		</div>
	);
};
