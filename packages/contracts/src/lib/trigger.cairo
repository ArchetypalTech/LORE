use dojo::{world::{WorldStorage}, model::ModelStorage};

use lore::{
    components::{
        area::{AreaComponent},
        exit::{ExitComponent},
        inspectable::{InspectableComponent},
        inventoryItem::{InventoryItemComponent},
        container::{ContainerComponent},
        player::{PlayerComponent},
    },
    constants::errors::Error, 
    lib::{entity::{Entity, EntityImpl}}
};

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Trigger {
    #[key]
    pub key: felt252, // Unique identifier, should be the entity is attached to
    pub name: ByteArray, // Human-readable name
    // properties
    pub trigger_type: TriggerType, // The type of trigger
    pub parameters: Array<TriggerParameter>, // Trigger parameters
    pub is_enabled: bool, // Whether the trigger is enabled
}

#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct TriggerIndex {
    #[key]
    pub trigger_type: TriggerType,
    //pub key: felt252,    
    pub trigger_id: Array<felt252>,
}

#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
pub struct TriggerContext {
    pub doer: felt252, // The entity that triggered the action (usually the player)    
    pub target1: felt252, // Primary target of the action (e.g., item being picked up, area being entered)    
    pub target2: felt252, // Secondary target (e.g., container being opened, item being used on)    
    pub inventory_object: felt252, // Inventory object involved (e.g., item being moved to/from inventory)
}

#[derive(Clone, Drop, Serde, Debug, PartialEq, Introspect)]
pub struct TriggerParameter {
    pub name: ByteArray,
    pub value: felt252,
}

#[derive(Serde, Copy, Drop, Debug, PartialEq, Introspect)]
pub enum TriggerType {
    // Player Triggers //
    PlayerEntersArea,
    PlayerLeavesArea,
    // EXPAND LATER//
}

#[generate_trait]
pub impl TriggerImpl of TriggerTrait {
    fn register_trigger(mut world: WorldStorage, trigger: Trigger) -> Result<(), Error> {
        // 1. Register trigger
        // Optional check: ensure name is short enough
        if (trigger.name.clone().len() >= 31) {
            return Result::Err(Error::NameTooLong);
        }
        // Store in Dojo world state
        world.write_model(@trigger);

        // 2. Update trigger index
        let result: Result = Self::update_triggerIndex(world, trigger.trigger_type, trigger.key);
        if result.is_err() {
            return Result::Err(Error::FailedToUpdateTriggerIndex);
        }
        // Done
        Result::Ok(())
    }

    fn get_triggerIndex(world: @WorldStorage, trigger_type: @TriggerType) -> Option<TriggerIndex> {
        let key: felt252 = trigger_type.clone().into();
        let trigger_index: TriggerIndex = world.read_model(key);
        if trigger_index.trigger_id.len() == 0 {
            return Option::None;
        }
        Option::Some(trigger_index)
    }

    fn update_triggerIndex(
        mut world: WorldStorage, trigger_type: TriggerType, key: felt252,
    ) -> Result<(), Error> {
        // Get the trigger index option
        let maybe_index = Self::get_triggerIndex(@world, @trigger_type);

        match maybe_index {
            Option::None => {
                // Create new trigger index
                let mut trigger_ids = ArrayTrait::<felt252>::new();
                trigger_ids.append(key);

                let _key_f: felt252 = trigger_type.clone().into();
                let trigger_index = TriggerIndex { trigger_type:trigger_type, trigger_id: trigger_ids };
                world.write_model(@trigger_index);
                Result::Ok(())
            },
            Option::Some(mut trigger_index) => {
                // Append trigger key to trigger index
                trigger_index.trigger_id.append(key);
                world.write_model(@trigger_index);
                Result::Ok(())
            },
        }
    }

    fn enable_trigger(mut world: WorldStorage, mut trigger: Trigger) {
        // Enable trigger
        trigger.is_enabled = true;
        world.write_model(@trigger);
    }

