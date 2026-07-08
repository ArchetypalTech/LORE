import { useState, useEffect, useMemo, type ReactElement } from "react";
import EditorData, { findInstValue, useEditorData } from "../data/editor.data";
import type { AnyObject } from "../lib/types";
import type { BigNumberish } from "starknet";
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
	/** Components proposed for deletion — shown as red badges, no diff needed. */
	deletedComponents: string[];
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
			map.set(inst, { entity: undefined, descriptionTexts: [], components: [], deletedComponents: [], isNew: !existsOnChain, proposed: {} });
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

	// Component-level deletions — red badge, no diff data needed.
	const tagDeleted = (insts: BigNumberish[], name: string) => {
		for (const inst of insts) {
			const d = ensure(String(inst));
			if (!d.deletedComponents.includes(name)) d.deletedComponents.push(name);
		}
	};
	const tagDeletedPairs = (flat: BigNumberish[], name: string) => {
		for (let i = 0; i + 1 < flat.length; i += 2) {
			const d = ensure(String(flat[i]));
			if (!d.deletedComponents.includes(name)) d.deletedComponents.push(name);
		}
	};
	tagDeleted(p.deleted_reactable_insts as BigNumberish[], "Reactable");
	tagDeleted(p.deleted_area_insts as BigNumberish[], "Area");
	tagDeleted(p.deleted_exit_insts as BigNumberish[], "Exit");
	tagDeleted(p.deleted_container_insts as BigNumberish[], "Container");
	tagDeleted(p.deleted_inventory_item_insts as BigNumberish[], "InventoryItem");
	tagDeleted(p.deleted_hub_insts as BigNumberish[], "Hub");
	tagDeleted(p.deleted_trail_insts as BigNumberish[], "Trail");
	tagDeleted(p.deleted_parent_insts as BigNumberish[], "ParentToChildren");
	tagDeleted(p.deleted_child_insts as BigNumberish[], "ChildToParent");
	tagDeletedPairs(p.deleted_description_text_keys as BigNumberish[], "DescriptionText");
	tagDeletedPairs(p.deleted_trigger_keys as BigNumberish[], "Trigger");
	tagDeletedPairs(p.deleted_condition_keys as BigNumberish[], "Condition");
	tagDeletedPairs(p.deleted_effect_keys as BigNumberish[], "Effect");
	tagDeletedPairs(p.deleted_action_keys as BigNumberish[], "Action");

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

// ---------------------------------------------------------------------------
// Per-component approval helpers
// ---------------------------------------------------------------------------

const SINGLE_WRITE_COMPS = [
	"Entity", "Reactable", "Area", "Exit", "Hub", "InventoryItem",
	"Container", "Trail", "ParentToChildren", "ChildToParent",
] as const;
const MULTI_WRITE_COMPS = ["Trigger", "Condition", "Effect", "Action"] as const;
const SINGLE_WRITE_SET = new Set<string>(SINGLE_WRITE_COMPS);
const MULTI_WRITE_SET = new Set<string>(MULTI_WRITE_COMPS);

const getDelSingleArr = (p: CollabProposalEvent, comp: string): BigNumberish[] => {
	const m: Record<string, BigNumberish[]> = {
		Reactable: p.deleted_reactable_insts as BigNumberish[],
		Area: p.deleted_area_insts as BigNumberish[],
		Exit: p.deleted_exit_insts as BigNumberish[],
		Container: p.deleted_container_insts as BigNumberish[],
		InventoryItem: p.deleted_inventory_item_insts as BigNumberish[],
		Hub: p.deleted_hub_insts as BigNumberish[],
		Trail: p.deleted_trail_insts as BigNumberish[],
		ParentToChildren: p.deleted_parent_insts as BigNumberish[],
		ChildToParent: p.deleted_child_insts as BigNumberish[],
	};
	return m[comp] ?? [];
};

