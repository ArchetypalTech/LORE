import { useState, useEffect, useMemo } from "react";
import EditorData, { findInstValue, useEditorData } from "../data/editor.data";
import type { AnyObject } from "../lib/types";
import { Button } from "./ui/Button";
import { CollapsibleComponent } from "./CollapsibleComponent";
import { SystemCalls } from "@lib/systemCalls";
import { useTokenStore } from "@/lib/stores/token.store";
import type {
	CollabProposalEvent,
	ApprovedProposal,
	DescriptionText,
	Entity,
} from "@/lib/dojo_bindings/typescript/models.gen";

// ---------------------------------------------------------------------------
// Diff helpers
// ---------------------------------------------------------------------------

type DiffEntry = {
	component: string;
	field: string;
	oldValue: string;
	newValue: string;
};

const SKIP_FIELDS = new Set([
	"inst", "creator_address", "trail_id",
	"is_entity", "is_reactable", "is_area", "is_exit",
	"is_hub", "is_trail", "is_inventory_item", "is_container",
]);

const formatValue = (val: unknown): string => {
	if (val === undefined || val === null) return "—";
	if (Array.isArray(val)) {
		if (val.length === 0) return "(empty)";
		if (val.every(x => typeof x === "string" || typeof x === "number")) return val.join(", ");
		return `[${val.length} item${val.length !== 1 ? "s" : ""}]`;
	}
	if (typeof val === "object") {
		try { return JSON.stringify(val); } catch { return String(val); }
	}
	return String(val);
};

const truncate = (s: string, max = 80) =>
	s.length > max ? `${s.slice(0, max)}…` : s;

/**
 * Compares each field of `incoming` against the current syncPool state.
 * Handles flat components (Entity, Area, Container…) and array-keyed components
 * (DescriptionText[], Trigger[], Action[]…) where items are matched by their `key` field.
 */
const computeDiff = (
	incoming: AnyObject,
	current: AnyObject | undefined,
): DiffEntry[] => {
	const diffs: DiffEntry[] = [];

	for (const componentKey of Object.keys(incoming)) {
		const incomingComp = (incoming as Record<string, unknown>)[componentKey];
		if (!incomingComp || typeof incomingComp !== "object") continue;

		const currentRaw = current ? (current as Record<string, unknown>)[componentKey] : undefined;

		if (Array.isArray(incomingComp)) {
			// Multi-keyed components: DescriptionText[], Trigger[], Action[], etc.
			// Each item is matched to its syncPool counterpart by the `key` field.
			const currentArr = Array.isArray(currentRaw)
				? (currentRaw as Record<string, unknown>[])
				: currentRaw ? [currentRaw as Record<string, unknown>] : [];
			for (const item of (incomingComp as Record<string, unknown>[])) {
				const keyVal = item["key"];
				const currentItem = keyVal !== undefined
					? currentArr.find(e => String(e["key"]) === String(keyVal))
					: undefined;
				for (const fieldKey of Object.keys(item)) {
					// skip identity fields used for matching
					if (SKIP_FIELDS.has(fieldKey) || fieldKey === "key") continue;
					const newVal = item[fieldKey];
					const oldVal = currentItem ? currentItem[fieldKey] : undefined;
					const newStr = formatValue(newVal);
					const oldStr = formatValue(oldVal);
					if (newStr !== oldStr) {
						diffs.push({ component: componentKey, field: fieldKey, oldValue: oldStr, newValue: newStr });
					}
				}
			}
			continue;
		}

		// Single-instance components
		let currentComp: Record<string, unknown> | undefined;
		if (Array.isArray(currentRaw)) {
			const keyVal = (incomingComp as Record<string, unknown>)["key"];
			currentComp = keyVal !== undefined
				? (currentRaw as Record<string, unknown>[]).find(e => String(e["key"]) === String(keyVal))
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
				diffs.push({ component: componentKey, field: fieldKey, oldValue: oldStr, newValue: newStr });
			}
		}
	}

	return diffs;
};

// ---------------------------------------------------------------------------
// Proposal review helpers
// ---------------------------------------------------------------------------

