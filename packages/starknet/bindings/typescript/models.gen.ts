import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { BigNumberish } from 'starknet';

// Type definition for `lore_sn::models::permit_config::PermitConfig` struct
export interface PermitConfig {
	key: BigNumberish;
	messaging_contract: string;
	appchain_contract: string;
	cartridge_contract: string;
}

// Type definition for `lore_sn::models::permit_token_info::PermitTokenInfo` struct
export interface PermitTokenInfo {
	permit_id: BigNumberish;
	permit_type: BigNumberish;
	is_used: boolean;
	trail_name: string;
}

// Type definition for `lore_sn::models::permit_token_info::PermitType` struct
export interface PermitType {
	permit_type: BigNumberish;
	actions_count: BigNumberish;
}

// Type definition for `lore_sn::models::appchain::AppchainMessageEvent` struct
export interface AppchainMessageEvent {
	uuid: BigNumberish;
	caller_address: string;
	from_address: string;
	to_address: string;
	block_number: BigNumberish;
	block_timestamp: BigNumberish;
	message_hash: BigNumberish;
	message_type: BigNumberish;
	payload: Array<BigNumberish>;
}

// Type definition for `nft_combo::erc721::erc721_combo::ERC721ComboComponent::BatchMetadataUpdate` struct
export interface BatchMetadataUpdate {
	from_token_id: BigNumberish;
	to_token_id: BigNumberish;
}

// Type definition for `nft_combo::erc721::erc721_combo::ERC721ComboComponent::MetadataUpdate` struct
export interface MetadataUpdate {
	token_id: BigNumberish;
}

// Type definition for `openzeppelin_token::erc721::erc721::ERC721Component::Approval` struct
export interface Approval {
	owner: string;
	approved: string;
	token_id: BigNumberish;
}

// Type definition for `openzeppelin_token::erc721::erc721::ERC721Component::ApprovalForAll` struct
export interface ApprovalForAll {
	owner: string;
	operator: string;
	approved: boolean;
}

// Type definition for `openzeppelin_token::erc721::erc721::ERC721Component::Transfer` struct
export interface Transfer {
	from: string;
	to: string;
	token_id: BigNumberish;
}

export interface SchemaType extends ISchemaType {
	lore_sn: {
		PermitConfig: PermitConfig,
		PermitTokenInfo: PermitTokenInfo,
		PermitType: PermitType,
		AppchainMessageEvent: AppchainMessageEvent,
		BatchMetadataUpdate: BatchMetadataUpdate,
		MetadataUpdate: MetadataUpdate,
		Approval: Approval,
		ApprovalForAll: ApprovalForAll,
		Transfer: Transfer,
	},
}
export const schema: SchemaType = {
	lore_sn: {
		PermitConfig: {
			key: 0,
			messaging_contract: "",
			appchain_contract: "",
			cartridge_contract: "",
		},
		PermitTokenInfo: {
			permit_id: 0,
			permit_type: 0,
			is_used: false,
		trail_name: "",
		},
		PermitType: {
			permit_type: 0,
			actions_count: 0,
		},
		AppchainMessageEvent: {
			uuid: 0,
			caller_address: "",
			from_address: "",
			to_address: "",
			block_number: 0,
			block_timestamp: 0,
			message_hash: 0,
			message_type: 0,
			payload: [0],
		},
		BatchMetadataUpdate: {
		from_token_id: 0,
		to_token_id: 0,
		},
		MetadataUpdate: {
		token_id: 0,
		},
		Approval: {
			owner: "",
			approved: "",
		token_id: 0,
		},
		ApprovalForAll: {
			owner: "",
			operator: "",
			approved: false,
		},
		Transfer: {
			from: "",
			to: "",
		token_id: 0,
		},
	},
};
export enum ModelsMapping {
	PermitConfig = 'lore_sn-PermitConfig',
	PermitTokenInfo = 'lore_sn-PermitTokenInfo',
	PermitType = 'lore_sn-PermitType',
	AppchainMessageEvent = 'lore_sn-AppchainMessageEvent',
	BatchMetadataUpdate = 'nft_combo-BatchMetadataUpdate',
	ContractURIUpdated = 'nft_combo-ContractURIUpdated',
	MetadataUpdate = 'nft_combo-MetadataUpdate',
	Approval = 'openzeppelin_token-Approval',
	ApprovalForAll = 'openzeppelin_token-ApprovalForAll',
	Transfer = 'openzeppelin_token-Transfer',
}