const getDelPairsForComp = (p: CollabProposalEvent, comp: string): BigNumberish[] => {
	const m: Record<string, BigNumberish[]> = {
		DescriptionText: p.deleted_description_text_keys as BigNumberish[],
		Trigger: p.deleted_trigger_keys as BigNumberish[],
		Condition: p.deleted_condition_keys as BigNumberish[],
		Effect: p.deleted_effect_keys as BigNumberish[],
		Action: p.deleted_action_keys as BigNumberish[],
	};
	return m[comp] ?? [];
};

/**
 * All selectable item keys for a specific inst.
 * Format: "w:{inst}:{comp}" / "w:{inst}:{comp}:{key}" for writes,
 *         "d:{inst}:{comp}" / "d:{inst}:{comp}:{key}" for deletions.
 */
const getInstSelectableKeys = (
	inst: string,
	data: InstData,
	proposal: CollabProposalEvent,
): string[] => {
	const keys: string[] = [];
	for (const comp of data.components) {
		if (SINGLE_WRITE_SET.has(comp)) {
			keys.push(`w:${inst}:${comp}`);
		} else if (comp === "DescriptionText") {
			const arr = data.proposed.DescriptionText as { key: unknown }[] | undefined;
			if (Array.isArray(arr)) for (const item of arr) keys.push(`w:${inst}:DescriptionText:${item.key}`);
		} else if (MULTI_WRITE_SET.has(comp)) {
			const arr = data.proposed[comp] as { key: unknown }[] | undefined;
			if (Array.isArray(arr)) for (const item of arr) keys.push(`w:${inst}:${comp}:${item.key}`);
		}
	}
	for (const comp of data.deletedComponents) {
		if (comp === "DescriptionText") {
			const flat = proposal.deleted_description_text_keys as BigNumberish[];
			for (let i = 0; i + 1 < flat.length; i += 2)
				if (String(flat[i]) === inst) keys.push(`d:${inst}:DescriptionText:${flat[i + 1]}`);
		} else if (MULTI_WRITE_SET.has(comp)) {
			const flat = getDelPairsForComp(proposal, comp);
			for (let i = 0; i + 1 < flat.length; i += 2)
				if (String(flat[i]) === inst) keys.push(`d:${inst}:${comp}:${flat[i + 1]}`);
		} else {
			keys.push(`d:${inst}:${comp}`);
		}
	}
	return keys;
};

const buildSelectableKeys = (
	proposal: CollabProposalEvent,
	instMap: Map<string, InstData>,
): Set<string> => {
	const keys = new Set<string>();
	for (const [inst, data] of instMap)
		for (const k of getInstSelectableKeys(inst, data, proposal)) keys.add(k);
	for (const inst of proposal.deleted_entity_insts) keys.add(`d:${String(inst)}:Entity`);
	return keys;
};