    fn disable_trigger(mut world: WorldStorage, mut trigger: Trigger) {
        // Disable trigger
        trigger.is_enabled = false;
        world.write_model(@trigger);
    }

    fn evaluate_trigger(world: @WorldStorage, trigger: @Trigger) -> Result<(), Error> {
        let mut result: Result::<(), Error> = Result::Ok(());
        // Evaluate trigger
        if !*trigger.is_enabled {
            return result; // If not enable is not an error.
        }

        match trigger.trigger_type {
            TriggerType::PlayerEntersArea => {
                // Get entity that trigger is attached to
                let ent_opt = EntityImpl::get_entity(world, trigger.key);
                if ent_opt.is_none() {
                    return Result::Err(Error::EntityNotFound);
                }
                // Check if entity has an area component
                let ent = ent_opt.unwrap();
                let area_opt = AreaComponent::get_component(*world, ent.inst);
                if area_opt.is_none() {
                    return Result::Err(Error::NoAreaComponent);
                }
                // Check if entity has player as a child
                let children = ent.get_children(world);
                let mut player_found = false;
                for child in children {
                    let child_player = PlayerComponent::get_component(*world, child.inst);
                    if child_player.is_some() {
                        player_found = true;
                        break;
                    }
                };
                if !player_found {
                    result = Result::Err(Error::TriggerNotMeetConditions);
                    return result;
                }
                return result;
            },
            TriggerType::PlayerLeavesArea => {
                // Get entity that trigger is attached to
                let ent_opt = EntityImpl::get_entity(world, trigger.key);
                if ent_opt.is_none() {
                    return Result::Err(Error::EntityNotFound);
                }
                // Check if entity has an area component
                let ent = ent_opt.unwrap();
                let area_opt = AreaComponent::get_component(*world, ent.inst);
                if area_opt.is_none() {
                    return Result::Err(Error::NoAreaComponent);
                }
                // Check if the entity does not have a player as a child
                let children = ent.get_children(world);
                let mut player_found = false;
                for child in children {
                    let child_player = PlayerComponent::get_component(*world, child.inst);
                    if child_player.is_some() {
                        player_found = true;
                        break;
                    }
                };
                if player_found {
                    return Result::Err(Error::TriggerNotMeetConditions);
                }
                return result;
            },
        }

        result
    }
}

pub impl TriggerTypeToFelt252 of Into<TriggerType, felt252> {
    #[inline]
    fn into(self : TriggerType) -> felt252 {
        match self {
            TriggerType::PlayerEntersArea => 0,
            TriggerType::PlayerLeavesArea => 1,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use dojo::{model::ModelStorage};
    use lore::tests::helpers;
    use lore::{lib::{entity::{EntityImpl}, trigger::{Trigger,TriggerType, TriggerImpl, TriggerParameter}},
        components::{area::{AreaComponent}, exit::{ExitComponent}, player::{Player, PlayerComponent, caller_as_player, PlayerImpl}}
    };
    use lore::constants::constants::Direction;
    use lore::lib::a_lexer::{Token, TokenType, Command};
    use lore::lib::c_handler::handle_command;

    fn create_test_trigger(key: felt252, nameT: ByteArray, trigger_type: TriggerType) -> Trigger {
        Trigger {
            key,
            name: nameT,
            trigger_type,
            parameters: array![
                TriggerParameter { name: "area", value: key },
            ],
            is_enabled: true,
        }
    }

    #[test]
    fn test_trigger_register_and_index() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        let trigger = create_test_trigger(1, "TestTrigger",TriggerType::PlayerEntersArea );

        let result = TriggerImpl::register_trigger(world, trigger.clone());
        assert(result.is_ok(), 'Trig not register successfully');

        let stored: Trigger = world.read_model(trigger.key);
        assert(stored.key == 1, 'Trigger key should match');
        assert(stored.name == "TestTrigger", 'Trigger name should match');

        let _key: felt252 = trigger.trigger_type.clone().into();
        let index: TriggerIndex = world.read_model(trigger.trigger_type);
        assert(index.trigger_id.len() == 1, 'Trig index should have one ID');
        assert(index.trigger_id[0] == @trigger.key, 'Idx should have the trigger key');
    }

    #[test]
    fn test_trigger_name_too_long() {
        let (mut world, _, _, _, _) = helpers::setup_core();
        let long_name = "Aakldjflkajdflkjldafljaldfjldjsdfdfdf";

        // Create entity
        let mut player = EntityImpl::create_entity(world);
        player.name = "player";
        world.write_model(@player);

        // Create trigger
        let trigger = create_test_trigger(2, long_name, TriggerType::PlayerLeavesArea);
        world.write_model(@trigger);

        let result = TriggerImpl::register_trigger(world, trigger);
        assert(result.is_err(), 'Trig name too long should fail');
    }

    #[test]
    fn test_trigger_enable_disable() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create trigger
        let trigger = create_test_trigger(3, "TestTrigger", TriggerType::PlayerLeavesArea);

        world.write_model(@trigger);
        TriggerImpl::enable_trigger(world, trigger.clone());
        let enabled: Trigger = world.read_model(trigger.key);
        assert(enabled.is_enabled, 'Trigger should be enabled');

        TriggerImpl::disable_trigger(world, trigger.clone());
        let disabled: Trigger = world.read_model(trigger.key);
        assert(!disabled.is_enabled, 'Trigger should be disabled');
    }

