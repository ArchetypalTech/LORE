#[cfg(test)]
pub mod tests {
    use core::num::traits::Zero;
    use starknet::ContractAddress;
    use dojo::{
        // world::{WorldStorage},
        model::{ModelStorage},
    };
    use lore::models::hub::*;
    use lore::{
        systems::{
            designer::{IDesignerDispatcherTrait},
            prompt::{IPromptDispatcherTrait},
            game_token::{IGameTokenDispatcherTrait},
            trail_token::{ITrailTokenDispatcherTrait},
            actions_token::{IActionsTokenDispatcherTrait},
        },
        models::{
            entity::{Entity, EntityImpl},
            player::{Player, PlayerImpl},
            player_account::{PlayerAccountImpl},
            trail_token_info::{TrailTokenInfo},
            area::{AreaComponent, Area},
            exit::{Exit, ExitComponent, ExitInstance},
            reactable::{ReactableInstance},
            container::{Container, ContainerComponent},
            inventory_item::{InventoryItem, InventoryItemComponent},
            actions_config::{ActionsReward},
        },
        tests::{
            helpers,
            helpers::{OWNER},
        },
        lib::{
            arrays::{ArrayTestUtilsTrait},
            utils::{ByteArrayTraitExt},
        },
        constants::constants::CONST,
    };

    // based on game_token_test::test_token_winner_becomes_editor()
    fn _create_trail(ref sys: helpers::HelperSystems, player_address: ContractAddress) -> (Entity, Trail) {
        // initialize player singleton
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        // mint a game
        helpers::set_caller(player_address);
        sys.prompt.prompt("", Option::None);
        let game_id: u128 = PlayerAccountImpl::current_game_id(@sys.world, player_address);
        assert_gt!(sys.game_token.total_supply(), 0);
        assert_eq!(sys.game_token.owner_of(game_id.into()), player_address);
        // get player
        let player: Player = PlayerImpl::get_player(@sys.world, game_id).unwrap();
        assert!(player.is_player, "player created");
        // set as editor
        helpers::set_caller(OWNER());
        sys.designer.set_editor(player_address, true);
        // create trail
        helpers::set_caller(player_address);
        sys.prompt.prompt("g_create_trail", Option::None);
// helpers::print_game_story_last_line(@sys.world, game_id);
        let trail_id: u128 = game_id; // we're creating one trail per game
// println!("trail_id: {}", trail_id);
        assert_gt!(sys.trail_token.total_supply(), 0);
        assert_eq!(sys.trail_token.owner_of(trail_id.into()), player_address);
        let trail_info: TrailTokenInfo = sys.world.read_model(trail_id);
        assert_ne!(trail_info.seed, 0, "seed");
        assert_ne!(trail_info.trail_inst, 0, "trail_inst");
        let entity: Entity = sys.world.read_model(trail_info.trail_inst);
        let trail: Trail = sys.world.read_model(trail_info.trail_inst);
        helpers::set_caller(OWNER());
        (entity, trail)
    }

