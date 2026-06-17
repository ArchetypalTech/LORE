import { PROFILE } from "@/dojo/dojoConfig";
import type { ProfileName } from "@/dojo/config_profiles";

// Display label for each profile's network.
const NETWORK_LABELS: Record<ProfileName, string> = {
	dev: "dev",
	sepolia: "Sepolia",
	mainnet: "Mainnet",
};

export function NetworkBadge() {
	return <p className="m-0">{NETWORK_LABELS[PROFILE.profileName]}</p>;
}
