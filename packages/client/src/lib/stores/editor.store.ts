import { useEffect, useMemo } from "react";
import WalletStore, { useWalletStore } from "./wallet.store";
import { useMounted } from "@/lib/utils/useMounted";
import { getAccountRoles } from "@/editor/data/editor.data";
import { EntityCollection } from "@/editor/lib/types";
import { StoreBuilder } from "../utils/storebuilder";

const {
	get,
	set,
	useStore: useEditorStore,
	createFactory,
} = StoreBuilder({
	// editor permissions
	isAdmin: undefined as boolean | undefined,
	isEditor: undefined as boolean | undefined,
});

/**
 * Factory function that returns all terminal store state and methods.
 * Can be used to access the terminal store outside of React components.
 * @returns {Object} The terminal store state and methods
 */
const EditorStore = createFactory({
	setPermissions: (isAdmin: boolean, isEditor: boolean) => {
		set({
			isAdmin,
			isEditor: (isAdmin || isEditor),
		});
	},
	canEditEntity: (entityCollection: EntityCollection | undefined) => {
		if (get().isAdmin) return true;
		if (get().isEditor)  {
			const walletAddress = WalletStore().walletAddress;
			const creatorAddress = BigInt(entityCollection?.Entity?.creator_address ?? 0);
			return (creatorAddress === BigInt(walletAddress ?? 0));
		}
		return false;
	},
});


/**
 * Keeps the player editor permissions in sync.
 * use only once at a top-level component.
 */
export const useSyncEditorPermissions = () => {
	const { isAdmin, isEditor } = useEditorStore();
	const { walletAddress, isConnected } = useWalletStore();
	const mounted = useMounted();
	useEffect(() => {
		if (mounted && walletAddress && isConnected) {
			// get account permissions
			getAccountRoles(walletAddress as string).then((roles: string[]) => {
				console.log("useSyncEditorPermissions() wallet roles:", roles);
				EditorStore().setPermissions(roles.includes("ROLE_ADMIN") ?? false, roles.includes("ROLE_EDITOR") ?? false);
			});
		} else {
			EditorStore().setPermissions(false, false);
		}
	}, [mounted, walletAddress, isConnected, isAdmin, isEditor]);
	return { isAdmin, isEditor };
};

/**
 * Returns the current player editor permissions.
 */
export const useEditorPermissions = () => {
	const { isAdmin, isEditor } = useEditorStore();
	return { isAdmin, isEditor };
};

/**
 * Returns the current player editor permissions to edit an entity.
 */
export const useCanEditEntity = (entityCollection: EntityCollection | undefined) => {
	const canEdit = useMemo(() => (
		EditorStore().canEditEntity(entityCollection)
	), [entityCollection])
	return { canEdit };
};

export default EditorStore;
export { useEditorStore };
