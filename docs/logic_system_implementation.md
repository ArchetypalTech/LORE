# Design Doc for Logic System Implementation (CAIRO)

## Overview

This document provides some very rough outline suggestions for building a LORE logic system. Not recommended for copying this 1:1- better to build this out step by step, revising this document with insights as you go.

for inspiration / reference:
https://youtu.be/n_vNJ1v6ZIg?t=465
https://youtu.be/0MN5PHkc6mw

## Some primary notes

- (in this order) Start building + firing triggers, then conditions + validation, then effects

- You will want to aim as first goal is out build towards text replacement for inspectables- as this fast tracks you to dynamic interactive content

- Another thing you want to prioritize is a `variables` component, that allows you to store arbitraty named variables.

  - The variables component gives you the flexibility to track arbitrary game state (i.e., a counter for interactions with something, a bool to track state, text strings to replace other text with)
  - You don't necessarily need to separate that into separate component as per the (https://app.excalidraw.com/l/ATtuPg2HGh2/5ZqUcn1XHcu) (int/string)- if you support variable types in one component that would also be fine

- This is focusing mostly on the Cairo implementation- however it is important to take into account that the logic editor needs to be designed and UX thought out on the React end (in the editor)

## Core Components

### 1. Action System

Actions are complete trigger definitions that combine triggers, conditions, and effects. In the editor, these would be the complete trigger definitions that users create.

```cairo
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

// Example usage:
let treasure_room_action = Action {
    key: 123,
    name: "Treasure Room Reward",
    description: "Gives player gold when they enter with key",
    is_enabled: true,

    // The trigger (when)
    trigger: Trigger {
        key: 456,
        name: "Player Enters Treasure Room",
        trigger_type: TriggerType::PlayerEntersArea,
        parameters: array![
            TriggerParameter { name: "area", value: treasure_room_id }
        ],
        is_enabled: true
    },

    // The conditions (if)
    conditions: array![
        Condition {
            key: 789,
            target: player_id,
            component: ComponentType::Player,
            property: "has_item",
            operator: Operator::Equals,
            value: treasure_key_id
        }
    ],

    // The effects (then)
    effects: array![
        Effect {
            key: 101,
            name: "Set Gold Stack",
            effect_type: EffectType::SetStackAmount,
            target: gold_id,
            value: 100,
            is_enabled: true
        },
        Effect {
            key: 101,
            name: "Give Gold",
            effect_type: EffectType::AddToInventory,
            target: player_id,
            value: gold_id,
            is_enabled: true
        },
        Effect {
            key: 102,
            name: "Show Message",
            effect_type: EffectType::ShowMessage,
            target: player_id,
            value: message_id,  // Reference to a message in a message table
            is_enabled: true
        }
    ],

    tags: array!["treasure", "reward", "key"]
};

// Implementation for processing actions
#[generate_trait]
impl ActionImpl of ActionTrait {
    fn process_action(
        self: @Action,
        mut world: WorldStorage,
        context: TriggerContext
    ) -> Result<(), Error> {
        // First check if the trigger matches
        if !self.trigger.matches(context) {
            return Result::Ok(());
        }

        // Then evaluate all conditions
        for condition in self.conditions {
            if !condition.evaluate_condition(world, context) {
                return Result::Ok(()); // Conditions not met, but not an error
            }
        }

        // Finally execute all effects
        for effect in self.effects {
            effect.apply_effect(world, context)?;
        }

        Result::Ok(())
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
```

### 2. Trigger System

The trigger system handles all events that can occur in the game world. Triggers are the "when" part of our logic system.

```cairo
pub struct Trigger {
    #[key]
    pub key: felt252,        // Unique identifier
    pub name: ByteArray,     // Human-readable name
    pub trigger_type: TriggerType,
    pub parameters: Array<TriggerParameter>,
    pub is_enabled: bool,    // For toggling triggers
}

pub struct TriggerParameter {
    pub name: ByteArray,
    pub value: felt252,
}

pub enum TriggerType {
    // Player Triggers
    PlayerEntersArea,
    PlayerLeavesArea,
    PlayerPicksUpItem,
    PlayerDropsItem,
    PlayerSaysPhrase,
    PlayerUsesItem,

    // World Triggers
    ItemStateChanges,
    EntityInteracts,
    ConditionBecomesTrue,
}
```

### 3. Condition System

Conditions are the "if" part of our logic system. They determine whether an action should execute by checking component states and properties.

#### Component Property Access Approaches

You may need to implement the Variables to replace immediate property values (see State Management 2.1) to access the properties of components, or find another solution for a 'reflection' style access to component properties. Needs some exploratory work. (this also applies for 'effects')

