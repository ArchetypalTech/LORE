import { StoreBuilder } from "@/lib/utils/storebuilder";
import { toast } from "sonner";

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
	logs?: CustomEvent[];
	timeout?: number | null;
}

// Create default notification state
export const initialNotificationState: NotificationState = {
	type: "none",
	message: "",
	blocking: false,
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
	clear: () => {
		setNotification(initialNotificationState);
	},
	showError: (message: string) => {
		toast.error(message, { richColors: true });
	},
	showSuccess: (message: string) => {
		toast.success(message, { richColors: true });
	},
	startPublishing: async (message = "Publishing to contract...") => {
		if (getNotification().type === "publishing") return;
		console.log("[Notification]: Starting Publishing");
		setNotification({
			type: "publishing",
			message,
			blocking: true,
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
		if (state.type !== "publishing" || state.logs === undefined) {
			console.warn("Cannot add log to non-publishing notification");
			return;
		}
		setNotification({
			...state,
			logs: [...state.logs, log],
		});
	},

	finalizePublishing: () => {
		const state = getNotification();
		notifications.clear();
		if (state.logs === undefined) {
			notifications.showError("No logs to show");
			console.error("No logs to show");
			return;
		}
		if (state.logs.some((log) => log.type === "error")) {
			notifications.showError("Errors while publishing");
		} else {
			notifications.showSuccess("Published to the world successfully");
		}
	},
};

// Export a composable store object with all functionality
export const Notifications = createFactory({
	...notifications,
});
export { useNotifications };