type InstData = {
	entity: Entity | undefined;
	descriptionTexts: DescriptionText[];
	components: string[];
	isNew: boolean;
	/** Proposed component data keyed by component name — used for field-level diffs. */
	proposed: Record<string, unknown>;
};

/** Build a per-inst map of everything the proposal touches. */
const buildInstMap = (p: CollabProposalEvent): Map<string, InstData> => {
	const map = new Map<string, InstData>();

	const ensure = (inst: string): InstData => {
		if (!map.has(inst)) {
			const existsOnChain = EditorData().getEntity(inst, true) !== undefined;
			map.set(inst, { entity: undefined, descriptionTexts: [], components: [], isNew: !existsOnChain, proposed: {} });
		}
		return map.get(inst)!;
	};

	for (const e of p.entities) {
		const d = ensure(String(e.inst));
		d.entity = e as unknown as Entity;
		d.proposed["Entity"] = e;
		if (!d.components.includes("Entity")) d.components.push("Entity");
	}

	// Single-instance components — store full data for field-level diffing.
	const tagSingle = (arr: { inst: unknown }[], name: string) => {
		for (const c of arr) {
			const d = ensure(String(c.inst));
			d.proposed[name] = c;
			if (!d.components.includes(name)) d.components.push(name);
		}
	};
	// Multi-instance components — accumulate into array so computeDiff can match by key.
	const tagMulti = (arr: { inst: unknown }[], name: string) => {
		for (const c of arr) {
			const d = ensure(String(c.inst));
			const existing = d.proposed[name];
			if (Array.isArray(existing)) existing.push(c);
			else d.proposed[name] = [c];
			if (!d.components.includes(name)) d.components.push(name);
		}
	};

	for (const dt of p.description_texts) {
		const d = ensure(String(dt.inst));
		d.descriptionTexts.push(dt as unknown as DescriptionText);
		// also store in proposed so computeDiff produces a text diff
		const existing = d.proposed["DescriptionText"];
		if (Array.isArray(existing)) existing.push(dt);
		else d.proposed["DescriptionText"] = [dt];
		if (!d.components.includes("DescriptionText")) d.components.push("DescriptionText");
	}
	tagSingle(p.reactables as { inst: unknown }[], "Reactable");
	tagSingle(p.areas as { inst: unknown }[], "Area");
	tagSingle(p.exits as { inst: unknown }[], "Exit");
	tagSingle(p.hubs as { inst: unknown }[], "Hub");
	tagSingle(p.trails as { inst: unknown }[], "Trail");
	tagSingle(p.containers as { inst: unknown }[], "Container");
	tagSingle(p.inventory_items as { inst: unknown }[], "InventoryItem");
	tagMulti(p.triggers as { inst: unknown }[], "Trigger");
	tagMulti(p.conditions as { inst: unknown }[], "Condition");
	tagMulti(p.effects as { inst: unknown }[], "Effect");
	tagMulti(p.actions as { inst: unknown }[], "Action");
	// Relationship components — badge only, no field-level diff needed.
	for (const c of (p.parents as { inst: unknown }[])) {
		const d = ensure(String(c.inst));
		if (!d.components.includes("ParentToChildren")) d.components.push("ParentToChildren");
	}
	for (const c of (p.children as { inst: unknown }[])) {
		const d = ensure(String(c.inst));
		if (!d.components.includes("ChildToParent")) d.components.push("ChildToParent");
	}

	return map;
};

const COMPONENT_BADGE_COLORS: Record<string, string> = {
	Entity: "bg-indigo-100 text-indigo-700",
	Reactable: "bg-purple-100 text-purple-700",
	Area: "bg-teal-100 text-teal-700",
	Exit: "bg-orange-100 text-orange-700",
	DescriptionText: "bg-yellow-100 text-yellow-800",
	Container: "bg-cyan-100 text-cyan-700",
	InventoryItem: "bg-pink-100 text-pink-700",
	Hub: "bg-slate-100 text-slate-700",
	Trail: "bg-emerald-100 text-emerald-700",
	Trigger: "bg-rose-100 text-rose-700",
	Condition: "bg-violet-100 text-violet-700",
	Effect: "bg-lime-100 text-lime-700",
	Action: "bg-amber-100 text-amber-700",
	ParentToChildren: "bg-gray-100 text-gray-600",
	ChildToParent: "bg-gray-100 text-gray-600",
};

