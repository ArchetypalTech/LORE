import { useState } from "react";
import EditorData, { findInstValue, useEditorData } from "../data/editor.data";
import type { AnyObject } from "../lib/types";
import { Button } from "./ui/Button";
import { CollapsibleComponent } from "./CollapsibleComponent";

// ---------------------------------------------------------------------------
// Diff helpers
// ---------------------------------------------------------------------------

type DiffEntry = {
	component: string;
	field: string;
	oldValue: string;
	newValue: string;
};

const SKIP_FIELDS = new Set(["inst"]);

const formatValue = (val: unknown): string => {
	if (val === undefined || val === null) return "—";
	if (Array.isArray(val)) return `[${val.length} item${val.length !== 1 ? "s" : ""}]`;
	if (typeof val === "object") {
		try { return JSON.stringify(val); } catch { return String(val); }
	}
	return String(val);
};

const truncate = (s: string, max = 80) =>
	s.length > max ? `${s.slice(0, max)}…` : s;

/**
 * Compares each field of `incoming` against the current syncPool state.
 * Handles both flat components (Entity, Area) and array-keyed components
 * (DescriptionText[], Action[]) where entries are matched by their `key` field.
 */
const computeDiff = (
	incoming: AnyObject,
	current: AnyObject | undefined,
): DiffEntry[] => {
	const diffs: DiffEntry[] = [];

	for (const componentKey of Object.keys(incoming)) {
		const incomingComp = (incoming as Record<string, unknown>)[componentKey];
		if (!incomingComp || typeof incomingComp !== "object" || Array.isArray(incomingComp)) continue;

		const currentRaw = current ? (current as Record<string, unknown>)[componentKey] : undefined;

		// If the current value is an array (e.g. DescriptionText[]), find the matching
		// entry by the `key` field present on the incoming component.
		let currentComp: Record<string, unknown> | undefined;
		if (Array.isArray(currentRaw)) {
			const keyVal = (incomingComp as Record<string, unknown>)["key"];
			currentComp = keyVal !== undefined
				? (currentRaw as Record<string, unknown>[]).find(
					(entry) => String(entry["key"]) === String(keyVal),
				)
				: undefined;
		} else {
			currentComp = currentRaw as Record<string, unknown> | undefined;
		}

		for (const fieldKey of Object.keys(incomingComp as object)) {
			if (SKIP_FIELDS.has(fieldKey)) continue;
			const newVal = (incomingComp as Record<string, unknown>)[fieldKey];
			const oldVal = currentComp ? currentComp[fieldKey] : undefined;
			const newStr = formatValue(newVal);
			const oldStr = formatValue(oldVal);
			if (newStr !== oldStr) {
				diffs.push({
					component: componentKey,
					field: fieldKey,
					oldValue: oldStr,
					newValue: newStr,
				});
			}
		}
	}

	return diffs;
};

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

/**
 * Option D remote-changes panel — shows updates queued by dojoSync for the active
 * collaboration trail. Updates to other trails never reach this queue; they're applied
 * to syncPool/dataPool directly. Accept merges the update into your working draft,
 * Dismiss ignores it until the next full reload.
 *
 * Each row is expandable to show a field-by-field diff between the incoming state
 * (from the collaborator's publish) and your current syncPool baseline.
 */
export const RemoteChangesPanel = () => {
	const { remoteQueue, activeTrailId } = useEditorData();
	const [expanded, setExpanded] = useState<Set<number>>(new Set());

	const toggle = (i: number) =>
		setExpanded((prev) => {
			const next = new Set(prev);
			next.has(i) ? next.delete(i) : next.add(i);
			return next;
		});

	if (activeTrailId === undefined) return null;
	if (remoteQueue.length === 0) {
		return (
			<CollapsibleComponent title="Remote changes (0)" defaultCollapsed>
				<p className="text-xs opacity-50">No pending updates for the active trail.</p>
			</CollapsibleComponent>
		);
	}

	return (
		<CollapsibleComponent title={`Remote changes (${remoteQueue.length})`}>
			<div className="flex flex-col gap-2 text-xs">
				<div className="flex justify-end">
					<Button size="sm" onClick={() => EditorData().acceptAllRemoteUpdates()}>
						Accept all
					</Button>
				</div>

				{remoteQueue.map((obj, i) => {
					const inst = findInstValue(obj as AnyObject);
					const currentEntity = inst !== undefined
						? EditorData().getEntity(inst, true) as AnyObject | undefined
						: undefined;
					const name = inst !== undefined
						? EditorData().getEntity(inst)?.Entity?.name ?? String(inst)
						: "unknown";
					const components = Object.keys(obj as object).join(", ");
					const diffs = computeDiff(obj as AnyObject, currentEntity);
					const isExpanded = expanded.has(i);

					return (
						<div
							key={i}
							className="flex flex-col rounded border border-amber-300 bg-amber-50"
						>
							{/* Row header — click to expand/collapse diff */}
							<div className="flex items-center gap-2 px-2 py-1">
								<button
									className="flex flex-1 items-start gap-1 text-left min-w-0"
									onClick={() => toggle(i)}
								>
									<span className="mt-0.5 shrink-0 opacity-40">
										{isExpanded ? "▾" : "▸"}
									</span>
									<div className="flex flex-col min-w-0">
										<span className="font-semibold truncate">{name}</span>
										<span className="opacity-50 truncate">{components}</span>
									</div>
								</button>
								<div className="flex shrink-0 gap-1">
									<Button
										size="sm"
										onClick={() => EditorData().acceptRemoteUpdate(obj)}
									>
										Accept
									</Button>
									<Button
										size="sm"
										variant="destructive"
										onClick={() => EditorData().dismissRemoteUpdate(obj)}
									>
										Dismiss
									</Button>
								</div>
							</div>

							{/* Diff panel — visible when expanded */}
							{isExpanded && (
								<div className="border-t border-amber-200 px-3 py-2 flex flex-col gap-2">
									{diffs.length === 0 ? (
										<p className="opacity-50 italic">No field changes detected.</p>
									) : (
										diffs.map((d, j) => (
											<div key={j} className="flex flex-col gap-0.5">
												<span className="opacity-60 font-medium">
													{d.component}.{d.field}
												</span>
												<div className="flex flex-col gap-0.5 pl-2 font-mono">
													<span className="text-red-600 break-all">
														− {truncate(d.oldValue)}
													</span>
													<span className="text-green-700 break-all">
														+ {truncate(d.newValue)}
													</span>
												</div>
											</div>
										))
									)}
								</div>
							)}
						</div>
					);
				})}
			</div>
		</CollapsibleComponent>
	);
};
