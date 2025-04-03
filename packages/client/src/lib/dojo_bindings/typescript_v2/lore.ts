// Generated by dojo-bindgen on Thu, 3 Apr 2025 12:05:37 +0000. Do not modify this file manually.
import { Account } from "starknet";
import {
    Clause,
    Client,
    ModelClause,
    createClient,
    valueToToriiValueAndOperator,
} from "@dojoengine/torii-client";
import {
    LOCAL_KATANA,
    LOCAL_RELAY,
    LOCAL_TORII,
    createManifestFromJson,
} from "@dojoengine/core";

// Type definition for `lore::lib::relations::ParentToChildrenValue` struct
export interface ParentToChildrenValue {
    is_parent: boolean;
    children: string[];
}

// Type definition for `lore::lib::relations::ParentToChildren` struct
export interface ParentToChildren {
    inst: string;
    is_parent: boolean;
    children: string[];
}

// Type definition for `core::byte_array::ByteArray` struct
export interface ByteArray {
    data: string[];
    pending_word: string;
    pending_word_len: number;
}

// Type definition for `dojo::model::definition::ModelDef` struct
export interface ModelDef {
    name: string;
    layout: Layout;
    schema: Struct;
    packed_size: Option<number>;
    unpacked_size: Option<number>;
}

// Type definition for `dojo::meta::layout::FieldLayout` struct
export interface FieldLayout {
    selector: string;
    layout: Layout;
}

// Type definition for `dojo::meta::introspect::Member` struct
export interface Member {
    name: string;
    attrs: string[];
    ty: Ty;
}

// Type definition for `dojo::meta::introspect::Enum` struct
export interface Enum {
    name: string;
    attrs: string[];
    children: [string, Ty][];
}

// Type definition for `dojo::meta::introspect::Struct` struct
export interface Struct {
    name: string;
    attrs: string[];
    children: Member[];
}

// Type definition for `core::option::Option::<core::integer::u32>` enum
type Option<A> = { type: 'Some'; data: A; } | { type: 'None'; }
// Type definition for `dojo::meta::introspect::Ty` enum
type Ty = { type: 'Primitive'; data: string; } | { type: 'Struct'; data: Struct; } | { type: 'Enum'; data: Enum; } | { type: 'Tuple'; data: Ty[]; } | { type: 'Array'; data: Ty[]; } | { type: 'ByteArray'; }
// Type definition for `dojo::meta::layout::Layout` enum
type Layout = { type: 'Fixed'; data: number[]; } | { type: 'Struct'; data: FieldLayout[]; } | { type: 'Tuple'; data: Layout[]; } | { type: 'Array'; data: Layout[]; } | { type: 'ByteArray'; } | { type: 'Enum'; data: FieldLayout[]; }

// Type definition for `lore::components::player::PlayerValue` struct
export interface PlayerValue {
    is_player: boolean;
    address: string;
    location: string;
}

// Type definition for `lore::components::player::Player` struct
export interface Player {
    inst: string;
    is_player: boolean;
    address: string;
    location: string;
}


// Type definition for `lore::lib::dictionary::Dict` struct
export interface Dict {
    dict_key: string;
    word: string;
    tokenType: TokenType;
    n_value: string;
}

// Type definition for `lore::lib::dictionary::DictValue` struct
export interface DictValue {
    word: string;
    tokenType: TokenType;
    n_value: string;
}

// Type definition for `lore::lib::a_lexer::TokenType` enum
type TokenType = { type: 'Unknown'; } | { type: 'Verb'; } | { type: 'Direction'; } | { type: 'Article'; } | { type: 'Preposition'; } | { type: 'Pronoun'; } | { type: 'Adjective'; } | { type: 'Noun'; } | { type: 'Quantifier'; } | { type: 'Interrogative'; } | { type: 'System'; }

// Type definition for `lore::components::inspectable::ActionMapInspectable` struct
export interface ActionMapInspectable {
    action: string;
    inst: string;
    action_fn: InspectableActions;
}

