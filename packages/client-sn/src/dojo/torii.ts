import { ToriiClient } from "@dojoengine/torii-client";
import { PROFILE } from "@/dojo/dojoConfig";

let clientPromiseStarknet: Promise<ToriiClient> | undefined;
let clientPromiseAppchain: Promise<ToriiClient> | undefined;

export const getToriiClientStarknet = async (): Promise<ToriiClient> => {
	if (!clientPromiseStarknet) {
		clientPromiseStarknet = Promise.resolve(
			new ToriiClient({
				toriiUrl: PROFILE.toriiUrl.starknet,
				worldAddress: PROFILE.contractAddresses.starknet.world,
			}) as unknown as Promise<ToriiClient>
		);
	}
	return clientPromiseStarknet;
}

export const getToriiClientAppchain = async (): Promise<ToriiClient> => {
	if (!clientPromiseAppchain) {
		clientPromiseAppchain = Promise.resolve(
			new ToriiClient({
				toriiUrl: PROFILE.toriiUrl.appchain,
				worldAddress: PROFILE.contractAddresses.appchain.world,
			}) as unknown as Promise<ToriiClient>
		);
	}
	return clientPromiseAppchain;
}