/** Builds an ApprovedProposal limited to the selected component items. */
const buildApprovedProposal = (
	proposal: CollabProposalEvent,
	selected: Set<string>,
	instMap: Map<string, InstData>,
): ApprovedProposal => {
	const sel = (key: string) => selected.has(key);

	// w_single_keys: insts with at least one selected single-key write component
	const wSingleSet = new Set<string>();
	for (const [inst, data] of instMap) {
		if (SINGLE_WRITE_COMPS.some(c => data.components.includes(c) && sel(`w:${inst}:${c}`)))
			wSingleSet.add(inst);
	}

	// w_description_texts: flat [inst, key, ...] pairs
	const wDesc: BigNumberish[] = [];
	for (const dt of proposal.description_texts) {
		if (sel(`w:${dt.inst}:DescriptionText:${dt.key}`)) { wDesc.push(dt.inst); wDesc.push(dt.key ?? 0); }
	}

	// w_multi_keys: flat [inst, key, ...] pairs for Trigger/Condition/Effect/Action
	const wMulti: BigNumberish[] = [];
	for (const [comp, arr] of [
		["Trigger", proposal.triggers], ["Condition", proposal.conditions],
		["Effect", proposal.effects], ["Action", proposal.actions],
	] as [string, { inst: unknown; key: unknown }[]][]) {
		for (const c of arr) {
			if (sel(`w:${c.inst}:${comp}:${c.key}`)) { wMulti.push(c.inst as BigNumberish); wMulti.push(c.key as BigNumberish); }
		}
	}

	// d_single_keys: entity deletions + selected single-key component deletions
	const dSingleSet = new Set<string>();
	for (const inst of proposal.deleted_entity_insts)
		if (sel(`d:${inst}:Entity`)) dSingleSet.add(String(inst));
	for (const comp of ["Reactable","Area","Exit","Container","InventoryItem","Hub","Trail","ParentToChildren","ChildToParent"]) {
		for (const inst of getDelSingleArr(proposal, comp))
			if (sel(`d:${inst}:${comp}`)) dSingleSet.add(String(inst));
	}

	// d_description_texts: flat [inst, key, ...] pairs
	const dDesc: BigNumberish[] = [];
	const ddFlat = proposal.deleted_description_text_keys as BigNumberish[];
	for (let i = 0; i + 1 < ddFlat.length; i += 2) {
		if (sel(`d:${ddFlat[i]}:DescriptionText:${ddFlat[i + 1]}`)) { dDesc.push(ddFlat[i]); dDesc.push(ddFlat[i + 1]); }
	}

	// d_multi_keys: flat [inst, key, ...] pairs for Trigger/Condition/Effect/Action deletions
	const dMulti: BigNumberish[] = [];
	for (const comp of MULTI_WRITE_COMPS) {
		const flat = getDelPairsForComp(proposal, comp);
		for (let i = 0; i + 1 < flat.length; i += 2)
			if (sel(`d:${flat[i]}:${comp}:${flat[i + 1]}`)) { dMulti.push(flat[i]); dMulti.push(flat[i + 1]); }
	}

	return {
		trail_id: proposal.trail_id,
		proposer: proposal.proposer,
		w_single_keys: Array.from(wSingleSet) as unknown as bigint[],
		w_description_texts: wDesc as unknown as bigint[],
		w_multi_keys: wMulti as unknown as bigint[],
		d_single_keys: Array.from(dSingleSet) as unknown as bigint[],
		d_description_texts: dDesc as unknown as bigint[],
		d_multi_keys: dMulti as unknown as bigint[],
	};
};

// ---------------------------------------------------------------------------
// ProposalCard
// ---------------------------------------------------------------------------

