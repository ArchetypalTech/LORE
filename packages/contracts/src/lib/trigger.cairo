use dojo::{world::{WorldStorage}, model::ModelStorage};

use lore::{constants::errors::Error, lib::{entity::{Entity, EntityImpl}}};

#[derive(Clone, Drop, Serde, Debug)]
#[dojo::model]
pub struct Trigger {
    #[key]
    pub key: felt252, // Unique identifier
    pub name: ByteArray, // Human-readable name
    // properties
    pub trigger_type: TriggerType, // The type of trigger
    pub entity_attachedTo: Entity, // Entity this trigger is attached to
    pub parameters: Array<TriggerParameter>, // Trigger parameters
    pub is_enabled: bool, // Whether the trigger is enabled
}

#[derive(Clone, Drop, Serde)]
#[dojo::model]
pub struct TriggerIndex {
    #[key]
    trigger_type: TriggerType,
    trigger_id: Array<felt252>,
}

#[derive(Copy, Drop, Serde)]
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

#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
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
        let trigger_index: TriggerIndex = world.read_model(*trigger_type);
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

                let trigger_index = TriggerIndex { trigger_type, trigger_id: trigger_ids };
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
}


#[cfg(test)]
mod tests {
    use super::*;
    use dojo::{model::ModelStorage};
    use lore::tests::helpers;
    use lore::lib::{entity::{Entity, EntityImpl}, trigger::{Trigger,TriggerType, TriggerImpl}};

    fn create_test_trigger(key: felt252, nameT: ByteArray, trigger_type: TriggerType, entity: Entity) -> Trigger {
        Trigger {
            key,
            name: nameT,
            trigger_type,
            entity_attachedTo: entity,
            parameters: array![],
            is_enabled: false,
        }
    }

    #[test]
    fn test_trigger_register_and_index() {
        let (mut world, _, _, _, _) = helpers::setup_core();

        // Create entity
        let mut player = EntityImpl::create_entity(world);
        player.name = "player";
        world.write_model(@player);

        let trigger = create_test_trigger(1, "TestTrigger",TriggerType::PlayerEntersArea, player);

        let result = TriggerImpl::register_trigger(world, trigger.clone());
        assert(result.is_ok(), 'Trig not register successfully');

        let stored: Trigger = world.read_model(trigger.key);
        assert(stored.key == 1, 'Trigger key should match');
        assert(stored.name == "TestTrigger", 'Trigger name should match');

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
        let trigger = create_test_trigger(2, long_name, TriggerType::PlayerLeavesArea, player);
        world.write_model(@trigger);

        let result = TriggerImpl::register_trigger(world, trigger);
        assert(result.is_err(), 'Trig name too long should fail');
    }

    #[test]
    fn test_trigger_enable_disable() {
        let (mut world, _, _, _, _) = helpers::setup_core();
        // Create entity
        let mut player = EntityImpl::create_entity(world);
        player.name = "player";
        world.write_model(@player);

        // Create trigger
        let trigger = create_test_trigger(3, "TestTrigger", TriggerType::PlayerLeavesArea, player);

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

        let index: TriggerIndex = world.read_model(TriggerType::PlayerEntersArea);
        assert(index.trigger_id.len() == 2, 'Two triggers should be indexed');
        assert(index.trigger_id[0] == @id_1, 'First ID should match');
        assert(index.trigger_id[1] == @id_2, 'Second ID should match');
    }
}