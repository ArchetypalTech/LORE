use core::option::{OptionTraitImpl};

#[starknet::interface]
pub trait IGameInstance<T> {
    fn create_game_instance(ref self: T, name: ByteArray);
    fn join_game_instance(ref self: T, game_instance_id: felt252);
}

#[dojo::contract]
pub mod game_instance {
    use super::IGameInstance;
    use starknet::{get_caller_address, get_block_timestamp};
    use dojo::{world::WorldStorage};
    use lore::{
    models::{index::{GameInstance}, player::caller_as_player},
    new_components::player_trait::PlayerImpl,
    lib::{utils::ByteArrayTraitExt},
};

    #[constructor]
    fn constructor(ref self: ContractState) {
        // Constructor can be empty for now
    }

    #[abi(embed_v0)]
    pub impl GameInstanceImpl of IGameInstance<ContractState> {
        fn create_game_instance(ref self: ContractState, name: ByteArray) {
            let mut world: WorldStorage = self.world(@"lore");
            let caller = get_caller_address();
            
            // Create new game instance
            let game_instance_id = 12345; // Simple ID for now
            let game_instance = GameInstance {
                inst: game_instance_id,
                is_game_instance: true,
                owner: caller,
                name,
                is_active: true,
                created_at: get_block_timestamp(),
            };
            
            // TODO: Fix world.write_model when Dojo API is available
            
            // Initialize basic world for this instance
            initialize_basic_world(world, game_instance_id);
            
            // Auto-join the creator
            join_game_instance_internal(world, caller, game_instance_id);
        }
        
        fn join_game_instance(ref self: ContractState, game_instance_id: felt252) {
            let mut world: WorldStorage = self.world(@"lore");
            let caller = get_caller_address();
            
            // TODO: Verify game instance exists and is active when Dojo API is available
            // let game_instance: GameInstance = world.read_model(game_instance_id);
            // assert(game_instance.is_game_instance, 'Game instance does not exist');
            // assert(game_instance.is_active, 'Game instance is not active');
            
            // Join the game instance
            join_game_instance_internal(world, caller, game_instance_id);
        }
    }

    fn join_game_instance_internal(mut world: WorldStorage, caller: starknet::ContractAddress, game_instance_id: felt252) {
        // Get or create player and assign to game instance
        let mut player = caller_as_player(world, caller);
        player.game_instance = game_instance_id;
        // TODO: Fix world.write_model when Dojo API is available
    }

    fn initialize_basic_world(mut world: WorldStorage, game_instance_id: felt252) {
        // Create a basic spawn area for this instance
        create_basic_spawn_area(world, game_instance_id);
        
        // Create a few basic entities for this instance
        create_basic_entities(world, game_instance_id);
    }

    fn create_basic_spawn_area(mut world: WorldStorage, game_instance_id: felt252) {
        // Create a basic spawn area
        let spawn_area_id = 12346; // Simple ID for now
        let spawn_area = lore::models::index::Area {
            inst: spawn_area_id,
            game_instance: game_instance_id,
            is_area: true,
            is_spawn_point: true,
        };
        
        // TODO: Fix world.write_model when Dojo API is available
        
        // Create corresponding entity
        let spawn_entity = lore::models::index::Entity {
            inst: spawn_area_id,
            game_instance: game_instance_id,
            is_entity: true,
            name: "Spawn Area",
            alt_names: array![],
            actions_keys: array![],
        };
        
        // TODO: Fix world.write_model when Dojo API is available
    }

    fn create_basic_entities(mut world: WorldStorage, game_instance_id: felt252) {
        // Create a basic inspectable object
        let inspectable_id = 12347; // Simple ID for now
        let inspectable = lore::models::index::Inspectable {
            inst: inspectable_id,
            game_instance: game_instance_id,
            is_inspectable: true,
            is_visible: true,
            description: array![1],
            action_map: array![],
            already_shown: false,
            new_entry: "",
        };
        
        // TODO: Fix world.write_model when Dojo API is available
        
        // Create corresponding entity
        let inspectable_entity = lore::models::index::Entity {
            inst: inspectable_id,
            game_instance: game_instance_id,
            is_entity: true,
            name: "Mysterious Object",
            alt_names: array!["object", "thing"],
            actions_keys: array![],
        };
        
        // TODO: Fix world.write_model when Dojo API is available
        
        // Create description text
        let description_text = lore::models::index::DescriptionText {
            inst: inspectable_id,
            key: 1,
            text: "You see a mysterious object. It seems to be waiting for something.",
        };
        
        // TODO: Fix world.write_model when Dojo API is available
    }
}