const ProposalCard = ({ proposal }: { proposal: CollabProposalEvent }) => {
	const instMap = useMemo(() => buildInstMap(proposal), [proposal]);
	const allInsts = useMemo(() => Array.from(instMap.keys()), [instMap]);
	const [selected, setSelected] = useState<Set<string>>(() => buildSelectableKeys(proposal, instMap));
	const [expanded, setExpanded] = useState<Set<string>>(new Set());
	const [busy, setBusy] = useState(false);

	const toggleItem = (key: string) =>
		setSelected(prev => {
			const next = new Set(prev);
			next.has(key) ? next.delete(key) : next.add(key);
			return next;
		});

	const toggleAllForInst = (instKeys: string[]) =>
		setSelected(prev => {
			const next = new Set(prev);
			const allSel = instKeys.every(k => next.has(k));
			if (allSel) instKeys.forEach(k => next.delete(k));
			else instKeys.forEach(k => next.add(k));
			return next;
		});

	const toggleExpand = (inst: string) =>
		setExpanded(prev => {
			const next = new Set(prev);
			next.has(inst) ? next.delete(inst) : next.add(inst);
			return next;
		});

	const shortAddr = (addr: string) => `${addr.slice(0, 6)}…${addr.slice(-4)}`;

	const removeSelf = () => {
		EditorData().set({
			pendingProposals: EditorData().get().pendingProposals.filter(p => p !== proposal),
		});
	};

	const handleApprove = async () => {
		if (selected.size === 0) return;
		setBusy(true);
		try {
			const approval = buildApprovedProposal(proposal, selected, instMap);
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

	// Reusable diff renderer used for each component's expanded row
	const renderDiffs = (diffs: ReturnType<typeof computeDiff>, isNew: boolean) =>
		diffs.length > 0 ? (
			<div className="ml-5 mt-1 flex flex-col gap-0.5">
				{diffs.map((d, j) => (
					<div key={j}>
						<span className="text-[9px] opacity-50 font-medium uppercase tracking-wide">{d.field}</span>
						{isNew ? (
							<div className="font-mono text-[10px] text-green-700 break-all pl-1">{truncate(d.newValue)}</div>
						) : (
							<div className="font-mono text-[10px] flex flex-col pl-1">
								<span className="text-red-500 break-all">− {truncate(d.oldValue)}</span>
								<span className="text-green-700 break-all">+ {truncate(d.newValue)}</span>
							</div>
						)}
					</div>
				))}
			</div>
		) : null;

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
				{allInsts.map(inst => {
					const data = instMap.get(inst)!;
					const displayName = data.entity?.name
						?? EditorData().getEntity(inst)?.Entity?.name
						?? shortAddr(inst);
					const isExpanded = expanded.has(inst);
					const hasDetails = data.components.length > 0 || data.deletedComponents.length > 0;

					const instKeys = getInstSelectableKeys(inst, data, proposal);
					const allInstSel = instKeys.length > 0 && instKeys.every(k => selected.has(k));
					const someInstSel = instKeys.some(k => selected.has(k));

					return (
						<div key={inst} className="rounded border border-blue-200 bg-white/60">
							{/* Entity header — checkbox selects/deselects all components for this entity */}
							<div className="flex items-start gap-2 px-2 py-1.5">
								<input
									type="checkbox"
									className="mt-0.5 shrink-0"
									checked={allInstSel}
									ref={el => { if (el) el.indeterminate = someInstSel && !allInstSel; }}
									onChange={() => toggleAllForInst(instKeys)}
								/>
								<div className="flex flex-col min-w-0 flex-1 gap-1">
									<div className="flex items-center gap-1.5 min-w-0">
										{data.isNew && (
											<span className="shrink-0 rounded px-1 py-px text-[9px] font-bold uppercase bg-green-100 text-green-700 border border-green-300">
												NEW
											</span>
										)}
										<span className="font-medium truncate">{displayName}</span>
									</div>
									<div className="flex flex-wrap gap-1">
										{data.components.filter(c => c !== "Entity" && c !== "ChildToParent" && c !== "ParentToChildren").map(c => (
											<span key={c} className={`rounded px-1 py-px text-[9px] font-medium ${COMPONENT_BADGE_COLORS[c] ?? "bg-gray-100 text-gray-600"}`}>{c}</span>
										))}
										{(data.components.includes("ChildToParent") || data.components.includes("ParentToChildren")) && (
											<span className="rounded px-1 py-px text-[9px] font-medium bg-gray-100 text-gray-500">relationship</span>
										)}
										{data.deletedComponents.map(c => (
											<span key={`del-${c}`} className="rounded px-1 py-px text-[9px] font-medium bg-red-100 text-red-600 line-through">{c}</span>
										))}
									</div>
								</div>
								{hasDetails && (
									<button
										type="button"
										className="shrink-0 opacity-40 hover:opacity-70 text-xs mt-0.5"
										onClick={() => toggleExpand(inst)}
									>
										{isExpanded ? "▾" : "▸"}
									</button>
								)}
							</div>

							{/* Expanded: per-component rows with individual approval checkboxes */}
							{isExpanded && (() => {
								const syncEntity = EditorData().getEntity(inst, true) as AnyObject | undefined;
								return (
									<div className="border-t border-blue-100 px-2 py-1.5 flex flex-col gap-1">
										{/* Single-key write components */}
										{data.components.filter(c => SINGLE_WRITE_SET.has(c)).map(comp => {
											const itemKey = `w:${inst}:${comp}`;
											const isSel = selected.has(itemKey);
											const diffs = computeDiff({ [comp]: data.proposed[comp] } as AnyObject, syncEntity);
											return (
												<div key={comp} className={`rounded border px-2 py-1 ${isSel ? "border-blue-200 bg-blue-50/30" : "border-gray-200 bg-gray-50/30 opacity-50"}`}>
													<label className="flex items-center gap-2 cursor-pointer select-none">
														<input type="checkbox" checked={isSel} onChange={() => toggleItem(itemKey)} />
														<span className={`rounded px-1 py-px text-[10px] font-semibold ${COMPONENT_BADGE_COLORS[comp] ?? "bg-gray-100 text-gray-600"}`}>{comp}</span>
													</label>
													{renderDiffs(diffs, data.isNew)}
												</div>
											);
										})}
										{/* DescriptionText — one row per key */}
										{data.components.includes("DescriptionText") && Array.isArray(data.proposed.DescriptionText) &&
											(data.proposed.DescriptionText as { key: unknown }[]).map(dt => {
												const itemKey = `w:${inst}:DescriptionText:${dt.key}`;
												const isSel = selected.has(itemKey);
												const diffs = computeDiff({ DescriptionText: [dt] } as unknown as AnyObject, syncEntity);
												return (
													<div key={`dt-${dt.key}`} className={`rounded border px-2 py-1 ${isSel ? "border-yellow-200 bg-yellow-50/30" : "border-gray-200 bg-gray-50/30 opacity-50"}`}>
														<label className="flex items-center gap-2 cursor-pointer select-none">
															<input type="checkbox" checked={isSel} onChange={() => toggleItem(itemKey)} />
															<span className="rounded px-1 py-px text-[10px] font-semibold bg-yellow-100 text-yellow-800">
																DescriptionText · key {String(dt.key)}
															</span>
														</label>
														{renderDiffs(diffs, data.isNew)}
													</div>
												);
											})
										}
										{/* Multi-key write components — one row per (comp, key) pair */}
										{MULTI_WRITE_COMPS.flatMap(comp => {
											if (!data.components.includes(comp)) return [];
											const arr = data.proposed[comp] as { key: unknown }[] | undefined;
											if (!Array.isArray(arr)) return [];
											return arr.map(item => {
												const itemKey = `w:${inst}:${comp}:${item.key}`;
												const isSel = selected.has(itemKey);
												const diffs = computeDiff({ [comp]: [item] } as AnyObject, syncEntity);
												return (
													<div key={`${comp}-${item.key}`} className={`rounded border px-2 py-1 ${isSel ? "border-blue-200 bg-blue-50/30" : "border-gray-200 bg-gray-50/30 opacity-50"}`}>
														<label className="flex items-center gap-2 cursor-pointer select-none">
															<input type="checkbox" checked={isSel} onChange={() => toggleItem(itemKey)} />
															<span className={`rounded px-1 py-px text-[10px] font-semibold ${COMPONENT_BADGE_COLORS[comp] ?? "bg-gray-100 text-gray-600"}`}>
																{comp} · key {String(item.key)}
															</span>
														</label>
														{renderDiffs(diffs, data.isNew)}
													</div>
												);
											});
										})}
										{/* Component deletion rows */}
										{data.deletedComponents.length > 0 && (
											<>
												{/* Single-key deletions */}
												{data.deletedComponents.filter(c => !["DescriptionText","Trigger","Condition","Effect","Action"].includes(c)).map(comp => {
													const itemKey = `d:${inst}:${comp}`;
													const isSel = selected.has(itemKey);
													return (
														<div key={`del-${comp}`} className={`rounded border px-2 py-1 ${isSel ? "border-red-200 bg-red-50/30" : "border-gray-200 bg-gray-50/30 opacity-50"}`}>
															<label className="flex items-center gap-2 cursor-pointer select-none">
																<input type="checkbox" checked={isSel} onChange={() => toggleItem(itemKey)} />
																<span className="text-[10px] text-red-600 line-through font-semibold">− {comp}</span>
															</label>
														</div>
													);
												})}
												{/* DescriptionText deletions — one row per key */}
												{data.deletedComponents.includes("DescriptionText") && (() => {
													const flat = proposal.deleted_description_text_keys as BigNumberish[];
													const rows: ReactElement[] = [];
													for (let i = 0; i + 1 < flat.length; i += 2) {
														if (String(flat[i]) !== inst) continue;
														const k = flat[i + 1];
														const itemKey = `d:${inst}:DescriptionText:${k}`;
														const isSel = selected.has(itemKey);
														rows.push(
															<div key={`del-dt-${k}`} className={`rounded border px-2 py-1 ${isSel ? "border-red-200 bg-red-50/30" : "border-gray-200 bg-gray-50/30 opacity-50"}`}>
																<label className="flex items-center gap-2 cursor-pointer select-none">
																	<input type="checkbox" checked={isSel} onChange={() => toggleItem(itemKey)} />
																	<span className="text-[10px] text-red-600 line-through font-semibold">− DescriptionText · key {String(k)}</span>
																</label>
															</div>
														);
													}
													return rows;
												})()}
												{/* Multi-key deletions — one row per (comp, key) pair */}
												{MULTI_WRITE_COMPS.flatMap(comp => {
													if (!data.deletedComponents.includes(comp)) return [];
													const flat = getDelPairsForComp(proposal, comp);
													const rows: ReactElement[] = [];
													for (let i = 0; i + 1 < flat.length; i += 2) {
														if (String(flat[i]) !== inst) continue;
														const k = flat[i + 1];
														const itemKey = `d:${inst}:${comp}:${k}`;
														const isSel = selected.has(itemKey);
														rows.push(
															<div key={`del-${comp}-${k}`} className={`rounded border px-2 py-1 ${isSel ? "border-red-200 bg-red-50/30" : "border-gray-200 bg-gray-50/30 opacity-50"}`}>
																<label className="flex items-center gap-2 cursor-pointer select-none">
																	<input type="checkbox" checked={isSel} onChange={() => toggleItem(itemKey)} />
																	<span className="text-[10px] text-red-600 line-through font-semibold">− {comp} · key {String(k)}</span>
																</label>
															</div>
														);
													}
													return rows;
												})}
											</>
										)}
									</div>
								);
							})()}
						</div>
					);
				})}

				{/* Entity-level deletions */}
				{proposal.deleted_entity_insts.length > 0 && (
					<div className="flex flex-col gap-1">
						<span className="text-[10px] uppercase tracking-wide opacity-50">Deletions</span>
						{proposal.deleted_entity_insts.map(inst => {
							const instStr = String(inst);
							const itemKey = `d:${instStr}:Entity`;
							const isSel = selected.has(itemKey);
							const name = EditorData().getEntity(instStr)?.Entity?.name ?? shortAddr(instStr);
							return (
								<label
									key={instStr}
									className={`flex items-start gap-2 cursor-pointer select-none rounded px-2 py-1 border ${isSel ? "bg-red-50 border-red-200" : "bg-gray-50 border-gray-200 opacity-50"}`}
								>
									<input
										type="checkbox"
										className="mt-0.5 shrink-0"
										checked={isSel}
										onChange={() => toggleItem(itemKey)}
									/>
									<span className={`truncate text-xs ${isSel ? "text-red-600 line-through" : "text-gray-500"}`}>{name}</span>
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