// Type definition for `lore::components::inspectable::InspectableValue` struct
export interface InspectableValue {
    is_inspectable: boolean;
    is_visible: boolean;
    description: string[];
    action_map: ActionMapInspectable[];
}

// Type definition for `lore::components::inspectable::Inspectable` struct
export interface Inspectable {
    inst: string;
    is_inspectable: boolean;
    is_visible: boolean;
    description: string[];
    action_map: ActionMapInspectable[];
}

// Type definition for `lore::components::inspectable::InspectableActions` enum
type InspectableActions = { type: 'SetVisible'; } | { type: 'ReadDescription'; }

// Type definition for `lore::components::container::Container` struct
export interface Container {
    inst: string;
    is_container: boolean;
    can_be_opened: boolean;
    can_receive_items: boolean;
    is_open: boolean;
    num_slots: number;
    item_ids: string[];
}

// Type definition for `lore::components::container::ContainerValue` struct
export interface ContainerValue {
    is_container: boolean;
    can_be_opened: boolean;
    can_receive_items: boolean;
    is_open: boolean;
    num_slots: number;
    item_ids: string[];
}


// Type definition for `lore::components::inventoryItem::InventoryItemValue` struct
export interface InventoryItemValue {
    is_inventory_item: boolean;
    owner_id: string;
    can_be_picked_up: boolean;
    can_go_in_container: boolean;
}

// Type definition for `lore::components::inventoryItem::InventoryItem` struct
export interface InventoryItem {
    inst: string;
    is_inventory_item: boolean;
    owner_id: string;
    can_be_picked_up: boolean;
    can_go_in_container: boolean;
}


// Type definition for `lore::components::area::AreaValue` struct
export interface AreaValue {
    is_area: boolean;
    direction: Direction;
}

// Type definition for `lore::components::area::Area` struct
export interface Area {
    inst: string;
    is_area: boolean;
    direction: Direction;
}

// Type definition for `lore::constants::constants::Direction` enum
type Direction = { type: 'None'; } | { type: 'North'; } | { type: 'South'; } | { type: 'East'; } | { type: 'West'; } | { type: 'Up'; } | { type: 'Down'; }

// Type definition for `lore::lib::entity::EntityValue` struct
export interface EntityValue {
    is_entity: boolean;
    name: string;
    alt_names: string[];
}

// Type definition for `lore::lib::entity::Entity` struct
export interface Entity {
    inst: string;
    is_entity: boolean;
    name: string;
    alt_names: string[];
}


// Type definition for `lore::lib::relations::ChildToParentValue` struct
export interface ChildToParentValue {
    is_child: boolean;
    parent: string;
}

// Type definition for `lore::lib::relations::ChildToParent` struct
export interface ChildToParent {
    inst: string;
    is_child: boolean;
    parent: string;
}


// Type definition for `lore::components::exit::Exit` struct
export interface Exit {
    inst: string;
    is_exit: boolean;
    is_enterable: boolean;
    leads_to: string;
    direction_type: Direction;
    action_map: string[];
}

// Type definition for `lore::components::exit::ExitValue` struct
export interface ExitValue {
    is_exit: boolean;
    is_enterable: boolean;
    leads_to: string;
    direction_type: Direction;
    action_map: string[];
}


// Type definition for `lore::components::player::PlayerStoryValue` struct
export interface PlayerStoryValue {
    story: string[];
}

// Type definition for `lore::components::player::PlayerStory` struct
export interface PlayerStory {
    inst: string;
    story: string[];
}


class BaseCalls {
    contractAddress: string;
    account?: Account;

    constructor(contractAddress: string, account?: Account) {
        this.account = account;
        this.contractAddress = contractAddress;
    }

    async execute(entrypoint: string, calldata: any[] = []): Promise<void> {
        if (!this.account) {
            throw new Error("No account set to interact with dojo_starter");
        }

        await this.account.execute(
            {
                contractAddress: this.contractAddress,
                entrypoint,
                calldata,
            },
            undefined,
            {
                maxFee: 0,
            }
        );
    }
}

class PromptCalls extends BaseCalls {
    constructor(contractAddress: string, account?: Account) {
        super(contractAddress, account);
    }

