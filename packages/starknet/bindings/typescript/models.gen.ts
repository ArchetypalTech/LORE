import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { CairoOption, CairoOptionVariant, BigNumberish } from 'starknet';

// Type definition for `bundle::models::index::Bundle` struct
export interface Bundle {
	id: BigNumberish;
	referral_percentage: BigNumberish;
	reissuable: boolean;
	price: BigNumberish;
	payment_token: string;
	payment_receiver: string;
	total_issued: BigNumberish;
	created_at: BigNumberish;
	metadata: string;
	contract: string;
	allower: string;
}

// Type definition for `bundle::models::index::BundleGroup` struct
export interface BundleGroup {
	id: BigNumberish;
	total_fees: BigNumberish;
	total_referrals: BigNumberish;
}

// Type definition for `bundle::models::index::BundleIssuance` struct
export interface BundleIssuance {
	bundle_id: BigNumberish;
	recipient: string;
	issued_at: BigNumberish;
}

// Type definition for `bundle::models::index::BundleReferral` struct
export interface BundleReferral {
	id: string;
	total_fees: BigNumberish;
	total_referrals: BigNumberish;
}

// Type definition for `bundle::models::index::BundleVoucher` struct
export interface BundleVoucher {
	key: BigNumberish;
	recipient: string;
}

// Type definition for `lore_sn::models::permit_config::PermitConfig` struct
export interface PermitConfig {
	key: BigNumberish;
	messaging_contract: string;
	appchain_contract: string;
}

// Type definition for `lore_sn::models::permit_token_info::PermitTokenInfo` struct
export interface PermitTokenInfo {
	permit_id: BigNumberish;
	permit_type: BigNumberish;
	is_used: boolean;
	trail_name: string;
}

// Type definition for `bundle::events::index::BundleIssued` struct
export interface BundleIssued {
	recipient: string;
	bundle_id: BigNumberish;
	payment_token: string;
	amount: BigNumberish;
	quantity: BigNumberish;
	referrer: CairoOption<string>;
	referrer_group: CairoOption<BigNumberish>;
	time: BigNumberish;
}

// Type definition for `bundle::events::index::BundleRegistered` struct
export interface BundleRegistered {
	bundle_id: BigNumberish;
	referral_percentage: BigNumberish;
	reissuable: boolean;
	time: BigNumberish;
	payment_receiver: string;
}

// Type definition for `bundle::events::index::BundleUpdated` struct
export interface BundleUpdated {
	bundle_id: BigNumberish;
	referral_percentage: BigNumberish;
	reissuable: boolean;
	price: BigNumberish;
	payment_token: string;
	metadata: string;
	time: BigNumberish;
	payment_receiver: string;
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

// Type definition for `bundle::component::Component::BundleQuote` struct
export interface BundleQuote {
	base_price: BigNumberish;
	referral_fee: BigNumberish;
	client_fee: BigNumberish;
	protocol_fee: BigNumberish;
	total_cost: BigNumberish;
	payment_token: string;
	contract: string;
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
		Bundle: Bundle,
		BundleGroup: BundleGroup,
		BundleIssuance: BundleIssuance,
		BundleReferral: BundleReferral,
		BundleVoucher: BundleVoucher,
		PermitConfig: PermitConfig,
		PermitTokenInfo: PermitTokenInfo,
		BundleIssued: BundleIssued,
		BundleRegistered: BundleRegistered,
		BundleUpdated: BundleUpdated,
		AppchainMessageEvent: AppchainMessageEvent,
		BundleQuote: BundleQuote,
		BatchMetadataUpdate: BatchMetadataUpdate,
		MetadataUpdate: MetadataUpdate,
		Approval: Approval,
		ApprovalForAll: ApprovalForAll,
		Transfer: Transfer,
	},
}
export const schema: SchemaType = {
	lore_sn: {
		Bundle: {
			id: 0,
			referral_percentage: 0,
			reissuable: false,
		price: 0,
			payment_token: "",
			payment_receiver: "",
			total_issued: 0,
			created_at: 0,
		metadata: "",
			contract: "",
			allower: "",
		},
		BundleGroup: {
			id: 0,
			total_fees: 0,
			total_referrals: 0,
		},
		BundleIssuance: {
			bundle_id: 0,
			recipient: "",
			issued_at: 0,
		},
		BundleReferral: {
			id: "",
			total_fees: 0,
			total_referrals: 0,
		},
		BundleVoucher: {
			key: 0,
			recipient: "",
		},
		PermitConfig: {
			key: 0,
			messaging_contract: "",
			appchain_contract: "",
		},
		PermitTokenInfo: {
			permit_id: 0,
			permit_type: 0,
			is_used: false,
		trail_name: "",
		},
		BundleIssued: {
			recipient: "",
			bundle_id: 0,
			payment_token: "",
		amount: 0,
			quantity: 0,
			referrer: new CairoOption(CairoOptionVariant.None),
			referrer_group: new CairoOption(CairoOptionVariant.None),
			time: 0,
		},
		BundleRegistered: {
			bundle_id: 0,
			referral_percentage: 0,
			reissuable: false,
			time: 0,
			payment_receiver: "",
		},
		BundleUpdated: {
			bundle_id: 0,
			referral_percentage: 0,
			reissuable: false,
		price: 0,
			payment_token: "",
		metadata: "",
			time: 0,
			payment_receiver: "",
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
		BundleQuote: {
		base_price: 0,
		referral_fee: 0,
		client_fee: 0,
		protocol_fee: 0,
		total_cost: 0,
			payment_token: "",
			contract: "",
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
	Bundle = 'bundle-Bundle',
	BundleGroup = 'bundle-BundleGroup',
	BundleIssuance = 'bundle-BundleIssuance',
	BundleReferral = 'bundle-BundleReferral',
	BundleVoucher = 'bundle-BundleVoucher',
	PermitConfig = 'lore_sn-PermitConfig',
	PermitTokenInfo = 'lore_sn-PermitTokenInfo',
	BundleIssued = 'bundle-BundleIssued',
	BundleRegistered = 'bundle-BundleRegistered',
	BundleUpdated = 'bundle-BundleUpdated',
	AppchainMessageEvent = 'lore_sn-AppchainMessageEvent',
	BundleQuote = 'bundle-BundleQuote',
	BatchMetadataUpdate = 'nft_combo-BatchMetadataUpdate',
	ContractURIUpdated = 'nft_combo-ContractURIUpdated',
	MetadataUpdate = 'nft_combo-MetadataUpdate',
	Approval = 'openzeppelin_token-Approval',
	ApprovalForAll = 'openzeppelin_token-ApprovalForAll',
	Transfer = 'openzeppelin_token-Transfer',
}