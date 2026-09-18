import { useMemo, useState, useEffect } from "react";
import EditorData, { useEditorData } from "../data/editor.data";
import type { ChangeSet } from "../lib/types";
import { publishConfigToContract, submitForReview } from "../publisher";
import { Button } from "./ui/Button";
import { CollapsibleComponent } from "./CollapsibleComponent";
import { useWalletStore } from "@/lib/stores/wallet.store";
import { useTokenStore } from "@/lib/stores/token.store";
import EditorStore from "@/lib/stores/editor.store";
import { toast } from "sonner";

const entityLabel = (c: ChangeSet) =>
	EditorData().getEntity(c.inst)?.Entity?.name ?? String(c.inst);

/** Component name(s) for a change, including key value for multi-keyed types. */
const componentLabel = (c: ChangeSet) =>
	Object.entries(c.object)
		.map(([name, value]) => {
			if (Array.isArray(value) && value.length > 0) {
				const keys = (value as { key?: unknown }[])
					.map(item => item.key)
					.filter(k => k !== undefined);
				if (keys.length > 0) return `${name} (key ${keys.join(", ")})`;
			}
			return name;
		})
		.join(", ");

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
	const { changeSet, stagedChanges, activeTrailId, reviewResult } = useEditorData();
	const { walletAddress } = useWalletStore();
	const { ownedTrailIds } = useTokenStore();
	const isAdmin = EditorStore().isAdmin ?? false;
	const [reviewBusy, setReviewBusy] = useState(false);
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

	// Show notification when the trail owner signals review result for this collaborator.
	useEffect(() => {
		if (!reviewResult || !walletAddress || !activeTrailId) return;
		if (BigInt(reviewResult.trail_id) !== activeTrailId) return;
		const norm = (a: string) => a.replace(/^0x0+/, "0x").toLowerCase();
		if (norm(reviewResult.proposer) !== norm(walletAddress)) return;
		if (reviewResult.skipped_count === 0 && reviewResult.published_count > 0) {
			toast.success("All your changes have been published.");
		} else if (reviewResult.published_count > 0) {
			toast.info(
				`Your changes were published, but ${reviewResult.skipped_count} item(s) were not included.`,
				{ duration: 12000, dismissible: true },
			);
		} else {
			setShowRejectedBanner(true);
		}
	}, [reviewResult]);

	// Auto-dismiss the rejected banner once the collaborator clears their staged changes.
	useEffect(() => {
		if (staged.length === 0) setShowRejectedBanner(false);
	}, [staged.length]);

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
					{unstaged.map((c) => (
						<div key={`${String(c.inst)}-${c.type}-${componentLabel(c)}`} className="flex items-center justify-between gap-2 rounded border border-gray-200 px-2 py-1">
							<span className="truncate">{entityLabel(c)}</span>
							<span className="rounded bg-gray-200 px-1 text-[10px] uppercase">{c.type}</span>
							<span className="truncate opacity-50">{componentLabel(c)}</span>
							<div className="flex gap-1">
								<Button size="sm" onClick={() => EditorData().stageChange(c)}>
									Stage
								</Button>
								<Button size="sm" variant="destructive" onClick={() => EditorData().discardChange(c)}>
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
					{staged.map((c) => (
						<div key={`${String(c.inst)}-${c.type}-${componentLabel(c)}`} className="flex items-center justify-between gap-2 rounded border border-gray-200 px-2 py-1">
							<span className="truncate">{entityLabel(c)}</span>
							<span className="rounded bg-gray-200 px-1 text-[10px] uppercase">{c.type}</span>
							<span className="truncate opacity-50">{componentLabel(c)}</span>
							<div className="flex gap-1">
								<Button size="sm" onClick={() => EditorData().unstageChange(c)}>
									Unstage
								</Button>
								<Button size="sm" variant="destructive" onClick={() => EditorData().discardChange(c)}>
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
								disabled={staged.length === 0 || reviewBusy || canPublishDirectly}
								onClick={handleSubmitForReview}
								variant="secondary"
								title={canPublishDirectly ? "Owners publish directly — no review needed" : undefined}
							>
								Submit for review
							</Button>
						)}
					</div>
				</section>

				{showRejectedBanner && staged.length > 0 && (
					<RejectedBannerSection onDismiss={() => setShowRejectedBanner(false)} />
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
