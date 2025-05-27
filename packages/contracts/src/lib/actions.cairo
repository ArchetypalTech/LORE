use dojo::{world::WorldStorage, model::ModelStorage};

use lore::{
    components::{
        area::{AreaComponent},
        exit::{ExitComponent},
        inspectable::{InspectableComponent},
        inventoryItem::{InventoryItemComponent},
        container::{ContainerComponent},
        player::{PlayerComponent},
    },
    lib::{
        utils::ByteArrayTraitExt,
        variable_property::{VariablePropertyImp},
        trigger::{Trigger,TriggerContext, TriggerImpl},
        condition::{Condition, ConditionImpl},
        effect::{Effect, EffectImpl},
    },
    constants::{errors::Error},
};

#[derive(Clone, Drop, Serde, Debug, Introspect)]
#[dojo::model]
pub struct Action {
    #[key]
    pub key: felt252,        // Unique identifier
    pub name: ByteArray,     // Human-readable name for the editor
    pub description: ByteArray, // Optional description
    pub is_enabled: bool,    // For toggling the entire action

    // The complete trigger definition
    pub trigger: Array<Trigger>,    // When this action can occur
    pub conditions: Array<Condition>, // What must be true
    pub effects: Array<Effect>, // What happens when triggered

    // Optional metadata for the editor
    pub tags: Array<ByteArray>,  // For searching/filtering
}

// Implementation for processing actions
#[generate_trait]
impl ActionImpl of ActionTrait {
    fn process_action(
        self: @Action,
        mut world: WorldStorage,
        context: TriggerContext
    ) -> (Result<(), Error>, Result<(), Error>, Result<(), Error>) {
        // Trigger
        let mut result_t: Result<(), Error> = Result::Ok(());
        //Conditions
        let mut result_c: Result<(), Error> = Result::Ok(());
        //Effects
        let mut result_e: Result<(), Error> = Result::Ok(());
        // First check if the trigger/s are valid
        for trigger in self.trigger.clone() {
            let result_opt = TriggerImpl::evaluate_trigger(world, @trigger);
            if result_opt.is_err() {
                result_t = result_opt;
                break;
            }
        };

        // Then evaluate all conditions
        for condition in self.conditions.clone() {
            if !condition.evaluate_condition(@world, context) {
                result_c = Result::Ok(()); // Conditions not met, but not an error
            }
        };

        // Finally execute all effects
        for effect in self.effects.clone() {
            let result_pos = effect.apply_effect(world, context);
            if result_pos.is_err() {
                result_e = result_pos;
            }
        };

        (result_t, result_c, result_e)
    }

    fn enable_action(mut self: Action, mut world: WorldStorage) {
        self.is_enabled = true;
        world.write_model(@self);
    }

    fn disable_action(mut self: Action, mut world: WorldStorage) {
        self.is_enabled = false;
        world.write_model(@self);
    }
}