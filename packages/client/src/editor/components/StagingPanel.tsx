import { useMemo, useState, useEffect, useRef } from "react";
import EditorData, { useEditorData } from "../data/editor.data";
import type { ChangeSet } from "../lib/types";
import { publishConfigToContract, submitForReview, publishApproved } from "../publisher";
import { Button } from "./ui/Button";
import { CollapsibleComponent } from "./CollapsibleComponent";
import { useWalletStore } from "@/lib/stores/wallet.store";
import type { ApprovedProposal } from "@/lib/dojo_bindings/typescript/models.gen";
import { toast } from "sonner";

const entityLabel = (c: ChangeSet) =>
	EditorData().getEntity(c.inst)?.Entity?.name ?? String(c.inst);

const componentNames = (c: ChangeSet) => Object.keys(c.object).join(", ");

const shortAddr = (addr: string) => `${addr.slice(0, 6)}…${addr.slice(-4)}`;

// ---------------------------------------------------------------------------
// PublishApprovedSection — shown when the current user has approvals waiting
// ---------------------------------------------------------------------------

const PublishApprovedSection = ({
	approvals,
	activeTrailId,
}: {
	approvals: ApprovedProposal[];
	activeTrailId: bigint;
}) => {
	const [busy, setBusy] = useState(false);

	if (approvals.length === 0) return null;

	const handlePublish = async (approval: ApprovedProposal) => {
		setBusy(true);
		try {
			await publishApproved(activeTrailId, approval);
		} catch (e) {
			console.error("publishApproved failed:", e);
		} finally {
			setBusy(false);
		}
	};

	return (
		<section className="flex flex-col gap-1">
			<h4 className="font-semibold text-green-700">Approved by trail owner</h4>
			{approvals.map((approval, i) => (
				<div
					key={i}
					className="flex items-center justify-between gap-2 rounded border border-green-300 bg-green-50 px-2 py-1"
				>
					<div className="flex flex-col min-w-0">
						<span className="font-mono text-[10px] truncate opacity-60">
							{shortAddr(approval.proposer)}
						</span>
						<span className="text-[10px] opacity-50">
							{(approval.w_single_keys as any[]).length} writes,{" "}
							{(approval.d_single_keys as any[]).length} deletions
						</span>
					</div>
					<Button
						size="sm"
						disabled={busy}
						onClick={() => handlePublish(approval)}
					>
						Publish approved
					</Button>
				</div>
			))}
		</section>
	);
};

// ---------------------------------------------------------------------------
// StagingPanel
// ---------------------------------------------------------------------------

/**
 * Option D staging panel — shows changeSet/stagedChanges filtered to the active
 * collaboration trail (or everything, when no trail is selected). Publishing only
 * sends what's in stagedChanges, leaving the rest of the changeSet untouched.
 *
 * When a trail is active, "Submit for review" lets collaborators send staged changes
 * to the trail owner without needing direct write access. If the owner has approved
 * a prior submission, "Publish approved" publishes those approved changes.
 */
export const StagingPanel = () => {
	const { changeSet, stagedChanges, activeTrailId, currentApprovals } = useEditorData();
	const { walletAddress } = useWalletStore();
	const [reviewBusy, setReviewBusy] = useState(false);

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

	// Approvals for the current user on the active trail
	const norm = (addr: string) => addr.replace(/^0x0+/, "0x").toLowerCase();
	const myApprovals = useMemo(() => {
		if (!activeTrailId || !walletAddress) return [];
		const myAddr = norm(walletAddress);
		return currentApprovals.filter(
			(a) =>
				BigInt(a.trail_id) === activeTrailId &&
				norm(a.proposer) === myAddr
		);
	}, [currentApprovals, activeTrailId, walletAddress]);

	// Notify the collaborator when the trail owner rejects their proposal.
	// We detect rejection when our approval disappears while we still have staged changes.
	const prevMyApprovalsRef = useRef<ApprovedProposal[]>([]);
	useEffect(() => {
		const prev = prevMyApprovalsRef.current;
		prevMyApprovalsRef.current = myApprovals;
		if (prev.length > 0 && myApprovals.length === 0 && staged.length > 0) {
			toast.warning(
				"Your proposal was rejected. Your staged changes are preserved — edit and resubmit.",
				{ duration: 6000, dismissible: true },
			);
		}
	}, [myApprovals]);

	const handleSubmitForReview = async () => {
		if (!activeTrailId) return;
		setReviewBusy(true);
		try {
			await submitForReview(activeTrailId);
		} catch (e) {
			console.error("submitForReview failed:", e);
		} finally {
			setReviewBusy(false);
		}
	};

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

					<div className="flex gap-1 mt-1">
						<Button
							disabled={staged.length === 0}
							onClick={() => publishConfigToContract()}
							variant="hero"
						>
							Publish staged ({staged.length})
						</Button>
						{activeTrailId !== undefined && (
							<Button
								disabled={staged.length === 0 || reviewBusy}
								onClick={handleSubmitForReview}
								variant="secondary"
							>
								Submit for review
							</Button>
						)}
					</div>
				</section>

				{myApprovals.length > 0 && activeTrailId !== undefined && (
					<PublishApprovedSection
						approvals={myApprovals}
						activeTrailId={activeTrailId}
					/>
				)}

				{allCount > 0 && (
					<Button variant="destructive" onClick={() => EditorData().discardChanges()}>
						Discard all changes ({allCount})
					</Button>
				)}
			</div>
		</CollapsibleComponent>
	);
};
