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
struct TriggerIndex {
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
impl TriggerImpl of TriggerTrait {
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
