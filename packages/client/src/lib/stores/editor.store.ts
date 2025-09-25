import { useEffect, useMemo } from "react";
import { useWalletStore } from "./wallet.store";
import { useMounted } from "@/lib/utils/useMounted";
import { getAccountPermissions } from "@/editor/data/editor.data";
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
			getAccountPermissions(walletAddress as string).then((accountPermissions) => {
				console.log("useSyncEditorPermissions() walletAddress:", accountPermissions);
				EditorStore().setPermissions(accountPermissions?.is_admin ?? false, accountPermissions?.is_editor ?? false);
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
export const useCanEditEntity = (EntityCollection: EntityCollection | undefined) => {
	const { isAdmin, isEditor } = useEditorStore();
	const { walletAddress } = useWalletStore();
	const canEdit = useMemo(() => {
		if (isAdmin) return true;
		if (isEditor)  {
			const creatorAddress = BigInt(EntityCollection?.Entity?.creator_address ?? 0);
			return (creatorAddress === BigInt(walletAddress ?? 0));
		}
		return false;
	}, [EntityCollection, isAdmin, isEditor, walletAddress])
	return { isAdmin, isEditor, canEdit };
};

export default EditorStore;
export { useEditorStore };
