import { DojoProvider, DojoCall } from "@dojoengine/core";
import { Account, AccountInterface, BigNumberish, CairoOption, CairoCustomEnum } from "starknet";
import * as models from "./models.gen";

export function setupWorld(provider: DojoProvider) {

	const build_permit_token_approve_calldata = (to: string, tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "approve",
			calldata: [to, tokenId],
		};
	};

	const permit_token_approve = async (snAccount: Account | AccountInterface, to: string, tokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_approve_calldata(to, tokenId),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_availableSupply_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "availableSupply",
			calldata: [],
		};
	};

	const permit_token_availableSupply = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_availableSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_balanceOf_calldata = (account: string): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "balanceOf",
			calldata: [account],
		};
	};

	const permit_token_balanceOf = async (account: string) => {
		try {
			return await provider.call("lore_sn", build_permit_token_balanceOf_calldata(account));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_consumeMessage_calldata = (payload: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "consume_message",
			calldata: [payload],
		};
	};

	const permit_token_consumeMessage = async (snAccount: Account | AccountInterface, payload: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_consumeMessage_calldata(payload),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_contractUri_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "contractURI",
			calldata: [],
		};
	};

	const permit_token_contractUri = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_contractUri_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_defaultRoyalty_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "defaultRoyalty",
			calldata: [],
		};
	};

	const permit_token_defaultRoyalty = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_defaultRoyalty_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_getApproved_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "getApproved",
			calldata: [tokenId],
		};
	};

	const permit_token_getApproved = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore_sn", build_permit_token_getApproved_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_isApprovedForAll_calldata = (owner: string, operator: string): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "isApprovedForAll",
			calldata: [owner, operator],
		};
	};

	const permit_token_isApprovedForAll = async (owner: string, operator: string) => {
		try {
			return await provider.call("lore_sn", build_permit_token_isApprovedForAll_calldata(owner, operator));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_isMintedOut_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "is_minted_out",
			calldata: [],
		};
	};

	const permit_token_isMintedOut = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_isMintedOut_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_isMintingPaused_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "is_minting_paused",
			calldata: [],
		};
	};

	const permit_token_isMintingPaused = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_isMintingPaused_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_isOwnerOf_calldata = (address: string, tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "is_owner_of",
			calldata: [address, tokenId],
		};
	};

	const permit_token_isOwnerOf = async (address: string, tokenId: BigNumberish) => {
		try {
			return await provider.call("lore_sn", build_permit_token_isOwnerOf_calldata(address, tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_lastTokenId_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "last_token_id",
			calldata: [],
		};
	};

	const permit_token_lastTokenId = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_lastTokenId_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_maxSupply_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "maxSupply",
			calldata: [],
		};
	};

	const permit_token_maxSupply = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_maxSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_mintedSupply_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "mintedSupply",
			calldata: [],
		};
	};

	const permit_token_mintedSupply = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_mintedSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_name_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "name",
			calldata: [],
		};
	};

	const permit_token_name = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_name_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_ownerOf_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "ownerOf",
			calldata: [tokenId],
		};
	};

	const permit_token_ownerOf = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore_sn", build_permit_token_ownerOf_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_purchasedStarterPack_calldata = (recipient: string): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "purchased_starter_pack",
			calldata: [recipient],
		};
	};

	const permit_token_purchasedStarterPack = async (snAccount: Account | AccountInterface, recipient: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_purchasedStarterPack_calldata(recipient),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_reservedSupply_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "reservedSupply",
			calldata: [],
		};
	};

	const permit_token_reservedSupply = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_reservedSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_royaltyInfo_calldata = (tokenId: BigNumberish, salePrice: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "royaltyInfo",
			calldata: [tokenId, salePrice],
		};
	};

	const permit_token_royaltyInfo = async (tokenId: BigNumberish, salePrice: BigNumberish) => {
		try {
			return await provider.call("lore_sn", build_permit_token_royaltyInfo_calldata(tokenId, salePrice));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_safeTransferFrom_calldata = (from: string, to: string, tokenId: BigNumberish, data: Array<BigNumberish>): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "safeTransferFrom",
			calldata: [from, to, tokenId, data],
		};
	};

	const permit_token_safeTransferFrom = async (snAccount: Account | AccountInterface, from: string, to: string, tokenId: BigNumberish, data: Array<BigNumberish>) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_safeTransferFrom_calldata(from, to, tokenId, data),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_setApprovalForAll_calldata = (operator: string, approved: boolean): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "setApprovalForAll",
			calldata: [operator, approved],
		};
	};

	const permit_token_setApprovalForAll = async (snAccount: Account | AccountInterface, operator: string, approved: boolean) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_setApprovalForAll_calldata(operator, approved),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_setAppchainContract_calldata = (appchainContract: string): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "set_appchain_contract",
			calldata: [appchainContract],
		};
	};

	const permit_token_setAppchainContract = async (snAccount: Account | AccountInterface, appchainContract: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_setAppchainContract_calldata(appchainContract),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_setCartridgeContract_calldata = (cartridgeContract: string): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "set_cartridge_contract",
			calldata: [cartridgeContract],
		};
	};

	const permit_token_setCartridgeContract = async (snAccount: Account | AccountInterface, cartridgeContract: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_setCartridgeContract_calldata(cartridgeContract),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_setMessagingContract_calldata = (messagingContract: string): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "set_messaging_contract",
			calldata: [messagingContract],
		};
	};

	const permit_token_setMessagingContract = async (snAccount: Account | AccountInterface, messagingContract: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_setMessagingContract_calldata(messagingContract),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_setPermitType_calldata = (permitType: BigNumberish, actionsCount: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "set_permit_type",
			calldata: [permitType, actionsCount],
		};
	};

	const permit_token_setPermitType = async (snAccount: Account | AccountInterface, permitType: BigNumberish, actionsCount: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_setPermitType_calldata(permitType, actionsCount),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_supportsInterface_calldata = (interfaceId: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "supports_interface",
			calldata: [interfaceId],
		};
	};

	const permit_token_supportsInterface = async (interfaceId: BigNumberish) => {
		try {
			return await provider.call("lore_sn", build_permit_token_supportsInterface_calldata(interfaceId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_symbol_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "symbol",
			calldata: [],
		};
	};

	const permit_token_symbol = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_symbol_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_tokenRoyalty_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "tokenRoyalty",
			calldata: [tokenId],
		};
	};

	const permit_token_tokenRoyalty = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore_sn", build_permit_token_tokenRoyalty_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_tokenUri_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "tokenURI",
			calldata: [tokenId],
		};
	};

	const permit_token_tokenUri = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore_sn", build_permit_token_tokenUri_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_tokenExists_calldata = (tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "token_exists",
			calldata: [tokenId],
		};
	};

	const permit_token_tokenExists = async (tokenId: BigNumberish) => {
		try {
			return await provider.call("lore_sn", build_permit_token_tokenExists_calldata(tokenId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_totalSupply_calldata = (): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "totalSupply",
			calldata: [],
		};
	};

	const permit_token_totalSupply = async () => {
		try {
			return await provider.call("lore_sn", build_permit_token_totalSupply_calldata());
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_permit_token_transferFrom_calldata = (from: string, to: string, tokenId: BigNumberish): DojoCall => {
		return {
			contractName: "permit_token",
			entrypoint: "transferFrom",
			calldata: [from, to, tokenId],
		};
	};

	const permit_token_transferFrom = async (snAccount: Account | AccountInterface, from: string, to: string, tokenId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_permit_token_transferFrom_calldata(from, to, tokenId),
				"lore_sn",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};



	return {
		permit_token: {
			approve: permit_token_approve,
			buildApproveCalldata: build_permit_token_approve_calldata,
			availableSupply: permit_token_availableSupply,
			buildAvailableSupplyCalldata: build_permit_token_availableSupply_calldata,
			balanceOf: permit_token_balanceOf,
			buildBalanceOfCalldata: build_permit_token_balanceOf_calldata,
			consumeMessage: permit_token_consumeMessage,
			buildConsumeMessageCalldata: build_permit_token_consumeMessage_calldata,
			contractUri: permit_token_contractUri,
			buildContractUriCalldata: build_permit_token_contractUri_calldata,
			defaultRoyalty: permit_token_defaultRoyalty,
			buildDefaultRoyaltyCalldata: build_permit_token_defaultRoyalty_calldata,
			getApproved: permit_token_getApproved,
			buildGetApprovedCalldata: build_permit_token_getApproved_calldata,
			isApprovedForAll: permit_token_isApprovedForAll,
			buildIsApprovedForAllCalldata: build_permit_token_isApprovedForAll_calldata,
			isMintedOut: permit_token_isMintedOut,
			buildIsMintedOutCalldata: build_permit_token_isMintedOut_calldata,
			isMintingPaused: permit_token_isMintingPaused,
			buildIsMintingPausedCalldata: build_permit_token_isMintingPaused_calldata,
			isOwnerOf: permit_token_isOwnerOf,
			buildIsOwnerOfCalldata: build_permit_token_isOwnerOf_calldata,
			lastTokenId: permit_token_lastTokenId,
			buildLastTokenIdCalldata: build_permit_token_lastTokenId_calldata,
			maxSupply: permit_token_maxSupply,
			buildMaxSupplyCalldata: build_permit_token_maxSupply_calldata,
			mintedSupply: permit_token_mintedSupply,
			buildMintedSupplyCalldata: build_permit_token_mintedSupply_calldata,
			name: permit_token_name,
			buildNameCalldata: build_permit_token_name_calldata,
			ownerOf: permit_token_ownerOf,
			buildOwnerOfCalldata: build_permit_token_ownerOf_calldata,
			purchasedStarterPack: permit_token_purchasedStarterPack,
			buildPurchasedStarterPackCalldata: build_permit_token_purchasedStarterPack_calldata,
			reservedSupply: permit_token_reservedSupply,
			buildReservedSupplyCalldata: build_permit_token_reservedSupply_calldata,
			royaltyInfo: permit_token_royaltyInfo,
			buildRoyaltyInfoCalldata: build_permit_token_royaltyInfo_calldata,
			safeTransferFrom: permit_token_safeTransferFrom,
			buildSafeTransferFromCalldata: build_permit_token_safeTransferFrom_calldata,
			setApprovalForAll: permit_token_setApprovalForAll,
			buildSetApprovalForAllCalldata: build_permit_token_setApprovalForAll_calldata,
			setAppchainContract: permit_token_setAppchainContract,
			buildSetAppchainContractCalldata: build_permit_token_setAppchainContract_calldata,
			setCartridgeContract: permit_token_setCartridgeContract,
			buildSetCartridgeContractCalldata: build_permit_token_setCartridgeContract_calldata,
			setMessagingContract: permit_token_setMessagingContract,
			buildSetMessagingContractCalldata: build_permit_token_setMessagingContract_calldata,
			setPermitType: permit_token_setPermitType,
			buildSetPermitTypeCalldata: build_permit_token_setPermitType_calldata,
			supportsInterface: permit_token_supportsInterface,
			buildSupportsInterfaceCalldata: build_permit_token_supportsInterface_calldata,
			symbol: permit_token_symbol,
			buildSymbolCalldata: build_permit_token_symbol_calldata,
			tokenRoyalty: permit_token_tokenRoyalty,
			buildTokenRoyaltyCalldata: build_permit_token_tokenRoyalty_calldata,
			tokenUri: permit_token_tokenUri,
			buildTokenUriCalldata: build_permit_token_tokenUri_calldata,
			tokenExists: permit_token_tokenExists,
			buildTokenExistsCalldata: build_permit_token_tokenExists_calldata,
			totalSupply: permit_token_totalSupply,
			buildTotalSupplyCalldata: build_permit_token_totalSupply_calldata,
			transferFrom: permit_token_transferFrom,
			buildTransferFromCalldata: build_permit_token_transferFrom_calldata,
		},
	};
}