    #[test]
    fn test_trigger_index_append_multiple() {
        let (mut world, _, _, _, _) = helpers::setup_core();
        let id_1: felt252 = 10;
        let id_2: felt252 = 11;

        let result1 = TriggerImpl::update_triggerIndex(world, TriggerType::PlayerEntersArea, id_1);
        // message: 1st trigger index insert didn't succeed
        assert(result1.is_ok(), '1 trig idx insert nt succ');

        let result2 = TriggerImpl::update_triggerIndex(world, TriggerType::PlayerEntersArea, id_2);
        // message: 2nd trigger index insert didn't succeed
        assert(result2.is_ok(), '2 trig idx insert nt succ');


        let _key: felt252 = TriggerType::PlayerEntersArea.clone().into();
        let index: TriggerIndex = world.read_model(TriggerType::PlayerEntersArea);
        assert(index.trigger_id.len() == 2, 'Two triggers should be indexed');
        assert(index.trigger_id[0] == @id_1, 'First ID should match');
        assert(index.trigger_id[1] == @id_2, 'Second ID should match');
    }

    #[test]
    fn test_evaluate_trigger() {
        let (mut world, _, _, player_1, _) = helpers::setup_core();
        // create room entity 1
        let mut room_entity_1 = EntityImpl::create_entity(world);
        // create room entity 2
        let mut room_entity_2 = EntityImpl::create_entity(world);
        
        // add area component to room entity 1
        let mut area_component_1 = AreaComponent::add_component(world, room_entity_1.inst);
        world.write_model(@area_component_1);
        // add exit component to room entity 1
        let mut exit_component_1 = ExitComponent::add_component(world, room_entity_1.inst);
        // update exit component
        exit_component_1.leads_to = room_entity_2.inst;
        exit_component_1.direction_type = Direction::North;
        world.write_model(@exit_component_1);
        
        // add area component to room entity 2
        let mut area_component_2 = AreaComponent::add_component(world, room_entity_2.inst);
        world.write_model(@area_component_2);
        // add exit component to room entity 2
        let mut exit_component_2 = ExitComponent::add_component(world, room_entity_2.inst);
        // update exit component
        exit_component_2.leads_to = room_entity_1.inst;
        exit_component_2.direction_type = Direction::South;
        world.write_model(@exit_component_2);

        let mut player: Player = caller_as_player(world, player_1);
        player.location = room_entity_2.inst;
        world.write_model(@player);

        let mut player_entity: Entity = EntityImpl::get_entity(@world, @player.inst).unwrap();
        // add player to room entity 2
        player_entity.set_parent(world, @room_entity_2);
        
        // set trigger to room entity 1
        let mut trigger = create_test_trigger(room_entity_1.inst, "TestTrigger", TriggerType::PlayerEntersArea);
        let _result = TriggerImpl::register_trigger(world, trigger.clone());

        // move player to room entity 1
        let mut playerR1: Player = world.read_model(player.inst);
        playerR1.move_to_room(world, room_entity_1.inst);

        let result = TriggerImpl::evaluate_trigger(@world, @trigger);
        if result.is_ok() {
            println!("Trigger jumps successfully");
        };
        assert(result.is_ok(), 'Trigger should jump');

        // move player to room entity 2
        player.move_to_room(world, room_entity_2.inst);
        player_entity.set_parent(world, @room_entity_2);

        let result2 = TriggerImpl::evaluate_trigger(@world, @trigger);
        println!("result2: {:?}", result2);
        if result2.is_err() {
            println!("Trigger does not jump");
        };
        assert(result2.is_err(), 'Trigger should not jump');
    }

