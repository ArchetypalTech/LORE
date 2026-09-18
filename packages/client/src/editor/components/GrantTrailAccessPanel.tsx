import { useMemo, useState } from "react";
import { useEditorData } from "../data/editor.data";
import { useTokenStore } from "@/lib/stores/token.store";
import { SystemCalls } from "@/lib/systemCalls";
import { Button } from "./ui/Button";
import { CollapsibleComponent } from "./CollapsibleComponent";

export const GrantTrailAccessPanel = () => {
	const { dataPool } = useEditorData();
	const { ownedTrailIds } = useTokenStore();

	const [selectedTrailId, setSelectedTrailId] = useState<string>("");
	const [address, setAddress] = useState<string>("");
	const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
	const [errorMsg, setErrorMsg] = useState<string>("");

	const ownedTrails = useMemo(() => {
		const result: { trailId: bigint; label: string }[] = [];
		for (const value of dataPool.values()) {
			const entity = value as { Trail?: { trail_id: unknown }; Entity?: { name?: string } };
			if (!entity?.Trail) continue;
			const trailId = BigInt(entity.Trail.trail_id as never);
			if (!ownedTrailIds.includes(trailId)) continue;
			const key = trailId.toString();
			if (result.some((t) => t.trailId === trailId)) continue;
			result.push({ trailId, label: entity.Entity?.name || `Trail ${key}` });
		}
		return result.sort((a, b) => a.label.localeCompare(b.label));
	}, [dataPool, ownedTrailIds]);

	const execute = async (granting: boolean) => {
		const trailId = selectedTrailId ? BigInt(selectedTrailId) : undefined;
		const trimmedAddress = address.trim();
		if (!trailId || !trimmedAddress) return;

		setStatus("loading");
		setErrorMsg("");
		try {
			await SystemCalls.grantAccessToTrail(trailId, trimmedAddress, granting);
			setStatus("success");
		} catch (e) {
			setErrorMsg((e as Error).message);
			setStatus("error");
		}
	};

	if (ownedTrailIds.length === 0) return null;

	return (
		<CollapsibleComponent title="Invite Trail Collaborator">
			<div className="flex flex-col gap-3 text-xs">
				<p className="opacity-70">
					Grant or revoke a player's ability to create, edit, and delete content in one of your
					trails.
				</p>

				<div className="flex flex-col gap-1">
					<label className="font-semibold">Trail</label>
					<select
						className="rounded border border-gray-300 bg-white px-2 py-1"
						value={selectedTrailId}
						onChange={(e) => {
							setSelectedTrailId(e.target.value);
							setStatus("idle");
						}}
					>
						<option value="">Select a trail…</option>
						{ownedTrails.map((t) => (
							<option key={t.trailId.toString()} value={t.trailId.toString()}>
								{t.label}
							</option>
						))}
					</select>
				</div>

				<div className="flex flex-col gap-1">
					<label className="font-semibold">Player address</label>
					<input
						type="text"
						className="rounded border border-gray-300 bg-white px-2 py-1 font-mono"
						placeholder="0x..."
						value={address}
						onChange={(e) => {
							setAddress(e.target.value);
							setStatus("idle");
						}}
					/>
				</div>

				<div className="flex gap-2">
					<Button
						disabled={!selectedTrailId || !address.trim() || status === "loading"}
						onClick={() => execute(true)}
					>
						{status === "loading" ? "Sending…" : "Grant access"}
					</Button>
					<Button
						variant="ghost"
						disabled={!selectedTrailId || !address.trim() || status === "loading"}
						onClick={() => execute(false)}
					>
						Revoke access
					</Button>
				</div>

				{status === "success" && (
					<p className="rounded bg-green-50 border border-green-300 px-2 py-1 text-green-800">
						Done!
					</p>
				)}
				{status === "error" && (
					<p className="rounded bg-red-50 border border-red-300 px-2 py-1 text-red-800 break-all">
						{errorMsg || "Transaction failed"}
					</p>
				)}
			</div>
		</CollapsibleComponent>
	);
};