1. **Variable Proxy System**

```cairo
// Variables could act as proxies for component properties
pub struct ComponentVariable {
    #[key]
    pub key: felt252,
    pub component_type: ComponentType,
    pub entity_id: felt252,
    pub property_name: ByteArray,
    pub value: felt252,
    pub last_updated: u64,
}

// This allows for:
// - Caching of frequently accessed properties
// - Tracking property changes over time
// - Debugging property access
// - Potential performance optimization
```

2. **Direct Component Access**

```cairo
// Direct access through component traits
#[generate_trait]
impl ComponentPropertyAccess of ComponentPropertyAccessTrait {
    fn get_property(
        self: @Component,
        property_name: ByteArray
    ) -> Option<felt252> {
        match self {
            Component::Inspectable(inspectable) => {
                match property_name {
                    "text" => Option::Some(inspectable.text.into()),
                    "is_visible" => Option::Some(inspectable.is_visible.into()),
                    _ => Option::None
                }
            },
            Component::Container(container) => {
                match property_name {
                    "is_open" => Option::Some(container.is_open.into()),
                    "can_be_opened" => Option::Some(container.can_be_opened.into()),
                    "can_receive_items" => Option::Some(container.can_receive_items.into()),
                    _ => Option::None
                }
            },
            Component::Player(player) => {
                match property_name {
                    "has_item" => Option::Some(player.has_item.into()),
                    "location" => Option::Some(player.location.into()),
                    _ => Option::None
                }
            },
            // ... other component types
        }
    }

    fn set_property(
        mut self: Component,
        property_name: ByteArray,
        value: felt252
    ) -> Result<(), Error> {
        match self {
            Component::Inspectable(mut inspectable) => {
                match property_name {
                    "text" => {
                        inspectable.text = value.into();
                        Result::Ok(())
                    },
                    "is_visible" => {
                        inspectable.is_visible = value.into();
                        Result::Ok(())
                    },
                    _ => Result::Err(Error::PropertyNotFound)
                }
            },
            // ... other component types
        }
    }
}
```

3. **Property Registry**

```cairo
// Registry of known properties per component type
pub struct PropertyRegistry {
    #[key]
    pub component_type: ComponentType,
    pub properties: Array<ComponentProperty>,
}

pub struct ComponentProperty {
    pub name: ByteArray,
    pub property_type: PropertyType,
    pub access_flags: PropertyAccess,
}

// This provides:
// - Documentation of available properties
// - Type safety for property access
// - Access control (read/write permissions)
```

```cairo
pub struct Condition {
    #[key]
    pub key: felt252,        // Unique identifier
    pub target: felt252,     // Entity to check (can be optional for global conditions)
    pub component: ComponentType,  // Which component to check
    pub property: felt252,   // Which property of the component to check
    pub operator: Operator,  // How to compare the values
    pub value: felt252,      // Value to compare against
}

pub enum Operator {
    Equals,
    NotEquals,
    GreaterThan,
    LessThan,
    GreaterThanOrEqualTo,
    LessThanOrEqualTo,
}

pub enum ComponentType {
    Area,
    Exit,
    Container,
    Inspectable,
    InventoryItem,
    Player,
    //etc
}

// Example of how to evaluate conditions against components
#[generate_trait]
impl ConditionImpl of ConditionTrait {
    fn evaluate_condition(
        self: @Condition,
        world: WorldStorage,
        context: TriggerContext
    ) -> bool {
        // Get the target entity's component
        let component = match self.component {
            ComponentType::Area => {
                Component::get_component::<Area>(world, self.target)
            },
            ComponentType::Exit => {
                Component::get_component::<Exit>(world, self.target)
            },
            ComponentType::Container => {
                Component::get_component::<Container>(world, self.target)
            },
            ComponentType::Inspectable => {
                Component::get_component::<Inspectable>(world, self.target)
            },
            ComponentType::InventoryItem => {
                Component::get_component::<InventoryItem>(world, self.target)
            },
            ComponentType::Player => {
                Component::get_component::<Player>(world, self.target)
            },
        };

        // If component doesn't exist, condition fails
        if component.is_none() {
            return false;
        }

        // Get the property value from the component
        let component_value = match self.component {
            ComponentType::Container => {
                let container = component.unwrap();
                match self.property {
                    // Example properties for Container
                    "is_open" => container.is_open.into(),
                    "can_be_opened" => container.can_be_opened.into(),
                    "can_receive_items" => container.can_receive_items.into(),
                    // ... other container properties
                }
            },
            ComponentType::Inspectable => {
                let inspectable = component.unwrap();
                match self.property {
                    // Example properties for Inspectable
                    "is_visible" => inspectable.is_visible.into(),
                    // ... other inspectable properties
                }
            },
            // ... handle other component types
        };

        // Compare values using the operator
        match self.operator {
            Operator::Equals => component_value == self.value,
            Operator::NotEquals => component_value != self.value,
            Operator::GreaterThan => component_value > self.value,
            Operator::LessThan => component_value < self.value,
            Operator::GreaterThanOrEqualTo => component_value >= self.value,
            Operator::LessThanOrEqualTo => component_value <= self.value,
        }
    }
}

// Example usage:
// Check if a container is open
let container_open_condition = Condition {
    key: 123,
    target: container_entity_id,
    component: ComponentType::Container,
    property: "is_open",
    operator: Operator::Equals,
    value: 1, // true
};

// Check if player has an item
let player_has_item_condition = Condition {
    key: 124,
    target: player_entity_id,
    component: ComponentType::Player,
    property: "has_item",
    operator: Operator::Equals,
    value: item_id,
};

// Check if an inspectable is visible
let inspectable_visible_condition = Condition {
    key: 125,
    target: inspectable_entity_id,
    component: ComponentType::Inspectable,
    property: "is_visible",
    operator: Operator::Equals,
    value: 1, // true
};
```

