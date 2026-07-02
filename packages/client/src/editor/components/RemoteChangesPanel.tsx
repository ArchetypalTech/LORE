import { useState } from "react";
import EditorData, { findInstValue, useEditorData } from "../data/editor.data";
import type { AnyObject } from "../lib/types";
import { Button } from "./ui/Button";
import { CollapsibleComponent } from "./CollapsibleComponent";
import { SystemCalls } from "@lib/systemCalls";
import type { CollabProposalEvent, ApprovedProposal } from "@/lib/dojo_bindings/typescript/models.gen";

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
// Proposal review helpers
// ---------------------------------------------------------------------------

/** Returns all unique entity insts referenced in a proposal. */
const proposalInsts = (p: CollabProposalEvent): string[] => {
	const insts = new Set<string>();
	for (const e of p.entities) insts.add(String(e.inst));
	for (const c of [
		...p.reactables, ...p.areas, ...p.exits, ...p.hubs, ...p.trails,
		...p.containers, ...p.inventory_items, ...p.parents, ...p.children,
		...p.description_texts, ...p.triggers, ...p.conditions, ...p.effects, ...p.actions,
	]) insts.add(String((c as any).inst));
	return Array.from(insts);
};

/** Component names present for an entity inst in a proposal. */
const componentSummary = (p: CollabProposalEvent, inst: string): string => {
	const present: string[] = [];
	if (p.entities.some((e) => String(e.inst) === inst)) present.push("Entity");
	if (p.areas.some((c) => String((c as any).inst) === inst)) present.push("Area");
	if (p.exits.some((c) => String((c as any).inst) === inst)) present.push("Exit");
	if (p.reactables.some((c) => String((c as any).inst) === inst)) present.push("Reactable");
	if (p.description_texts.some((c) => String((c as any).inst) === inst)) present.push("DescriptionText");
	if (p.containers.some((c) => String((c as any).inst) === inst)) present.push("Container");
	if (p.inventory_items.some((c) => String((c as any).inst) === inst)) present.push("InventoryItem");
	if (p.hubs.some((c) => String((c as any).inst) === inst)) present.push("Hub");
	if (p.trails.some((c) => String((c as any).inst) === inst)) present.push("Trail");
	if (p.triggers.some((c) => String((c as any).inst) === inst)) present.push("Trigger");
	if (p.conditions.some((c) => String((c as any).inst) === inst)) present.push("Condition");
	if (p.effects.some((c) => String((c as any).inst) === inst)) present.push("Effect");
	if (p.actions.some((c) => String((c as any).inst) === inst)) present.push("Action");
	if (p.parents.some((c) => String((c as any).inst) === inst)) present.push("ParentToChildren");
	if (p.children.some((c) => String((c as any).inst) === inst)) present.push("ChildToParent");
	return present.join(", ");
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
	const allInsts = proposalInsts(proposal);
	const [selected, setSelected] = useState<Set<string>>(new Set(allInsts));
	const [busy, setBusy] = useState(false);

	const toggle = (inst: string) =>
		setSelected((prev) => {
			const next = new Set(prev);
			next.has(inst) ? next.delete(inst) : next.add(inst);
			return next;
		});

	const shortAddr = (addr: string) =>
		`${addr.slice(0, 6)}…${addr.slice(-4)}`;

	const handleApprove = async () => {
		if (selected.size === 0) return;
		setBusy(true);
		try {
			const approval = buildApprovedProposal(proposal, selected);
			await SystemCalls.approveProposal(approval);
		} catch (e) {
			console.error("approveProposal failed:", e);
		} finally {
			setBusy(false);
		}
	};

	const handleReject = async () => {
		setBusy(true);
		try {
			await SystemCalls.rejectProposal(
				BigInt(proposal.trail_id),
				proposal.proposer,
			);
		} catch (e) {
			console.error("rejectProposal failed:", e);
		} finally {
			setBusy(false);
		}
	};

	return (
		<div className="flex flex-col gap-2 rounded border border-blue-300 bg-blue-50 p-2">
			<div className="flex items-center justify-between">
				<div className="flex flex-col gap-0.5">
					<span className="text-[10px] opacity-50 uppercase tracking-wide">Proposer</span>
					<span className="font-mono text-xs">{shortAddr(proposal.proposer)}</span>
				</div>
				<div className="flex gap-1">
					<Button
						size="sm"
						disabled={busy || selected.size === 0}
						onClick={handleApprove}
					>
						Approve ({selected.size})
					</Button>
					<Button
						size="sm"
						variant="destructive"
						disabled={busy}
						onClick={handleReject}
					>
						Reject
					</Button>
				</div>
			</div>

			{/* Entity list */}
			<div className="flex flex-col gap-1">
				{allInsts.map((inst) => {
					const name = EditorData().getEntity(inst)?.Entity?.name
						?? proposal.entities.find((e) => String(e.inst) === inst)?.name
						?? inst;
					const summary = componentSummary(proposal, inst);
					return (
						<label
							key={inst}
							className="flex items-start gap-2 cursor-pointer select-none rounded px-1 py-0.5 hover:bg-blue-100"
						>
							<input
								type="checkbox"
								className="mt-0.5 shrink-0"
								checked={selected.has(inst)}
								onChange={() => toggle(inst)}
							/>
							<div className="flex flex-col min-w-0">
								<span className="truncate font-medium">{String(name)}</span>
								<span className="truncate opacity-50">{summary}</span>
							</div>
						</label>
					);
				})}

				{proposal.deleted_entity_insts.length > 0 && (
					<div className="mt-1 flex flex-col gap-1">
						<span className="text-[10px] uppercase tracking-wide opacity-50">Deletions</span>
						{proposal.deleted_entity_insts.map((inst) => {
							const instStr = String(inst);
							const name = EditorData().getEntity(instStr)?.Entity?.name ?? instStr;
							return (
								<label
									key={instStr}
									className="flex items-start gap-2 cursor-pointer select-none rounded px-1 py-0.5 hover:bg-blue-100"
								>
									<input
										type="checkbox"
										className="mt-0.5 shrink-0"
										checked={selected.has(instStr)}
										onChange={() => toggle(instStr)}
									/>
									<span className="truncate text-red-600">{String(name)}</span>
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
	const { pendingProposals } = useEditorData();

	if (pendingProposals.length === 0) return null;

	return (
		<CollapsibleComponent title={`Pending proposals (${pendingProposals.length})`}>
			<div className="flex flex-col gap-2 text-xs">
				{pendingProposals.map((proposal, i) => (
					<ProposalCard key={`${String(proposal.trail_id)}-${proposal.proposer}-${i}`} proposal={proposal} />
				))}
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