    #[test]
    fn test_create_trail_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (entity, trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        assert!(trail.is_trail, "is_trail");
        assert_eq!(entity.name, "Trail-1");
        assert_eq!(entity.trail_id, trail.trail_id);
        assert!(ExitInstance::has_component(@sys.world, entity.inst));
        assert!(ReactableInstance::has_component(@sys.world, entity.inst));
        //
        // add some children
        let game_id: u128 = 0;
        let mut child1: Entity = EntityImpl::create_entity(ref sys.world, "child1");
        let mut child2: Entity = EntityImpl::create_entity(ref sys.world, "child2");
        child1.trail_id = trail.trail_id;
        child2.trail_id = trail.trail_id;
        sys.world.write_model(@child1);
        sys.world.write_model(@child2);
        child1.set_parent(ref sys.world, @entity, game_id);
        child2.set_parent(ref sys.world, @entity, game_id);
        // should be able to delete children
        sys.designer.delete_entity(array![child1.inst, child2.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed to create','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_create_trails_directly() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let mut trail_1: Trail = TrailImpl::add_component(ref sys.world, 0x123, 1);
        sys.designer.create_trail(array![trail_1.clone()]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Invalid trail id','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_edit_trail_id() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_entity, mut trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        trail.trail_id = 2;
        sys.designer.create_trail(array![trail.clone()]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Invalid hub','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_use_invalid_hub() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (_entity, mut trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        trail.hub_inst = 0x123;
        sys.designer.create_trail(array![trail.clone()]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_trail_entity() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (entity, _trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_entity(array![entity.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_trail_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (entity, _trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_trail(array![entity.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_exit_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (entity, _trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_exit(array![entity.inst]);
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Not allowed delete trail','ENTRYPOINT_FAILED'))]
    fn test_not_allowed_to_delete_reactable_component() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let (entity, _trail) : (Entity, Trail) = _create_trail(ref sys, helpers::PLAYER_1);
        helpers::set_caller(OWNER());
        sys.designer.delete_reactable(array![entity.inst]);
    }

    //---------------------------------
    // Hubs + Trails
    //

    pub fn _mint_trail(ref sys: helpers::HelperSystems, recipient: ContractAddress) -> (Entity, Trail, Exit) {
        // initialize player singleton
        helpers::set_caller(OWNER());
        PlayerImpl::caller_as_player(ref sys.world, OWNER(), 0);
        // give recipient editor access
        sys.designer.set_editor(recipient, true);
        // mint from command
        let supply: u128 = sys.trail_token.total_supply().low;
        helpers::set_caller(recipient);
        sys.prompt.prompt("g_create_trail", Option::None);
        // minted
        let trail_id: u128 = supply + 1;
        assert_eq!(sys.trail_token.total_supply().low, trail_id, "trail_token.total_supply()");
        assert_eq!(sys.trail_token.owner_of(trail_id.into()), recipient, "trail.owner_of(recipient)");
        // find entity
        let trail_info: TrailTokenInfo = sys.world.read_model(trail_id);
        assert_ne!(trail_info.trail_inst, 0, "_mint_trail()");
        assert_ne!(trail_info.seed, 0, "_mint_trail()");
        let entity: Entity = sys.world.read_model(trail_info.trail_inst);
        let trail: Trail = sys.world.read_model(trail_info.trail_inst);
        let exit: Exit = sys.world.read_model(trail_info.trail_inst);
        assert_eq!(trail.trail_id, trail_id, "_mint_trail()");
        assert_eq!(entity.trail_id, trail_id, "_mint_trail()");
        (entity, trail, exit)
    }

    #[test]
    fn test_designer_create_hub_trails_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create trails
        // Create Hubs
        let entity_hub_1: Entity = EntityImpl::create_entity(ref sys.world, "hub");
        let entity_hub_2: Entity = EntityImpl::create_entity(ref sys.world, "hub");
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, entity_hub_1.inst);
        let mut hub_2: Hub = HubImpl::add_component(ref sys.world, entity_hub_2.inst);
        // create with designer
        helpers::set_caller(OWNER());
        sys.designer.create_entity(array![entity_hub_1.clone(), entity_hub_2.clone()]);
        sys.designer.create_hub(array![hub_1.clone(), hub_2.clone()]);
        // mint Trails -- will create trails
        let (_entity_trail_1, mut trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (_entity_trail_2, mut trail_2, _exit_2): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (_entity_trail_3, mut trail_3, _exit_3): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        trail_1.hub_inst = hub_1.inst;
        trail_2.hub_inst = hub_1.inst;
        trail_3.hub_inst = 0;
        // edit Trails with designer >> assign to Hubs
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone(), trail_3.clone()]);
        //
        // check hub trails
        let mut hub_1: Hub = sys.world.read_model(hub_1.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![trail_1.inst, trail_2.inst].span(), "hub_1.trails_insts 1");
        ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_insts.span(), array![].span(), "hub_2.trails_insts 2");
        //
        // try to edit trails -- NOW ALLOWED!
        hub_1.trails_insts = array![trail_3.inst];
        sys.designer.create_hub(array![hub_1.clone()]);
        let mut hub_1: Hub = sys.world.read_model(hub_1.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![trail_1.inst, trail_2.inst].span(), "hub_1.trails_insts STILL");
        //
        // move trails...
        trail_1.hub_inst = 0; // remove...
        trail_2.hub_inst = hub_2.inst; // move...
        trail_3.hub_inst = hub_2.inst; // add...
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone(), trail_3.clone()]);
        let hub_1: Hub = sys.world.read_model(hub_1.inst);
        let hub_2: Hub = sys.world.read_model(hub_2.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![].span(), "hub_1.trails_insts 2");
        ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_insts.span(), array![trail_2.inst, trail_3.inst].span(), "hub_2.trails_insts 2");
        //
        // delete trail, remove from hub -- NOT ALLOWED!!
//         sys.designer.delete_trail(array![trail_2.inst]);
//         let hub_1: Hub = sys.world.read_model(hub_1.inst);
//         let hub_2: Hub = sys.world.read_model(hub_2.inst);
//         ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![].span(), "hub_1.trails_insts 3");
//         ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_insts.span(), array![trail_3.inst].span(), "hub_2.trails_insts 3");
        //
        // delete Hub, remove trails from hub
        sys.designer.delete_hub(array![hub_2.inst]);
        let hub_1: Hub = sys.world.read_model(hub_1.inst);
        let hub_2: Hub = sys.world.read_model(hub_2.inst);
        let trail_1: Trail = sys.world.read_model(trail_1.inst);
        let trail_2: Trail = sys.world.read_model(trail_2.inst);
        let trail_3: Trail = sys.world.read_model(trail_3.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![].span(), "hub_1.trails_insts 4");
        ArrayTestUtilsTrait::assert_span_eq(hub_2.trails_insts.span(), array![].span(), "hub_2.trails_insts 4");
        assert!(trail_1.hub_inst.is_zero(), "trail_1.hub_inst 4");
        assert!(trail_2.hub_inst.is_zero(), "trail_2.hub_inst 4");
        assert!(trail_3.hub_inst.is_zero(), "trail_3.hub_inst 4");
    }

    #[test]
    #[should_panic(expected: ('TRAIL: Hub is disabled','ENTRYPOINT_FAILED'))]
    fn test_designer_create_trail_to_disabled_hub() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create trails
        let (_entity_trail_1, mut trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        // Create Hubs
        let entity_hub_1: Entity = EntityImpl::create_entity(ref sys.world, "hub");
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, entity_hub_1.inst);
        hub_1.is_enabled = false;
        trail_1.hub_inst = hub_1.inst;
        //
        // create with designer
        helpers::set_caller(OWNER());
        sys.designer.create_entity(array![entity_hub_1.clone()]);
        sys.designer.create_hub(array![hub_1.clone()]);
        // edit trail and panic...
        sys.designer.create_trail(array![trail_1.clone()]);
    }


    #[test]
    #[should_panic(expected: ('TRAIL: Invalid hub','ENTRYPOINT_FAILED'))]
    fn test_designer_create_trail_to_invalid_hub() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create trails
        let (_entity_trail_1, mut trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        trail_1.hub_inst = 0x123;
        //
        // edit trail and panic...
        helpers::set_caller(OWNER());
        sys.designer.create_trail(array![trail_1.clone()]);
    }


    #[test]
    fn test_get_hub_trails_as_children_ok() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // Create Hubs
        let game_id: u128 = 0;
        let entity_hub_1: Entity = EntityImpl::create_entity(ref sys.world, "hub");
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, entity_hub_1.inst);
        sys.designer.create_entity(array![entity_hub_1.clone()]);
        sys.designer.create_hub(array![hub_1.clone()]);
        // mint Trails
        let (entity_trail_1, mut trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (entity_trail_2, mut trail_2, _exit_2): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (entity_trail_3, mut trail_3, _exit_3): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        // add trails to hub
        trail_1.hub_inst = hub_1.inst;
        trail_2.hub_inst = hub_1.inst;
        trail_3.hub_inst = hub_1.inst;
        trail_1.is_published = true;
        trail_2.is_published = true;
        trail_3.is_published = false;
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone(), trail_3.clone()]);
        // validate...
        let hub_1: Hub = sys.world.read_model(hub_1.inst);
        ArrayTestUtilsTrait::assert_span_eq(hub_1.trails_insts.span(), array![trail_1.inst, trail_2.inst, trail_3.inst].span(), "hub_1.trails_insts");
        // create Areas inside trails
        let mut entity_area_1_spawn: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_1_spawn");
        let mut entity_area_1_other: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_1_other");
        let mut entity_area_2_spawn: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_2_spawn");
        let mut entity_area_2_other: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_2_other");
        let mut entity_area_3_spawn: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_3_spawn");
        let mut entity_area_3_other: Entity = EntityImpl::create_entity(ref sys.world, "entity_area_3_other");
        let mut area_1_spawn: Area = AreaComponent::add_component(ref sys.world, entity_area_1_spawn.inst);
        let mut area_1_other: Area = AreaComponent::add_component(ref sys.world, entity_area_1_other.inst);
        let mut area_2_spawn: Area = AreaComponent::add_component(ref sys.world, entity_area_2_spawn.inst);
        let mut area_2_other: Area = AreaComponent::add_component(ref sys.world, entity_area_2_other.inst);
        let mut area_3_spawn: Area = AreaComponent::add_component(ref sys.world, entity_area_3_spawn.inst);
        let mut area_3_other: Area = AreaComponent::add_component(ref sys.world, entity_area_3_other.inst);
        area_1_spawn.is_spawn_point = true;
        area_1_other.is_spawn_point = false;
        area_2_spawn.is_spawn_point = true;
        area_2_other.is_spawn_point = false;
        area_3_spawn.is_spawn_point = true;
        area_3_other.is_spawn_point = false;
        entity_area_1_spawn.trail_id = trail_1.trail_id;
        entity_area_1_other.trail_id = trail_1.trail_id;
        entity_area_2_spawn.trail_id = trail_2.trail_id;
        entity_area_2_other.trail_id = trail_2.trail_id;
        entity_area_3_spawn.trail_id = trail_3.trail_id;
        entity_area_3_other.trail_id = trail_3.trail_id;
        sys.designer.create_entity(array![
            entity_area_1_spawn.clone(), entity_area_1_other.clone(),
            entity_area_2_spawn.clone(), entity_area_2_other.clone(),
            entity_area_3_spawn.clone(), entity_area_3_other.clone(),
        ]);
        sys.designer.create_area(array![
            area_1_spawn.clone(), area_1_other.clone(),
            area_2_spawn.clone(), area_2_other.clone(),
            area_3_spawn.clone(), area_3_other.clone(),
        ]);
        entity_area_1_spawn.set_parent(ref sys.world, @entity_trail_1, game_id);
        entity_area_1_other.set_parent(ref sys.world, @entity_trail_1, game_id);
        entity_area_2_spawn.set_parent(ref sys.world, @entity_trail_2, game_id);
        entity_area_2_other.set_parent(ref sys.world, @entity_trail_2, game_id);
        entity_area_3_spawn.set_parent(ref sys.world, @entity_trail_3, game_id);
        entity_area_3_other.set_parent(ref sys.world, @entity_trail_3, game_id);
        //
        // check hub trails as children
        let children: Span<Entity> = hub_1.get_trails_as_children(@sys.world).span();
        assert_eq!(children.len(), 2, "exits.len()");
        assert_eq!(*children[0].inst, entity_trail_1.inst, "children[0].inst");
        assert_eq!(*children[1].inst, entity_trail_2.inst, "children[1].inst");
        //
        // check hub trails -- NOT USED!
        // let exits: Span<Exit> = hub_1.get_trails_exits(@sys.world);
        // assert_eq!(exits.len(), 2, "exits.len()");
        // assert_eq!(*exits[0].leads_to, area_1_spawn.inst, "exits[0].leads_to");
        // assert_eq!(*exits[1].leads_to, area_2_spawn.inst, "exits[1].leads_to");
    }
    
    #[test]
    fn test_hub_look_around() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // create some rooms
        let (room_1_entity, area_1): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 1", "ROOM1", Option::None);
        let (room_2_entity, area_2): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 2", "ROOM2", Option::None);
        // create exits
        let (_exit_1_entity, _exit_to_room_2): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit To Room 2", "to_room_2", @room_1_entity, area_2.inst);
        let (_exit_2_entity, _exit_to_room_1): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit To Room 1", "to_room_1", @room_2_entity, area_1.inst);
        //
        // create player
        let game_id: u128 = 1;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, 0);
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None); // creates game token
// helpers::print_game_story_last_command(@sys.world, game_id, "init");
        // place in Room 2
        helpers::set_caller(helpers::OWNER());
        player.move_to_room(ref sys.world, room_2_entity.inst);
        //
        // move to room 1
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("use to_room_1", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "use to_room_1");
        sys.prompt.prompt("look around", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (in_room_1)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "to_room_2", "look 2");
        //
        // Create Hub inside ROOM 1
        helpers::set_caller(helpers::OWNER());
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, room_1_entity.inst);
        // sys.world.write_model(@hub_1);
        sys.designer.create_hub(array![hub_1.clone()]);
        // mint Trails
        let (entity_trail_1, mut trail_1, mut exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        let (entity_trail_2, mut trail_2, mut exit_2): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        // add trails to hub
        trail_1.hub_inst = hub_1.inst;
        trail_2.hub_inst = hub_1.inst;
        trail_1.is_published = true;
        trail_2.is_published = false;
        // sys.world.write_model(@trail_1);
        // sys.world.write_model(@trail_2);
        sys.designer.create_trail(array![trail_1.clone(), trail_2.clone()]);
        //
        // Create areas inside trails
        let (trail_1_area_entity, _trail_1_area): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Trail 1", "TRAIL1", Option::Some(@entity_trail_1));
        let (trail_2_area_entity, _trail_2_area): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Trail 2", "TRAIL2", Option::Some(@entity_trail_2));
        exit_1.leads_to = trail_1_area_entity.inst;
        exit_2.leads_to = trail_2_area_entity.inst;
        sys.world.write_model(@exit_1);
        sys.world.write_model(@exit_2);
        // create exits back to Hub
        let (_exit_1_entity, _exit_from_trail_1): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit From Trail 1", "trail_1_exit", @trail_1_area_entity, room_1_entity.inst);
        let (_exit_2_entity, _exit_from_trail_2): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit From Trail 2", "trail_2_exit", @trail_2_area_entity, room_1_entity.inst);
        //
        // list rooms (with trail)
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("look around", Option::None); // will display the description
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (+trail_1)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1"); // last exit available
        //
        // enable Trail2 
        helpers::set_caller(helpers::OWNER());
        trail_2.is_published = true;
        sys.world.write_model(@trail_2);
        // list rooms (with trail)
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("look around", Option::None); // will display the description
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (+trail_2)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-2"); // last exit available

        //
        // move to trail 1...
        sys.prompt.prompt("use trail-1", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "use trail-1");
        // assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1", "use trail-1");
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (IN trail_1 AGAIN)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail_1_exit"); // last exit available

        //
        // move back to hub...
        sys.prompt.prompt("use trail_1_exit", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "use trail_1_exit");
        // assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1", "use trail-1");
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (trail_1_exit)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-2"); // last exit available

        //
        // create a player's container
        helpers::set_caller(helpers::OWNER());
        let player_entity: Entity = sys.world.read_model(player.inst);
        let _player_container: Container = ContainerComponent::add_component(ref sys.world, player_entity.inst);
        // list empty inventory
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("inventory", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "inventory (EMPTY)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "It is empty.");
        //
        // Add something to the player's container
        helpers::set_caller(helpers::OWNER());
        let mut item1_entity: Entity = EntityImpl::create_entity(ref sys.world, "item-1");
        let mut _item1: InventoryItem = InventoryItemComponent::add_component(ref sys.world, item1_entity.inst);
        assert!(!item1_entity.has_parent(@sys.world, game_id), "!item1.has_parent");
        item1_entity.set_parent(ref sys.world, @player_entity, game_id);
        sys.world.write_model(@item1_entity);
        // list invetory
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("inventory", Option::None);
helpers::print_game_story_last_command(@sys.world, game_id, "inventory (hub)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "item-1"); // last item available

        //
        // move to trail 2...
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("use trail-2", Option::None);
helpers::print_game_story_last_command(@sys.world, game_id, "use trail-21");
        // assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1", "use trail-1");
        sys.prompt.prompt("look around", Option::None);
helpers::print_game_story_last_command(@sys.world, game_id, "look around (IN trail_2 AGAIN)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail_2_exit"); // last exit available

        //
        // DROP something from the player's inventory
        sys.prompt.prompt("drop item-1", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "drop item-1");
        sys.prompt.prompt("inventory", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "inventory (dropped item-1)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "It is empty.");
        sys.prompt.prompt("look around", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (dropped item-1)");

        //
        // exit trail 2...
        // TODO: implement [exit trail] command
        sys.prompt.prompt("exit trail", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "exit trail_2");
        // assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1", "use trail-1");
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (exit trail_2 AGAIN)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-2"); // last exit available
    }
    
    #[test]
    fn test_spend_actions_in_trail() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        helpers::set_caller(helpers::OWNER());
        sys.actions.set_action_cost_amount(1 * CONST::ETH_TO_WEI.low);
        // create some rooms
        let (room_1_entity, _area_1): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Room 1", "ROOM1", Option::None);
        //
        // create player
        let game_id: u128 = 1;
        let player: Player = PlayerImpl::caller_as_player(ref sys.world, helpers::PLAYER_1, 0);
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None); // creates game token
// helpers::print_game_story_last_command(@sys.world, game_id, "init");
        // place in Room 2
        helpers::set_caller(helpers::OWNER());
        player.move_to_room(ref sys.world, room_1_entity.inst);
        //
        // Create Hub inside ROOM 1
        helpers::set_caller(helpers::OWNER());
        let mut hub_1: Hub = HubImpl::add_component(ref sys.world, room_1_entity.inst);
        // sys.world.write_model(@hub_1);
        sys.designer.create_hub(array![hub_1.clone()]);
        // mint Trails
        let (entity_trail_1, mut trail_1, mut exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, OWNER());
        // add trails to hub
        trail_1.hub_inst = hub_1.inst;
        trail_1.is_published = true;
        sys.designer.create_trail(array![trail_1.clone()]);
        //
        // Create areas inside trails
        let (trail_1_area_entity, _trail_1_area): (Entity, Area) = helpers::create_area_entity(ref sys, "This is Trail 1", "TRAIL1", Option::Some(@entity_trail_1));
        let (_exit_1_entity, _exit_from_trail_1): (Entity, Exit) = helpers::create_exit_in_area(ref sys, "Exit From Trail 1", "trail_1_exit", @trail_1_area_entity, room_1_entity.inst);
        exit_1.leads_to = trail_1_area_entity.inst;
        sys.world.write_model(@exit_1);
        //
        // list rooms (with trail)
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("look around", Option::None); // will display the description
// helpers::print_game_story_last_command(@sys.world, game_id, "look around");
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (+trail_1)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1"); // last exit available
        //
        // move to trail 1...
        sys.prompt.prompt("use trail-1", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id, "use trail-1");
        // assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail-1", "use trail-1");
        sys.prompt.prompt("look around", Option::None); // willl display reactable.new_entry
// helpers::print_game_story_last_command(@sys.world, game_id, "look around (IN trail_1 AGAIN)");
        assert_eq!(helpers::game_story_last_line(@sys.world, game_id), "trail_1_exit"); // last exit available
        
        // check trail collected actions
        let actions_reward: ActionsReward = sys.world.read_model(OWNER());
// println!("actions_reward.collected_actions_amount: {}", actions_reward.collected_actions_amount);
        assert_gt!(actions_reward.collected_actions_amount, 0, "actions_reward.collected_actions_amount");
        assert_eq!(actions_reward.claimed_actions_amount, 0, "actions_reward.claimed_actions_amount");

        // check actions collected balance
        let game_id_2: u128 = 2;
        helpers::set_caller(helpers::OWNER());
        sys.prompt.prompt("", Option::None); // creates game token
        sys.prompt.prompt("g_actions", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id_2, "g_actions");
        let actions_balance: u128 = (sys.actions.balance_of(OWNER()).low / CONST::ETH_TO_WEI.low);
        let actions_collected: u128 = (actions_reward.collected_actions_amount / CONST::ETH_TO_WEI.low);
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 5), format!("+sys+actions balance: {}", actions_balance));
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 4), format!("+sys+actions collected: {}", actions_collected));
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 3), "+sys+actions claimed: 0");
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 2), format!("+sys+actions claimable: {}", actions_collected));
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 1), "+sys+permits claimable: 0");

        // claim collected actions as actions
        sys.prompt.prompt("g_claim_actions", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id_2, "g_claim_actions");
        let actions_balance_after: u128 = actions_balance + actions_collected;
        let actions_collected: u128 = (actions_reward.collected_actions_amount / CONST::ETH_TO_WEI.low);
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 2), format!("+sys+actions claimed: {}", actions_collected));
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 1), format!("+sys+actions balance: {}", actions_balance_after));
        assert_eq!(sys.actions.balance_of(OWNER()), actions_balance_after.into() * CONST::ETH_TO_WEI);
        let actions_reward: ActionsReward = sys.world.read_model(OWNER());
        assert_gt!(actions_reward.collected_actions_amount, 0, "actions_reward.collected_actions_amount CLAIMED");
        assert_eq!(actions_reward.claimed_actions_amount, actions_reward.collected_actions_amount, "actions_reward.claimed_actions_amount CLAIMED");

        sys.prompt.prompt("g_actions", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id_2, "g_actions");
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 5), format!("+sys+actions balance: {}", actions_balance_after));
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 4), format!("+sys+actions collected: {}", actions_collected));
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 3), format!("+sys+actions claimed: {}", actions_collected));
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 2), "+sys+actions claimable: 0");
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 1), "+sys+permits claimable: 0");
    }
    
    #[test]
    fn test_trail_commands() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        // mint Trails
        let (_entity_trail_1, mut _trail_1, _exit_1): (Entity, Trail, Exit) = _mint_trail(ref sys, helpers::PLAYER_1);
        // player_1 say anything... (will create a game)
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("", Option::None);
        let game_id_1: u128 = 1;
        helpers::set_caller(helpers::PLAYER_2);
        sys.prompt.prompt("", Option::None);
        let game_id_2: u128 = 2;
        // owner commands
        helpers::set_caller(helpers::PLAYER_1);
        sys.prompt.prompt("g_trail_info 1", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id_1, "g_trail_info 1");
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_1, 2), "+sys+trail-1");
        assert!(helpers::game_story_line_backwards(@sys.world, game_id_1, 1).starts_with(@"+sys+Your"));
        // owner commands
        helpers::set_caller(helpers::PLAYER_2);
        sys.prompt.prompt("g_trail_info 1", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id_2, "g_trail_info 1");
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 2), "+sys+trail-1");
        assert!(helpers::game_story_line_backwards(@sys.world, game_id_2, 1).starts_with(@"+sys+Owner"));
        // invalid
        sys.prompt.prompt("g_trail_info 2", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id_2, "g_trail_info 1");
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 1), "Trail does not exist");
        // main
        sys.prompt.prompt("g_trail_info 0", Option::None);
// helpers::print_game_story_last_command(@sys.world, game_id_2, "g_trail_info 1");
        assert_eq!(helpers::game_story_line_backwards(@sys.world, game_id_2, 1), "+sys+you are in the Oruggin Trail");
        // bad usage
        sys.prompt.prompt("g_trail_info", Option::None);
        assert!(helpers::game_story_line_backwards(@sys.world, game_id_2, 1).starts_with(@"+sys+usage:"));
    }
}