### 4. Effect System

Effects are the actual changes that occur in the game world.

This needs exploratory work as well, how to associate parameters with effects:

Example use cases:

- _You want to be able to set the text of an inspectable_, where do we store the text to be set- how to debug this.
- You want to trigger things we now trigger with an actionmap -> getItem is triggered, so we need to move the item to the inventory etc.

#### Effect Parameterization Approaches

1. **Parameter Storage**

```cairo
// Store effect parameters separately for better debugging and flexibility
pub struct EffectParameter {
    #[key]
    pub key: felt252,
    pub effect_key: felt252,
    pub name: ByteArray,
    pub value: felt252,
    pub value_type: ParameterType,
}

// This allows for:
// - Easy inspection of effect parameters
// - Parameter reuse across effects
// - Runtime parameter modification
// - Better debugging through parameter history
```

2. **Effect Templates**

```cairo
// Predefined effect templates for common operations
pub struct EffectTemplate {
    #[key]
    pub key: felt252,
    pub name: ByteArray,
    pub effect_type: EffectType,
    pub required_parameters: Array<ParameterDefinition>,
    pub optional_parameters: Array<ParameterDefinition>,
}

// Example: SetInspectableText template
let set_text_template = EffectTemplate {
    key: 1,
    name: "Set Inspectable Text",
    effect_type: EffectType::ModifyComponent,
    required_parameters: array![
        ParameterDefinition {
            name: "entity_id",
            param_type: ParameterType::EntityReference,
            description: "The inspectable entity to modify"
        },
        ParameterDefinition {
            name: "text",
            param_type: ParameterType::String,
            description: "The new text to set"
        }
    ],
    optional_parameters: array![]
};
```

3. **Effect Debugging**

```cairo
// Track effect execution for debugging
pub struct EffectExecution {
    #[key]
    pub key: felt252,
    pub effect_key: felt252,
    pub timestamp: u64,
    pub parameters: Array<EffectParameter>,
    pub status: ExecutionStatus,
    pub error_message: Option<ByteArray>,
}

// This provides:
// - Execution history
// - Parameter values at execution time
// - Error tracking
// - Performance monitoring
```

## Implementation Steps

### 1. Core System Implementation

1. **Trigger Registration**
   You can borrow here from the Dictionary implementation

```cairo
#[generate_trait]
impl TriggerImpl of TriggerTrait {
    fn register_trigger(mut world: WorldStorage, trigger: Trigger) {
        // Store trigger in world state
        world.write_model(@trigger);

        // Register trigger handlers
        match trigger.trigger_type {
            TriggerType::PlayerEntersArea => {
                // Register area entry handler
            },
            // ... other trigger types
        }
    }
}
```

2. **Condition Evaluation**
   You can borrow here from the Dictionary implementation

```cairo
#[generate_trait]
impl ConditionImpl of ConditionTrait {
    fn evaluate_condition(
        self: @Condition,
        world: WorldStorage,
        context: TriggerContext
    ) -> bool {
        match self.condition_type {
            ConditionType::PlayerHasItem => {
                // Check if player has item
                let player = context.doer;
                let item_id = self.parameters[0].value;
                // ... implementation
            },
            // ... other condition types
        }
    }
}
```