/** Builds an ApprovedProposal from a proposal limited to the selected entity insts. */
const buildApprovedProposal = (
	proposal: CollabProposalEvent,
	selectedInsts: Set<string>,
): ApprovedProposal => {
	const sel = (inst: unknown) => selectedInsts.has(String(inst));

	// Single-key component entity insts
	const singleInstSet = new Set<string>();
	for (const e of proposal.entities) {
		if (sel(e.inst)) singleInstSet.add(String(e.inst));
	}
	for (const c of [
		...proposal.reactables, ...proposal.areas, ...proposal.exits,
		...proposal.hubs, ...proposal.trails, ...proposal.containers,
		...proposal.inventory_items, ...proposal.parents, ...proposal.children,
	]) {
		const inst = (c as any).inst;
		if (sel(inst)) singleInstSet.add(String(inst));
	}
	const w_single_keys = Array.from(singleInstSet) as unknown as bigint[];

	// Description text entity insts
	const descInstSet = new Set<string>();
	for (const dt of proposal.description_texts) {
		if (sel(dt.inst)) descInstSet.add(String(dt.inst));
	}
	const w_description_texts = Array.from(descInstSet) as unknown as bigint[];

	// Multi-key (inst, key) pairs
	const w_multi_keys: unknown[] = [];
	for (const c of [
		...proposal.triggers, ...proposal.conditions,
		...proposal.effects, ...proposal.actions,
	]) {
		const cv = c as any;
		if (sel(cv.inst)) {
			w_multi_keys.push(cv.inst);
			w_multi_keys.push(cv.key);
		}
	}

	// Deletion approvals
	const d_single_keys = proposal.deleted_entity_insts
		.filter((inst) => sel(inst)) as unknown as bigint[];

	return {
		trail_id: proposal.trail_id,
		proposer: proposal.proposer,
		w_single_keys,
		w_description_texts,
		w_multi_keys: w_multi_keys as unknown as bigint[],
		d_single_keys,
		d_description_texts: [] as unknown as bigint[],
		d_multi_keys: [] as unknown as bigint[],
	};
};

// ---------------------------------------------------------------------------
// ProposalCard
// ---------------------------------------------------------------------------