    #[test]
    fn test_trigger_with_command() {
        let (mut world, _, _, player_1, _) = helpers::setup_core();
        // create room entity 1
        let mut room_entity_1 = EntityImpl::create_entity(world);
        // create room entity 2
        let mut room_entity_2 = EntityImpl::create_entity(world);
        
        // add area component to room entity 1
        let mut _area_component = AreaComponent::add_component(world, room_entity_1.inst);
        // add exit component to room entity 1
        let mut exit_component_1 = ExitComponent::add_component(world, room_entity_1.inst);
        // update exit component
        exit_component_1.leads_to = room_entity_2.inst;
        exit_component_1.direction_type = Direction::North;
        world.write_model(@exit_component_1);
        
        // add area component to room entity 2
        let mut _area_component = AreaComponent::add_component(world, room_entity_2.inst);
        // add exit component to room entity 2
        let mut exit_component_2 = ExitComponent::add_component(world, room_entity_2.inst);
        // update exit component
        exit_component_2.is_enterable = true;
        exit_component_2.leads_to = room_entity_1.inst;
        exit_component_2.direction_type = Direction::South;
        world.write_model(@exit_component_2);

        let mut player: Player = caller_as_player(world, player_1);
        player.location = room_entity_2.inst;
        world.write_model(@player);

        let mut player_entity: Entity = EntityImpl::get_entity(@world, @player.inst).unwrap();
        // add player to room entity 2
        player_entity.set_parent(world, @room_entity_2);
        
        // set trigger to room entity 1
        let mut trigger = create_test_trigger(room_entity_1.inst, "TestTrigger", TriggerType::PlayerEntersArea);
        let _result = TriggerImpl::register_trigger(world, trigger.clone());

        // set trigger to room entity 2
        let mut trigger = create_test_trigger(room_entity_2.inst, "TestTrigger", TriggerType::PlayerLeavesArea);
        let _result = TriggerImpl::register_trigger(world, trigger.clone());

        // set command
        let mut command = Command {
            command_id: 1,
            text: "go south",
            words: array!["go", "south"],
            token_count: 2,
            action_type: 0,
            tokens: array![
                Token {
                    position: 0,
                    text: "go",
                    token_type: TokenType::Verb,
                    token_value: 1,
                    target: 0,
                },
                Token {
                    position: 1,
                    text: "south",
                    token_type: TokenType::Direction,
                    token_value: 2,
                    target: 0,
                },
            ],
        };

        // execute command
        let result = handle_command(command.clone(), world, player.clone());
        if result.is_ok() {
            println!("Command + trigger jumps successfully");
        };
        assert_eq!(result.is_ok(), true, "CMD + trig should jump");
    }
}