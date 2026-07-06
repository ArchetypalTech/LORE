import { useMemo, useState, useEffect, useRef } from "react";
import EditorData, { useEditorData } from "../data/editor.data";
import type { ChangeSet } from "../lib/types";
import { publishConfigToContract, submitForReview, publishApproved } from "../publisher";
import { Button } from "./ui/Button";
import { CollapsibleComponent } from "./CollapsibleComponent";
import { useWalletStore } from "@/lib/stores/wallet.store";
import { useTokenStore } from "@/lib/stores/token.store";
import EditorStore from "@/lib/stores/editor.store";
import type { ApprovedProposal } from "@/lib/dojo_bindings/typescript/models.gen";
import { toast } from "sonner";

const entityLabel = (c: ChangeSet) =>
	EditorData().getEntity(c.inst)?.Entity?.name ?? String(c.inst);

const componentNames = (c: ChangeSet) => Object.keys(c.object).join(", ");

const shortAddr = (addr: string) => `${addr.slice(0, 6)}…${addr.slice(-4)}`;

// ---------------------------------------------------------------------------
// RejectedBannerSection — shown when the trail owner rejects the proposal
// ---------------------------------------------------------------------------

const RejectedBannerSection = ({ onDismiss }: { onDismiss: () => void }) => (
	<section className="flex items-center justify-between gap-2 rounded border border-red-300 bg-red-50 px-3 py-2">
		<div className="flex flex-col gap-0.5 min-w-0">
			<span className="font-semibold text-red-700 text-xs">Proposal rejected by trail owner</span>
			<span className="text-[10px] text-red-600 opacity-80">
				Your staged changes are preserved — edit and resubmit.
			</span>
		</div>
		<Button size="sm" variant="destructive" onClick={onDismiss}>
			Dismiss
		</Button>
	</section>
);

// ---------------------------------------------------------------------------
// PublishApprovedSection — shown when the current user has approvals waiting
// ---------------------------------------------------------------------------

const PublishApprovedSection = ({
	approvals,
	busy,
	onPublish,
}: {
	approvals: ApprovedProposal[];
	busy: boolean;
	onPublish: (approval: ApprovedProposal) => void;
}) => {
	if (approvals.length === 0) return null;

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
						onClick={() => onPublish(approval)}
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
	const { ownedTrailIds } = useTokenStore();
	const isAdmin = EditorStore().isAdmin ?? false;
	const [reviewBusy, setReviewBusy] = useState(false);
	const [publishBusy, setPublishBusy] = useState(false);
	const [showRejectedBanner, setShowRejectedBanner] = useState(false);

	// Trail owners and admins may publish directly. When a trail is active, collaborators
	// (non-owners) must submit for review instead.
	const canPublishDirectly =
		isAdmin || activeTrailId === undefined || ownedTrailIds.includes(activeTrailId);

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

	// Detect when the trail owner acts on the collaborator's proposal.
	// justPublishedRef guards against a false positive: if WE cleared the approval (by publishing),
	// that drop must not trigger the rejection banner.
	const prevMyApprovalsRef = useRef<ApprovedProposal[]>([]);
	const justPublishedRef = useRef(false);
	useEffect(() => {
		const prev = prevMyApprovalsRef.current;
		prevMyApprovalsRef.current = myApprovals;
		const hadApproval = prev.length > 0;
		const hasApproval = myApprovals.length > 0;

		// Rejection: approval dropped while staged changes remain.
		if (hadApproval && !hasApproval && staged.length > 0) {
			if (justPublishedRef.current) {
				justPublishedRef.current = false;
				return;
			}
			setShowRejectedBanner(true);
		}
	}, [myApprovals]);

	// Auto-dismiss the rejected banner once the collaborator clears their staged changes.
	useEffect(() => {
		if (staged.length === 0) setShowRejectedBanner(false);
	}, [staged.length]);

	const handlePublish = async (approval: ApprovedProposal) => {
		if (!activeTrailId) return;
		setPublishBusy(true);
		justPublishedRef.current = true;
		try {
			await publishApproved(activeTrailId, approval);
			// After publishing, check if any staged items for this trail remain.
			// If so, they were not included in the approval — tell the collaborator.
			const remaining = EditorData().get().stagedChanges.filter((c) => {
				const entity = EditorData().getEntity(c.inst);
				return BigInt(entity?.Entity?.trail_id?.toString() ?? "0") === activeTrailId;
			});
			if (remaining.length > 0) {
				toast.info(
					`${remaining.length} staged item${remaining.length !== 1 ? "s" : ""} were not included in the approval — resubmit for review.`,
					{ duration: 8000, dismissible: true },
				);
			}
		} catch (e) {
			justPublishedRef.current = false;
			console.error("publishApproved failed:", e);
		} finally {
			setPublishBusy(false);
		}
	};

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
							disabled={staged.length === 0 || !canPublishDirectly}
							onClick={() => publishConfigToContract()}
							variant="hero"
							title={!canPublishDirectly ? "Only trail owners can publish directly — use Submit for review" : undefined}
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

				{showRejectedBanner && staged.length > 0 && (
					<RejectedBannerSection onDismiss={() => setShowRejectedBanner(false)} />
				)}

				{myApprovals.length > 0 && activeTrailId !== undefined && (
					<PublishApprovedSection
						approvals={myApprovals}
						busy={publishBusy}
						onPublish={handlePublish}
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