const ProposalCard = ({ proposal }: { proposal: CollabProposalEvent }) => {
	const instMap = useMemo(() => buildInstMap(proposal), [proposal]);
	const allInsts = useMemo(() => Array.from(instMap.keys()), [instMap]);
	const [selected, setSelected] = useState<Set<string>>(new Set(allInsts));
	const [expanded, setExpanded] = useState<Set<string>>(new Set());
	const [busy, setBusy] = useState(false);

	const toggle = (inst: string) =>
		setSelected((prev) => {
			const next = new Set(prev);
			next.has(inst) ? next.delete(inst) : next.add(inst);
			return next;
		});

	const toggleExpand = (inst: string) =>
		setExpanded((prev) => {
			const next = new Set(prev);
			next.has(inst) ? next.delete(inst) : next.add(inst);
			return next;
		});

	const shortAddr = (addr: string) => `${addr.slice(0, 6)}…${addr.slice(-4)}`;

	const removeSelf = () => {
		EditorData().set({
			pendingProposals: EditorData().get().pendingProposals.filter((p) => p !== proposal),
		});
	};

	const handleApprove = async () => {
		if (selected.size === 0) return;
		setBusy(true);
		try {
			const approval = buildApprovedProposal(proposal, selected);
			await SystemCalls.approveProposal(approval);
			removeSelf();
		} catch (e) {
			console.error("approveProposal failed:", e);
		} finally {
			setBusy(false);
		}
	};

	const handleReject = async () => {
		setBusy(true);
		try {
			await SystemCalls.rejectProposal(BigInt(proposal.trail_id), proposal.proposer);
			removeSelf();
		} catch (e) {
			console.error("rejectProposal failed:", e);
		} finally {
			setBusy(false);
		}
	};

	return (
		<div className="flex flex-col gap-2 rounded border border-blue-300 bg-blue-50 p-2">
			{/* Header */}
			<div className="flex items-center justify-between">
				<div className="flex flex-col gap-0.5">
					<span className="text-[10px] opacity-50 uppercase tracking-wide">Proposer</span>
					<span className="font-mono text-xs">{shortAddr(proposal.proposer)}</span>
				</div>
				<div className="flex gap-1">
					<Button size="sm" disabled={busy || selected.size === 0} onClick={handleApprove}>
						Approve ({selected.size})
					</Button>
					<Button size="sm" variant="destructive" disabled={busy} onClick={handleReject}>
						Reject
					</Button>
				</div>
			</div>

			{/* Entity rows */}
			<div className="flex flex-col gap-1.5">
				{allInsts.map((inst) => {
					const data = instMap.get(inst)!;
					const displayName = data.entity?.name
						?? EditorData().getEntity(inst)?.Entity?.name
						?? shortAddr(inst);
					const isExpanded = expanded.has(inst);
					// Show expand arrow whenever there's component data to diff
					const hasDetails = Object.keys(data.proposed).length > 0;

					return (
						<div key={inst} className="rounded border border-blue-200 bg-white/60">
							<label className="flex items-start gap-2 cursor-pointer select-none px-2 py-1.5">
								<input
									type="checkbox"
									className="mt-0.5 shrink-0"
									checked={selected.has(inst)}
									onChange={() => toggle(inst)}
								/>
								<div className="flex flex-col min-w-0 flex-1 gap-1">
									{/* Name + NEW badge */}
									<div className="flex items-center gap-1.5 min-w-0">
										{data.isNew && (
											<span className="shrink-0 rounded px-1 py-px text-[9px] font-bold uppercase bg-green-100 text-green-700 border border-green-300">
												NEW
											</span>
										)}
										<span className="font-medium truncate">{displayName}</span>
									</div>
									{/* Component badges */}
									<div className="flex flex-wrap gap-1">
										{data.components.filter(c => c !== "Entity" && c !== "ChildToParent" && c !== "ParentToChildren").map((c) => (
											<span
												key={c}
												className={`rounded px-1 py-px text-[9px] font-medium ${COMPONENT_BADGE_COLORS[c] ?? "bg-gray-100 text-gray-600"}`}
											>
												{c}
											</span>
										))}
										{(data.components.includes("ChildToParent") || data.components.includes("ParentToChildren")) && (
											<span className="rounded px-1 py-px text-[9px] font-medium bg-gray-100 text-gray-500">
												relationship
											</span>
										)}
									</div>
								</div>
								{hasDetails && (
									<button
										type="button"
										className="shrink-0 opacity-40 hover:opacity-70 text-xs mt-0.5"
										onClick={(e) => { e.preventDefault(); toggleExpand(inst); }}
									>
										{isExpanded ? "▾" : "▸"}
									</button>
								)}
							</label>

							{/* Expanded content — unified field-level diffs for all components */}
							{isExpanded && (() => {
								const syncEntity = EditorData().getEntity(inst, true) as AnyObject | undefined;
								const diffs = computeDiff(data.proposed as AnyObject, syncEntity);
								return (
									<div className="border-t border-blue-100 px-3 py-2 flex flex-col gap-1">
										{diffs.length > 0 ? diffs.map((d, j) => (
											<div key={j} className="flex flex-col gap-0.5">
												<span className="text-[9px] opacity-50 font-medium uppercase tracking-wide">
													{d.component} · {d.field}
												</span>
												{data.isNew ? (
													<span className="pl-2 text-[10px] text-green-700 font-mono break-all">
														{truncate(d.newValue)}
													</span>
												) : (
													<div className="pl-2 flex flex-col gap-0.5 font-mono text-[10px]">
														<span className="text-red-500 break-all">− {truncate(d.oldValue)}</span>
														<span className="text-green-700 break-all">+ {truncate(d.newValue)}</span>
													</div>
												)}
											</div>
										)) : (
											<p className="text-[10px] opacity-40 italic">No field-level changes detected.</p>
										)}
									</div>
								);
							})()}
						</div>
					);
				})}

				{/* Deletions */}
				{proposal.deleted_entity_insts.length > 0 && (
					<div className="flex flex-col gap-1">
						<span className="text-[10px] uppercase tracking-wide opacity-50">Deletions</span>
						{proposal.deleted_entity_insts.map((inst) => {
							const instStr = String(inst);
							const name = EditorData().getEntity(instStr)?.Entity?.name ?? shortAddr(instStr);
							return (
								<label
									key={instStr}
									className="flex items-start gap-2 cursor-pointer select-none rounded px-2 py-1 bg-red-50 border border-red-200"
								>
									<input
										type="checkbox"
										className="mt-0.5 shrink-0"
										checked={selected.has(instStr)}
										onChange={() => toggle(instStr)}
									/>
									<span className="truncate text-red-600 line-through text-xs">{name}</span>
								</label>
							);
						})}
					</div>
				)}
			</div>
		</div>
	);
};