    async dojoName(): Promise<void> {
        try {
            await this.execute("dojo_name", [])
        } catch (error) {
            console.error("Error executing dojoName:", error);
            throw error;
        }
    }

    async upgrade(new_class_hash: string): Promise<void> {
        try {
            await this.execute("upgrade", [new_class_hash])
        } catch (error) {
            console.error("Error executing upgrade:", error);
            throw error;
        }
    }

    async prompt(cmd: string): Promise<void> {
        try {
            await this.execute("prompt", [props.cmd.data,
                    props.cmd.pending_word,
                    props.cmd.pending_word_len])
        } catch (error) {
            console.error("Error executing prompt:", error);
            throw error;
        }
    }

    async worldDispatcher(): Promise<void> {
        try {
            await this.execute("world_dispatcher", [])
        } catch (error) {
            console.error("Error executing worldDispatcher:", error);
            throw error;
        }
    }
}
class DesignerCalls extends BaseCalls {
    constructor(contractAddress: string, account?: Account) {
        super(contractAddress, account);
    }

    async dojoName(): Promise<void> {
        try {
            await this.execute("dojo_name", [])
        } catch (error) {
            console.error("Error executing dojoName:", error);
            throw error;
        }
    }

    async createEntity(t: Entity[]): Promise<void> {
        try {
            await this.execute("create_entity", [t])
        } catch (error) {
            console.error("Error executing createEntity:", error);
            throw error;
        }
    }

    async createInspectable(t: Inspectable[]): Promise<void> {
        try {
            await this.execute("create_inspectable", [t])
        } catch (error) {
            console.error("Error executing createInspectable:", error);
            throw error;
        }
    }

    async createArea(t: Area[]): Promise<void> {
        try {
            await this.execute("create_area", [t])
        } catch (error) {
            console.error("Error executing createArea:", error);
            throw error;
        }
    }

    async createExit(t: Exit[]): Promise<void> {
        try {
            await this.execute("create_exit", [t])
        } catch (error) {
            console.error("Error executing createExit:", error);
            throw error;
        }
    }

    async deleteEntity(ids: string[]): Promise<void> {
        try {
            await this.execute("delete_entity", [ids])
        } catch (error) {
            console.error("Error executing deleteEntity:", error);
            throw error;
        }
    }

    async deleteInspectable(ids: string[]): Promise<void> {
        try {
            await this.execute("delete_inspectable", [ids])
        } catch (error) {
            console.error("Error executing deleteInspectable:", error);
            throw error;
        }
    }

    async deleteArea(ids: string[]): Promise<void> {
        try {
            await this.execute("delete_area", [ids])
        } catch (error) {
            console.error("Error executing deleteArea:", error);
            throw error;
        }
    }

    async deleteExit(ids: string[]): Promise<void> {
        try {
            await this.execute("delete_exit", [ids])
        } catch (error) {
            console.error("Error executing deleteExit:", error);
            throw error;
        }
    }

    async worldDispatcher(): Promise<void> {
        try {
            await this.execute("world_dispatcher", [])
        } catch (error) {
            console.error("Error executing worldDispatcher:", error);
            throw error;
        }
    }

    async upgrade(new_class_hash: string): Promise<void> {
        try {
            await this.execute("upgrade", [new_class_hash])
        } catch (error) {
            console.error("Error executing upgrade:", error);
            throw error;
        }
    }
}

type Query = Partial<{
    ParentToChildren: ModelClause<ParentToChildren>;
    Player: ModelClause<Player>;
    Dict: ModelClause<Dict>;
    Inspectable: ModelClause<Inspectable>;
    Container: ModelClause<Container>;
    InventoryItem: ModelClause<InventoryItem>;
    Area: ModelClause<Area>;
    Entity: ModelClause<Entity>;
    ChildToParent: ModelClause<ChildToParent>;
    Exit: ModelClause<Exit>;
    PlayerStory: ModelClause<PlayerStory>;
}>;

