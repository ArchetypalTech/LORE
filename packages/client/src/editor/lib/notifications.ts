import { StoreBuilder } from "@/lib/utils/storebuilder";
import { toast } from "sonner";
import { publishConfigToContract } from "../publisher";

// Define notification state types
export type NotificationType =
	| "error"
	| "success"
	| "loading"
	| "publishing"
	| "warning"
	| "info"
	| "none";

export interface NotificationState {
	type: NotificationType;
	message: string;
	blocking: boolean;
	logs: CustomEvent[];
	timeout?: number | null;
}

// Create default notification state
export const initialNotificationState: NotificationState = {
	type: "none",
	message: "",
	blocking: false,
	logs: [],
};

const {
	get: getNotification,
	set: setNotification,
	createFactory,
	useStore: useNotifications,
} = StoreBuilder<NotificationState>(initialNotificationState);

/**
 * Combined actions for the editor, organized by functionality
 */
// Notification related actions
const notifications = {
	doLoggedAction: async (action: () => Promise<void>) => {
		notifications.startPublishing();
		await action();
		notifications.finalizePublishing();
	},
	needsToPublish: () => {
		toast("Your changes are not yet published", {
			id: "editor-dirty",
			duration: Infinity,
			position: "bottom-center",
			action: {
				label: "Publish",
				onClick: () => publishConfigToContract(),
			},
		});
	},
	clear: () => {
		setNotification(initialNotificationState);
	},
	showError: (message: string) => {
		toast.error(message, { richColors: true, duration: 4000, dismissible: true });
	},
	showSuccess: (message: string) => {
		toast.success(message, { richColors: true });
	},
	startPublishing: async () => {
		toast.loading("Publishing to the world...", {
			richColors: true,
			position: "bottom-center",
			id: "publishing-world",
		});
		setNotification({
			logs: [],
		});
		const currentNotification = getNotification();
		return currentNotification.logs || [];
	},
	/**
	 * Add a log entry to a publishing notification
	 */
	addPublishingLog: (log: CustomEvent) => {
		const state = getNotification();
		if (log.type === "error") {
			notifications.showError(log.detail.error.message);
		}
		setNotification({
			...state,
			logs: [...state.logs, log],
		});
	},

	finalizePublishing: () => {
		const state = getNotification();
		toast.dismiss("publishing-world");
		if (state.logs.some((log) => log.type === "error")) {
			notifications.showError("Errors while publishing");
		} else {
			toast.info("World published");
		}
	},
};

// Export a composable store object with all functionality
export const Notifications = createFactory({
	...notifications,
});
export { useNotifications };