// ---------------------------------------------------------------------------
// ProposalReviewPanel
// ---------------------------------------------------------------------------

const ProposalReviewPanel = () => {
	const { pendingProposals, activeTrailId } = useEditorData();
	const { ownedTrailIds } = useTokenStore();
	const [syncing, setSyncing] = useState(false);

	const isOwner = activeTrailId !== undefined && ownedTrailIds.includes(activeTrailId);

	const doSync = async () => {
		if (!activeTrailId) return;
		setSyncing(true);
		try {
			await EditorData().syncProposals([activeTrailId]);
		} catch (e) {
			console.error("syncProposals failed:", e);
		} finally {
			setSyncing(false);
		}
	};

	useEffect(() => {
		if (isOwner) doSync();
	// eslint-disable-next-line react-hooks/exhaustive-deps
	}, [activeTrailId, isOwner]);

	if (!isOwner) return null;

	return (
		<CollapsibleComponent title={`Pending proposals (${pendingProposals.length})`}>
			<div className="flex flex-col gap-2 text-xs">
				<div className="flex justify-end">
					<Button size="sm" disabled={syncing} onClick={doSync}>
						{syncing ? "Refreshing…" : "Refresh"}
					</Button>
				</div>
				{pendingProposals.length === 0 ? (
					<p className="opacity-50">No pending proposals for this trail.</p>
				) : (
					pendingProposals.map((proposal, i) => (
						<ProposalCard key={`${String(proposal.trail_id)}-${proposal.proposer}-${i}`} proposal={proposal} />
					))
				)}
			</div>
		</CollapsibleComponent>
	);
};

// ---------------------------------------------------------------------------
// RemoteChangesPanel
// ---------------------------------------------------------------------------

/**
 * Option D remote-changes panel — shows updates queued by dojoSync for the active
 * collaboration trail. Updates to other trails never reach this queue; they're applied
 * to syncPool/dataPool directly. Accept merges the update into your working draft,
 * Dismiss ignores it until the next full reload.
 *
 * Each row is expandable to show a field-by-field diff between the incoming state
 * (from the collaborator's publish) and your current syncPool baseline.
 *
 * Below the live-update queue, ProposalReviewPanel shows CollabProposalEvents awaiting
 * trail-owner approval.
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

	return (
		<>
			{activeTrailId !== undefined && (
				<CollapsibleComponent
					title={`Remote changes (${remoteQueue.length})`}
					defaultCollapsed={remoteQueue.length === 0}
				>
					<div className="flex flex-col gap-2 text-xs">
						{remoteQueue.length === 0 ? (
							<p className="opacity-50">No pending updates for the active trail.</p>
						) : (
							<>
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
											<div className="flex items-center gap-2 px-2 py-1">
												<button
													className="flex flex-1 items-start gap-1 text-left min-w-0"
													onClick={() => toggle(i)}
												>
													<span className="mt-0.5 shrink-0 opacity-40">
														{isExpanded ? "▾" : "▸"}
													</span>
													<div className="flex flex-col min-w-0">
														<span className="font-semibold truncate">{String(name)}</span>
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
							</>
						)}
					</div>
				</CollapsibleComponent>
			)}

			<ProposalReviewPanel />
		</>
	);
};