3. **Action Execution**
   You can borrow here from the Dictionary implementation

```cairo
#[generate_trait]
impl ActionImpl of ActionTrait {
    fn execute_action(
        mut self: Action,
        mut world: WorldStorage,
        context: TriggerContext
    ) -> Result<(), Error> {
        // Check conditions first
        for condition in self.conditions {
            if !condition.evaluate_condition(world, context) {
                return Result::Err(Error::ConditionNotMet);
            }
        }

        // Execute effects
        for effect in self.effects {
            effect.apply_effect(world, context)?;
        }

        Result::Ok(())
    }
}
```

### 2. State Management

1. **Variable System**
   You may or may not need to implement a wrapper for properties of components in order to access them dynamically.

```cairo
pub struct Variable {
    #[key]
    pub key: felt252,
    pub name: ByteArray,
    pub var_type: VariableType,
    pub value: felt252,
    pub is_global: bool,
}

pub enum VariableType {
    Integer,
    Boolean,
    String,
    EntityReference,
    Location,
}
```

### 3. Event Processing

Since we're using Cairo / Dojo- we can store these as models- want to explore the best way to store these for the fastest lookup. Following seems like should cover the basics:

#### Trigger Storage with Dojo Models

For basic trigger storage, we can use a single key model. This works well when we have a unique identifier for each trigger:

```cairo
#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Trigger {
    #[key]
    trigger_id: felt252,  // Unique identifier for this trigger

    trigger_type: TriggerType,
    action_key: felt252,
    is_enabled: bool,
}

// Example usage:
let trigger = Trigger {
    trigger_id: generate_unique_id(),  // e.g., using poseidon hash
    trigger_type: TriggerType::PlayerPicksUpItem,
    action_key: give_reward_action_key,
    is_enabled: true,
};

// Reading a specific trigger
let trigger = world.read_model(trigger_id);
```

#### Trigger Index

You will want to store a mapping of TriggerType -> Trigger;

```cairo
#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct TriggerIndex {
    #[key]
    trigger_type: TriggerType,
    trigger_id: Array<felt252>,
}
```

### Trigger Context System

To make triggers more practical and flexible, we need a standardized way to pass relevant information from the trigger through to conditions and effects. This is achieved through a `TriggerContext` buffer that contains common fields used across different trigger types.

```cairo
#[derive(Copy, Drop, Serde)]
pub struct TriggerContext {
    // The entity that triggered the action (usually the player)
    pub doer: felt252,

    // Primary target of the action (e.g., item being picked up, area being entered)
    pub target1: felt252,

    // Secondary target (e.g., container being opened, item being used on)
    pub target2: felt252,

    // Inventory object involved (e.g., item being moved to/from inventory)
    pub inventory_object: felt252,
}

// Example usage with different trigger types:
// 1. Player picks up item
let pickup_context = TriggerContext {
    doer: player_id,
    target1: item_id,  // The item being picked up
    target2: 0,        // Not used
    inventory_object: item_id,  // Same as target1 in this case
};

// 2. Player uses item on object
let use_context = TriggerContext {
    doer: player_id,
    target1: item_id,     // The item being used
    target2: object_id,   // The object being used on
    inventory_object: item_id,
};

// 3. Player enters area
let enter_context = TriggerContext {
    doer: player_id,
    target1: area_id,     // The area being entered
    target2: 0,           // Not used
    inventory_object: 0,  // Not used
};
```

This context buffer is then used throughout the trigger system:

1. When a trigger fires, it creates a `TriggerContext` with relevant information
2. Conditions can access this context to evaluate their conditions
3. Effects can use the context to know what entities to act upon

For example, a condition checking if a player has picked up a specific item:

```cairo
// Condition implementation using context
fn evaluate_condition(
    self: @Condition,
    world: WorldStorage,
    context: TriggerContext
) -> bool {
    // For a "player has item" condition
    if self.component == ComponentType::Player && self.property == "has_item" {
        // Check if the target1 (item) in the context matches our condition value
        return context.target1 == self.value;
    }

    // For other condition types...
    // ...
}
```

And an effect that gives an item to the player:

```cairo
// Effect implementation using context
fn apply_effect(
    self: @Effect,
    world: WorldStorage,
    context: TriggerContext
) -> Result<(), Error> {
    // For a "give item" effect
    if self.effect_type == EffectType::GiveItemToPlayer {
        // Use the doer (player) and target1 (item) from context
        let player = context.doer;
        let item = context.target1;

        // Apply the effect...
        // ...
    }

    // For other effect types...
    // ...
}
```