type ResultMapping = {
    ParentToChildren: ParentToChildren;
    Player: Player;
    Dict: Dict;
    Inspectable: Inspectable;
    Container: Container;
    InventoryItem: InventoryItem;
    Area: Area;
    Entity: Entity;
    ChildToParent: ChildToParent;
    Exit: Exit;
    PlayerStory: PlayerStory;
};

type QueryResult<T extends Query> = {
    [K in keyof T]: K extends keyof ResultMapping ? ResultMapping[K] : never;
};

// Only supports a single model for now, since torii doesn't support multiple models
// And inside that single model, there's only support for a single query.
function convertQueryToToriiClause(query: Query): Clause | undefined {
    const [model, clause] = Object.entries(query)[0];

    if (Object.keys(clause).length === 0) {
        return undefined;
    }

    const clauses: Clause[] = Object.entries(clause).map(([key, value]) => {
        return {
            Member: {
                model,
                member: key,
                ...valueToToriiValueAndOperator(value),
            },
        } satisfies Clause;
    });

    return clauses[0];
}
type GeneralParams = {
    toriiUrl?: string;
    relayUrl?: string;
    account?: Account;
};

type InitialParams = GeneralParams &
    (
        | {
                rpcUrl?: string;
                worldAddress: string;
                promptAddress: string;
    designerAddress: string;
            }
        | {
                manifest: any;
            }
    );

export class Lore {
    rpcUrl: string;
    toriiUrl: string;
    toriiPromise: Promise<Client>;
    relayUrl: string;
    worldAddress: string;
    private _account?: Account;
    prompt: PromptCalls;
    promptAddress: string;
    designer: DesignerCalls;
    designerAddress: string;

    constructor(params: InitialParams) {
        if ("manifest" in params) {
            const config = createManifestFromJson(params.manifest);
            this.rpcUrl = config.world.metadata.rpc_url;
            this.worldAddress = config.world.address;

            const promptAddress = config.contracts.find(
                (contract) =>
                    contract.name === "dojo_starter::systems::prompt::prompt"
            )?.address;

            if (!promptAddress) {
                throw new Error("No prompt contract found in the manifest");
            }

            this.promptAddress = promptAddress;
    const designerAddress = config.contracts.find(
                (contract) =>
                    contract.name === "dojo_starter::systems::designer::designer"
            )?.address;

            if (!designerAddress) {
                throw new Error("No designer contract found in the manifest");
            }

            this.designerAddress = designerAddress;
        } else {
            this.rpcUrl = params.rpcUrl || LOCAL_KATANA;
            this.worldAddress = params.worldAddress;
            this.promptAddress = params.promptAddress;
    this.designerAddress = params.designerAddress;
        }
        this.toriiUrl = params.toriiUrl || LOCAL_TORII;
        this.relayUrl = params.relayUrl || LOCAL_RELAY;
        this._account = params.account;
        this.prompt = new PromptCalls(this.promptAddress, this._account);
    this.designer = new DesignerCalls(this.designerAddress, this._account);

        this.toriiPromise = createClient([], {
            rpcUrl: this.rpcUrl,
            toriiUrl: this.toriiUrl,
            worldAddress: this.worldAddress,
            relayUrl: this.relayUrl,
        });
    }

    get account(): Account | undefined {
        return this._account;
    }

    set account(account: Account) {
        this._account = account;
        this.prompt = new PromptCalls(this.promptAddress, this._account);
    this.designer = new DesignerCalls(this.designerAddress, this._account);
    }

    async query<T extends Query>(query: T, limit = 10, offset = 0) {
        const torii = await this.toriiPromise;

        return {
            torii,
            findEntities: async () => this.findEntities(query, limit, offset),
        };
    }

    async findEntities<T extends Query>(query: T, limit = 10, offset = 0) {
        const torii = await this.toriiPromise;

        const clause = convertQueryToToriiClause(query);

        const toriiResult = await torii.getEntities({
            limit,
            offset,
            clause,
        });

        return toriiResult as Record<string, QueryResult<T>>;
    }

    async findEntity<T extends Query>(query: T) {
        const result = await this.findEntities(query, 1);

        if (Object.values(result).length === 0) {
            return undefined;
        }

        return Object.values(result)[0] as QueryResult<T>;
    }
}