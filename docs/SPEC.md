# LORE Shinigami Refactoring Technical Specification
# Implementation-Ready Architectural Blueprint

**Document Version:** 1.0  
**Date:** 2025-06-24  
**Status:** Draft - Ready for Implementation  
**Based on:** SHINIGAMI_REFACTOR_PRD.md v1.0

---

## Overview

This technical specification provides implementation-ready architectural blueprints for refactoring LORE's Cairo smart contracts to the Shinigami Design Pattern. This document defines exact module responsibilities, function signatures, data structures, and implementation guidelines.

**Critical Constraint:** All external interfaces (`prompt.cairo` and `designer.cairo`) must remain byte-for-byte identical to preserve frontend compatibility.

---

## Architecture Overview

### Shinigami 6-Layer Architecture
```
┌─────────────────────────────────────────────────────────────┐
│ Layer 6: SYSTEMS (Game Modes & Configuration)              │
├─────────────────────────────────────────────────────────────┤
│ Layer 5: COMPONENTS (Business Logic Orchestration)         │
├─────────────────────────────────────────────────────────────┤
│ Layer 4: MODELS (Pure Data Persistence)                    │
├─────────────────────────────────────────────────────────────┤
│ Layer 3: TYPES (Entry Points & Routing)                    │
├─────────────────────────────────────────────────────────────┤
│ Layer 2: ELEMENTS (Individual Entity Behaviors)            │
├─────────────────────────────────────────────────────────────┤
│ Layer 1: HELPERS (Pure Utility Functions)                  │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow Architecture
```
Frontend → Systems → Components → Elements → Models
                  ↓              ↓         ↓
                Types ←─── Helpers ←─── Storage
```

---

## Layer 1: Helpers (Pure Utilities)

### Module: `helpers/text_utils.cairo`

**Purpose:** Stateless text processing and dictionary operations

**Dependencies:** None (pure utilities)

**Public Functions:**
```cairo
// Dictionary Operations
fn get_word_token(word: ByteArray) -> Option<TokenType>
fn add_word_mapping(word: ByteArray, token_type: TokenType, value: u32) -> Result<(), DictionaryError>
fn get_token_value(token_type: TokenType) -> u32

// Text Processing
fn normalize_text(input: ByteArray) -> ByteArray
fn split_words(text: ByteArray) -> Array<ByteArray>
fn clean_input(text: ByteArray) -> ByteArray
fn is_valid_command(text: ByteArray) -> bool

// Token Classification
fn classify_word(word: ByteArray) -> TokenClassification
fn get_context_matches(words: Array<ByteArray>, context: EntityContext) -> Array<EntityMatch>
```

**Data Structures:**
```cairo
struct TokenClassification {
    token_type: TokenType,
    confidence: u8,
    alternatives: Array<TokenType>
}

struct EntityMatch {
    entity_inst: u32,
    match_type: MatchType,
    confidence: u8
}

struct EntityContext {
    player_location: u32,
    visible_entities: Array<u32>,
    inventory_items: Array<u32>
}
```

**Error Handling:** Returns `DictionaryError` for dictionary operations, never panics

---

### Module: `helpers/random_utils.cairo`

**Purpose:** Deterministic random number generation for game mechanics

**Dependencies:** None

**Public Functions:**
```cairo
fn generate_seed(base: felt252, salt: u64) -> u64
fn random_range(seed: u64, min: u32, max: u32) -> u32
fn random_choice<T>(seed: u64, options: Array<T>) -> T
fn weighted_choice<T>(seed: u64, options: Array<T>, weights: Array<u32>) -> T
fn shuffle_array<T>(seed: u64, array: Array<T>) -> Array<T>
```

---

### Module: `helpers/property_manager.cairo`

**Purpose:** Dynamic property system management

**Dependencies:** None

**Public Functions:**
```cairo
fn register_property(component_type: ComponentType, property_name: ByteArray, property_type: PropertyType) -> Result<(), PropertyError>
fn get_property_registry(component_type: ComponentType) -> Array<PropertyDefinition>
fn validate_property_value(property_type: PropertyType, value: felt252) -> bool
fn serialize_property(property_type: PropertyType, value: felt252) -> ByteArray
fn deserialize_property(property_type: PropertyType, data: ByteArray) -> Result<felt252, PropertyError>
```

**Data Structures:**
```cairo
struct PropertyDefinition {
    name: ByteArray,
    property_type: PropertyType,
    default_value: felt252,
    constraints: PropertyConstraints
}

struct PropertyConstraints {
    min_value: Option<felt252>,
    max_value: Option<felt252>,
    allowed_values: Array<felt252>
}
```

---

### Module: `helpers/validation.cairo`

**Purpose:** Input validation and sanitization

**Dependencies:** None

**Public Functions:**
```cairo
fn validate_entity_inst(inst: u32) -> bool
fn validate_command_input(input: ByteArray) -> Result<ByteArray, ValidationError>
fn validate_entity_name(name: ByteArray) -> Result<(), ValidationError>
fn sanitize_user_input(input: ByteArray) -> ByteArray
fn check_rate_limits(caller: ContractAddress, action: ActionType) -> Result<(), RateLimitError>
```

---

### Module: `helpers/data_packer.cairo`

**Purpose:** Storage optimization and data serialization

**Dependencies:** None

**Public Functions:**
```cairo
fn pack_entity_data(entity: EntityData) -> felt252
fn unpack_entity_data(packed: felt252) -> EntityData
fn pack_relationship_data(parent: u32, child: u32, relationship_type: RelationshipType) -> felt252
fn unpack_relationship_data(packed: felt252) -> (u32, u32, RelationshipType)
fn calculate_storage_cost(data_size: u32) -> u32
```

---

## Layer 2: Elements (Individual Entity Behaviors)

### Module: `elements/entities/player.cairo`

**Purpose:** Player-specific behaviors and capabilities

**Dependencies:** `helpers/validation`, `types/entity_type`

**Public Functions:**
```cairo
fn move_player(player_inst: u32, target_area: u32) -> Result<MoveResult, PlayerError>
fn get_player_context(player_inst: u32) -> PlayerContext
fn add_to_story_log(player_inst: u32, message: ByteArray) -> Result<(), PlayerError>
fn get_story_log(player_inst: u32, limit: u32) -> Array<ByteArray>
fn set_debug_mode(player_inst: u32, enabled: bool) -> Result<(), PlayerError>
fn check_player_permissions(player_inst: u32, action: ActionType) -> bool
```

**Data Structures:**
```cairo
struct PlayerContext {
    current_area: u32,
    visible_entities: Array<u32>,
    accessible_exits: Array<u32>,
    inventory_container: u32
}

struct MoveResult {
    success: bool,
    new_location: u32,
    movement_message: ByteArray,
    triggered_actions: Array<u32>
}
```

**Error Handling:** Returns `PlayerError` enum with specific error types

---

### Module: `elements/entities/area.cairo`

**Purpose:** Area/room specific behaviors

**Dependencies:** `helpers/validation`, `types/entity_type`

**Public Functions:**
```cairo
fn enter_area(area_inst: u32, player_inst: u32) -> Result<AreaEntry, AreaError>
fn exit_area(area_inst: u32, player_inst: u32) -> Result<(), AreaError>
fn get_area_description(area_inst: u32, player_inst: u32) -> ByteArray
fn get_area_contents(area_inst: u32) -> AreaContents
fn check_spawn_eligibility(area_inst: u32) -> bool
fn trigger_area_events(area_inst: u32, event_type: AreaEventType) -> Array<u32>
```

**Data Structures:**
```cairo
struct AreaEntry {
    description: ByteArray,
    contents: AreaContents,
    available_actions: Array<ActionType>,
    triggered_events: Array<u32>
}

struct AreaContents {
    entities: Array<u32>,
    exits: Array<u32>,
    items: Array<u32>,
    containers: Array<u32>
}
```

---

### Module: `elements/entities/item.cairo`

**Purpose:** Item-specific behaviors and interactions

**Dependencies:** `helpers/validation`, `types/entity_type`

**Public Functions:**
```cairo
fn use_item(item_inst: u32, user_inst: u32, target: Option<u32>) -> Result<UseResult, ItemError>
fn pickup_item(item_inst: u32, picker_inst: u32) -> Result<(), ItemError>
fn drop_item(item_inst: u32, dropper_inst: u32, location: u32) -> Result<(), ItemError>
fn get_item_actions(item_inst: u32) -> Array<ActionType>
fn check_item_usability(item_inst: u32, user_inst: u32) -> UsabilityCheck
```

**Data Structures:**
```cairo
struct UseResult {
    success: bool,
    result_message: ByteArray,
    state_changes: Array<StateChange>,
    triggered_effects: Array<u32>
}

struct UsabilityCheck {
    can_use: bool,
    requirements: Array<Requirement>,
    restrictions: Array<Restriction>
}
```

---

### Module: `elements/entities/container.cairo`

**Purpose:** Container storage and management behaviors

**Dependencies:** `helpers/validation`, `types/entity_type`

**Public Functions:**
```cairo
fn add_to_container(container_inst: u32, item_inst: u32) -> Result<(), ContainerError>
fn remove_from_container(container_inst: u32, item_inst: u32) -> Result<(), ContainerError>
fn get_container_contents(container_inst: u32) -> Array<u32>
fn check_container_capacity(container_inst: u32, item_inst: u32) -> bool
fn search_container(container_inst: u32, query: ByteArray) -> Array<u32>
```

---

### Module: `elements/entities/exit.cairo`

**Purpose:** Exit/passage behaviors and navigation

**Dependencies:** `helpers/validation`, `types/direction_type`

**Public Functions:**
```cairo
fn attempt_passage(exit_inst: u32, traveler_inst: u32) -> Result<PassageResult, ExitError>
fn get_exit_description(exit_inst: u32, observer_inst: u32) -> ByteArray
fn check_passage_requirements(exit_inst: u32, traveler_inst: u32) -> RequirementCheck
fn get_destination(exit_inst: u32) -> u32
fn is_bidirectional(exit_inst: u32) -> bool
```

**Data Structures:**
```cairo
struct PassageResult {
    success: bool,
    destination: u32,
    travel_message: ByteArray,
    triggered_actions: Array<u32>
}

struct RequirementCheck {
    can_pass: bool,
    blocking_conditions: Array<u32>,
    required_items: Array<u32>
}
```

---

### Module: `elements/descriptors/inspectable.cairo`

**Purpose:** Description and examination behaviors

**Dependencies:** `helpers/random_utils`, `helpers/text_utils`

**Public Functions:**
```cairo
fn inspect_entity(entity_inst: u32, inspector_inst: u32, action_type: InspectionType) -> ByteArray
fn get_random_description(entity_inst: u32, description_type: DescriptionType) -> ByteArray
fn check_inspection_history(entity_inst: u32, inspector_inst: u32) -> InspectionHistory
fn add_contextual_description(entity_inst: u32, context: InspectionContext) -> ByteArray
```

**Data Structures:**
```cairo
struct InspectionHistory {
    first_inspection: bool,
    inspection_count: u32,
    last_inspection_time: u64
}

struct InspectionContext {
    inspector_location: u32,
    time_of_day: u32,
    inspector_state: PlayerState
}
```

---

### Module: `elements/relationships/spatial.cairo`

**Purpose:** Spatial relationship behaviors

**Dependencies:** `helpers/validation`

**Public Functions:**
```cairo
fn establish_parent_child(parent_inst: u32, child_inst: u32) -> Result<(), RelationshipError>
fn remove_parent_child(parent_inst: u32, child_inst: u32) -> Result<(), RelationshipError>
fn get_children(parent_inst: u32) -> Array<u32>
fn get_parent(child_inst: u32) -> Option<u32>
fn get_siblings(entity_inst: u32) -> Array<u32>
fn validate_relationship(parent_inst: u32, child_inst: u32) -> bool
fn check_circular_dependency(parent_inst: u32, child_inst: u32) -> bool
```

---

## Layer 3: Types (Entry Points & Routing)

### Module: `types/entity_type.cairo`

**Purpose:** Entity classification and type routing

**Dependencies:** None

**Public Types:**
```cairo
#[derive(Drop, Serde)]
enum EntityType {
    Player,
    Area,
    Item,
    Container,
    Exit,
    Inspectable,
    Trigger,
    Condition,
    Effect,
    Action
}

#[derive(Drop, Serde)]
enum ComponentType {
    PlayerComponent,
    AreaComponent,
    ItemComponent,
    ContainerComponent,
    ExitComponent,
    InspectableComponent
}
```

**Public Functions:**
```cairo
fn get_entity_type(entity_inst: u32) -> Result<EntityType, TypeError>
fn get_component_types(entity_type: EntityType) -> Array<ComponentType>
fn validate_type_compatibility(entity_type: EntityType, component_type: ComponentType) -> bool
```

---

### Module: `types/command_type.cairo`

**Purpose:** Command classification and routing

**Dependencies:** None

**Public Types:**
```cairo
#[derive(Drop, Serde)]
enum CommandType {
    Movement(DirectionType),
    Interaction(InteractionType),
    Inspection(InspectionType),
    Inventory(InventoryType),
    System(SystemType),
    Debug(DebugType)
}

#[derive(Drop, Serde)]
enum InteractionType {
    Take,
    Drop,
    Use,
    Open,
    Close,
    Enter,
    Exit
}
```

**Public Functions:**
```cairo
fn parse_command_type(tokens: Array<TokenType>) -> Result<CommandType, ParseError>
fn get_required_parameters(command_type: CommandType) -> Array<ParameterType>
fn validate_command_context(command_type: CommandType, context: PlayerContext) -> bool
```

---

### Module: `types/action_type.cairo`

**Purpose:** Action system type definitions

**Dependencies:** None

**Public Types:**
```cairo
#[derive(Drop, Serde)]
enum TriggerType {
    OnEnter,
    OnExit,
    OnInteract,
    OnInspect,
    OnUse,
    OnTimer,
    OnCondition
}

#[derive(Drop, Serde)]
enum ConditionType {
    HasItem,
    InLocation,
    PropertyEquals,
    TimeRange,
    RandomChance,
    Custom
}

#[derive(Drop, Serde)]
enum EffectType {
    ModifyProperty,
    AddItem,
    RemoveItem,
    MoveEntity,
    SendMessage,
    TriggerAction
}
```

---

### Module: `types/direction_type.cairo`

**Purpose:** Movement and direction handling

**Dependencies:** None

**Public Types:**
```cairo
#[derive(Drop, Serde)]
enum DirectionType {
    North,
    South,
    East,
    West,
    Northeast,
    Northwest,
    Southeast,
    Southwest,
    Up,
    Down,
    In,
    Out
}
```

**Public Functions:**
```cairo
fn parse_direction(word: ByteArray) -> Option<DirectionType>
fn get_opposite_direction(direction: DirectionType) -> DirectionType
fn get_direction_vector(direction: DirectionType) -> (i32, i32, i32)
```

---

## Layer 4: Models (Pure Data Persistence)

### Module: `models/player.cairo`

**Purpose:** Player state data persistence

**Dependencies:** `dojo::database::schema`

**Dojo Model:**
```cairo
#[derive(Model, Drop, Serde)]
struct Player {
    #[key]
    inst: u32,
    address: ContractAddress,
    name: ByteArray,
    current_area: u32,
    personal_container: u32,
    debug_mode: bool,
    story_log: Array<ByteArray>,
    created_at: u64,
    last_active: u64
}
```

**Storage Functions:**
```cairo
fn get_player(world: IWorldDispatcher, inst: u32) -> Player
fn set_player(world: IWorldDispatcher, player: Player)
fn update_player_location(world: IWorldDispatcher, inst: u32, new_location: u32)
fn add_story_entry(world: IWorldDispatcher, inst: u32, message: ByteArray)
```

---

### Module: `models/area.cairo`

**Purpose:** Area/room state data persistence

**Dependencies:** `dojo::database::schema`

**Dojo Model:**
```cairo
#[derive(Model, Drop, Serde)]
struct Area {
    #[key]
    inst: u32,
    name: ByteArray,
    is_spawn_point: bool,
    capacity: u32,
    environment_type: EnvironmentType,
    ambient_properties: felt252
}
```

---

### Module: `models/item.cairo`

**Purpose:** Item state data persistence

**Dependencies:** `dojo::database::schema`

**Dojo Model:**
```cairo
#[derive(Model, Drop, Serde)]
struct Item {
    #[key]
    inst: u32,
    name: ByteArray,
    item_type: ItemType,
    weight: u32,
    value: u32,
    durability: u32,
    max_durability: u32,
    properties: felt252
}
```

---

### Module: `models/container.cairo`

**Purpose:** Container state data persistence

**Dependencies:** `dojo::database::schema`

**Dojo Model:**
```cairo
#[derive(Model, Drop, Serde)]
struct Container {
    #[key]
    inst: u32,
    name: ByteArray,
    capacity: u32,
    current_weight: u32,
    max_weight: u32,
    container_type: ContainerType,
    access_restrictions: felt252
}
```

---

### Module: `models/exit.cairo`

**Purpose:** Exit/passage state data persistence

**Dependencies:** `dojo::database::schema`

**Dojo Model:**
```cairo
#[derive(Model, Drop, Serde)]
struct Exit {
    #[key]
    inst: u32,
    name: ByteArray,
    leads_to: u32,
    direction_type: DirectionType,
    is_enterable: bool,
    passage_requirements: Array<u32>,
    passage_restrictions: Array<u32>
}
```

---

### Module: `models/inspectable.cairo`

**Purpose:** Inspectable content data persistence

**Dependencies:** `dojo::database::schema`

**Dojo Model:**
```cairo
#[derive(Model, Drop, Serde)]
struct Inspectable {
    #[key]
    inst: u32,
    descriptions: Array<ByteArray>,
    first_time_description: ByteArray,
    repeat_description: ByteArray,
    action_mappings: Array<ActionMapping>
}

struct ActionMapping {
    action_type: ActionType,
    response: ByteArray
}
```

---

### Module: `models/entity.cairo`

**Purpose:** Core entity data persistence

**Dependencies:** `dojo::database::schema`

**Dojo Model:**
```cairo
#[derive(Model, Drop, Serde)]
struct Entity {
    #[key]
    inst: u32,
    name: ByteArray,
    alt_names: Array<ByteArray>,
    entity_type: EntityType,
    component_types: Array<ComponentType>,
    actions_keys: Array<u32>,
    created_at: u64,
    modified_at: u64
}
```

---

### Module: `models/relationships.cairo`

**Purpose:** Entity relationship data persistence

**Dependencies:** `dojo::database::schema`

**Dojo Models:**
```cairo
#[derive(Model, Drop, Serde)]
struct ParentToChildren {
    #[key]
    parent_inst: u32,
    children: Array<u32>
}

#[derive(Model, Drop, Serde)]
struct ChildToParent {
    #[key]
    child_inst: u32,
    parent_inst: u32,
    relationship_type: RelationshipType
}
```

---

### Module: `models/action_system.cairo`

**Purpose:** Action system data persistence

**Dependencies:** `dojo::database::schema`

**Dojo Models:**
```cairo
#[derive(Model, Drop, Serde)]
struct Trigger {
    #[key]
    inst: u32,
    trigger_type: TriggerType,
    entity_inst: u32,
    conditions: Array<u32>,
    effects: Array<u32>,
    is_active: bool
}

#[derive(Model, Drop, Serde)]
struct Condition {
    #[key]
    inst: u32,
    condition_type: ConditionType,
    parameters: felt252,
    expected_value: felt252
}

#[derive(Model, Drop, Serde)]
struct Effect {
    #[key]
    inst: u32,
    effect_type: EffectType,
    target_entity: u32,
    parameters: felt252,
    value: felt252
}
```

---

## Layer 5: Components (Business Logic Orchestration)

### Module: `components/command_processor.cairo`

**Purpose:** Command parsing and routing orchestration

**Dependencies:** `elements/entities/*`, `types/command_type`, `helpers/text_utils`

**Public Functions:**
```cairo
fn process_command(player_inst: u32, command_text: ByteArray) -> Result<CommandResult, ProcessingError>
fn parse_natural_language(text: ByteArray, context: PlayerContext) -> Result<ParsedCommand, ParseError>
fn route_command(parsed_command: ParsedCommand, player_inst: u32) -> Result<CommandResult, RoutingError>
fn validate_command_permissions(command: ParsedCommand, player_inst: u32) -> bool
fn execute_command_chain(commands: Array<ParsedCommand>, player_inst: u32) -> Array<CommandResult>
```

**Data Structures:**
```cairo
struct ParsedCommand {
    command_type: CommandType,
    primary_target: Option<u32>,
    secondary_target: Option<u32>,
    parameters: Array<felt252>,
    confidence: u8
}

struct CommandResult {
    success: bool,
    message: ByteArray,
    state_changes: Array<StateChange>,
    triggered_actions: Array<u32>
}
```

---

### Module: `components/entity_manager.cairo`

**Purpose:** Entity lifecycle and relationship management

**Dependencies:** `models/*`, `elements/relationships/spatial`

**Public Functions:**
```cairo
fn create_entity(entity_type: EntityType, name: ByteArray, properties: EntityProperties) -> Result<u32, EntityError>
fn delete_entity(entity_inst: u32) -> Result<(), EntityError>
fn add_component_to_entity(entity_inst: u32, component_type: ComponentType, data: felt252) -> Result<(), EntityError>
fn remove_component_from_entity(entity_inst: u32, component_type: ComponentType) -> Result<(), EntityError>
fn establish_relationship(parent_inst: u32, child_inst: u32, relationship_type: RelationshipType) -> Result<(), EntityError>
fn get_entity_hierarchy(root_inst: u32) -> EntityHierarchy
```

**Data Structures:**
```cairo
struct EntityProperties {
    initial_location: Option<u32>,
    component_data: Array<ComponentData>,
    relationships: Array<RelationshipDef>
}

struct EntityHierarchy {
    root: u32,
    children: Array<EntityHierarchy>,
    depth: u32
}
```

---

### Module: `components/text_parser.cairo`

**Purpose:** Natural language processing orchestration

**Dependencies:** `helpers/text_utils`, `types/command_type`

**Public Functions:**
```cairo
fn tokenize_input(text: ByteArray) -> Array<Token>
fn resolve_entity_references(tokens: Array<Token>, context: PlayerContext) -> Array<ResolvedToken>
fn build_command_structure(resolved_tokens: Array<ResolvedToken>) -> Result<CommandStructure, ParseError>
fn handle_ambiguous_references(ambiguities: Array<Ambiguity>, context: PlayerContext) -> Array<Resolution>
```

**Data Structures:**
```cairo
struct Token {
    word: ByteArray,
    token_type: TokenType,
    position: u32,
    confidence: u8
}

struct ResolvedToken {
    token: Token,
    entity_reference: Option<u32>,
    alternatives: Array<u32>
}

struct CommandStructure {
    verb: ResolvedToken,
    direct_object: Option<ResolvedToken>,
    indirect_object: Option<ResolvedToken>,
    prepositions: Array<ResolvedToken>,
    modifiers: Array<ResolvedToken>
}
```

---

### Module: `components/action_system.cairo`

**Purpose:** Trigger-condition-effect system orchestration

**Dependencies:** `models/action_system`, `elements/entities/*`

**Public Functions:**
```cairo
fn register_trigger(entity_inst: u32, trigger_type: TriggerType, conditions: Array<u32>, effects: Array<u32>) -> Result<u32, ActionError>
fn evaluate_trigger(trigger_inst: u32, context: TriggerContext) -> bool
fn execute_effects(effects: Array<u32>, context: EffectContext) -> Array<EffectResult>
fn check_conditions(conditions: Array<u32>, context: ConditionContext) -> bool
fn create_condition_chain(conditions: Array<ConditionDef>, logic_operator: LogicOperator) -> Result<u32, ActionError>
```

**Data Structures:**
```cairo
struct TriggerContext {
    triggering_entity: u32,
    target_entity: Option<u32>,
    player_inst: u32,
    action_type: ActionType,
    timestamp: u64
}

struct EffectContext {
    executor: u32,
    target: u32,
    parameters: Array<felt252>
}

struct ConditionContext {
    evaluator: u32,
    target: Option<u32>,
    current_state: GameState
}
```

---

### Module: `components/movement_system.cairo`

**Purpose:** Navigation and movement orchestration

**Dependencies:** `elements/entities/player`, `elements/entities/area`, `elements/entities/exit`

**Public Functions:**
```cairo
fn attempt_movement(player_inst: u32, direction: DirectionType) -> Result<MovementResult, MovementError>
fn find_valid_exits(area_inst: u32, player_inst: u32) -> Array<ExitOption>
fn calculate_movement_cost(from_area: u32, to_area: u32, player_inst: u32) -> u32
fn handle_movement_events(movement_result: MovementResult) -> Array<TriggeredEvent>
```

**Data Structures:**
```cairo
struct MovementResult {
    success: bool,
    from_area: u32,
    to_area: u32,
    path_taken: Array<u32>,
    movement_time: u32,
    events_triggered: Array<u32>
}

struct ExitOption {
    exit_inst: u32,
    direction: DirectionType,
    destination: u32,
    can_pass: bool,
    restrictions: Array<Restriction>
}
```

---

### Module: `components/inventory_system.cairo`

**Purpose:** Item and inventory management orchestration

**Dependencies:** `elements/entities/item`, `elements/entities/container`

**Public Functions:**
```cairo
fn transfer_item(item_inst: u32, from_container: u32, to_container: u32) -> Result<TransferResult, InventoryError>
fn check_inventory_capacity(container_inst: u32, item_inst: u32) -> CapacityCheck
fn organize_inventory(container_inst: u32, sort_type: SortType) -> Result<(), InventoryError>
fn search_inventory(container_inst: u32, search_criteria: SearchCriteria) -> Array<u32>
```

**Data Structures:**
```cairo
struct TransferResult {
    success: bool,
    item_moved: u32,
    from_location: u32,
    to_location: u32,
    weight_change: i32
}

struct CapacityCheck {
    can_fit: bool,
    current_capacity: u32,
    max_capacity: u32,
    weight_limit_reached: bool
}
```

---

### Module: `components/interaction_system.cairo`

**Purpose:** Entity interaction and inspection orchestration

**Dependencies:** `elements/descriptors/inspectable`, `elements/entities/*`

**Public Functions:**
```cairo
fn handle_interaction(actor_inst: u32, target_inst: u32, interaction_type: InteractionType) -> Result<InteractionResult, InteractionError>
fn inspect_entity(inspector_inst: u32, target_inst: u32, inspection_type: InspectionType) -> InspectionResult
fn get_available_interactions(actor_inst: u32, target_inst: u32) -> Array<InteractionOption>
fn execute_interaction_chain(interactions: Array<PlannedInteraction>) -> Array<InteractionResult>
```

**Data Structures:**
```cairo
struct InteractionResult {
    success: bool,
    description: ByteArray,
    state_changes: Array<StateChange>,
    follow_up_options: Array<InteractionOption>
}

struct InspectionResult {
    description: ByteArray,
    detailed_info: Array<DetailedInfo>,
    available_actions: Array<ActionType>
}
```

---

## Layer 6: Systems (Game Modes & Entry Points)

### Module: `systems/game_engine.cairo`

**Purpose:** Main game entry point - replaces `prompt.cairo` while preserving interface

**Dependencies:** `components/command_processor`, `components/action_system`

**Critical Preserved Interface:**
```cairo
#[external(v0)]
fn prompt(ref self: ContractState, cmd: ByteArray)
```

**Implementation Strategy:**
```cairo
fn prompt(ref self: ContractState, cmd: ByteArray) {
    // 1. Get caller's player instance
    let player_inst = get_player_instance(get_caller_address());
    
    // 2. Process command through new component system
    let result = process_command(player_inst, cmd);
    
    // 3. Handle action triggers
    handle_triggered_actions(result.triggered_actions);
    
    // 4. Update game state and emit events (maintaining exact same behavior as original)
    update_game_state_and_emit_events(result);
}
```

**Internal Functions:**
```cairo
fn get_player_instance(address: ContractAddress) -> u32
fn update_game_state_and_emit_events(result: CommandResult)
fn handle_triggered_actions(actions: Array<u32>)
fn validate_game_state(player_inst: u32) -> bool
```

---

### Module: `systems/world_builder.cairo`

**Purpose:** World creation entry point - replaces `designer.cairo` while preserving interface

**Dependencies:** `components/entity_manager`, `components/action_system`

**Critical Preserved Interfaces:**
```cairo
#[external(v0)]
fn create_player(ref self: ContractState, t: Array<Player>)

#[external(v0)]
fn create_entity(ref self: ContractState, t: Array<Entity>)

#[external(v0)]
fn create_area(ref self: ContractState, t: Array<Area>)

// ... (20+ other designer functions with exact signatures preserved)
```

**Implementation Strategy:**
```cairo
fn create_entity(ref self: ContractState, t: Array<Entity>) {
    // Route through new entity_manager component
    for entity in t {
        let result = entity_manager::create_entity(entity.entity_type, entity.name, entity.properties);
        // Handle any errors internally, maintain void return
    }
}
```

---

### Module: `systems/standard_mode.cairo`

**Purpose:** Default gameplay rules and configuration

**Dependencies:** All components

**Public Functions:**
```cairo
fn initialize_game_mode(world: IWorldDispatcher) -> Result<(), ModeError>
fn get_game_rules() -> GameRules
fn validate_action(action: ActionType, context: GameContext) -> bool
fn apply_game_mode_modifiers(base_result: CommandResult) -> CommandResult
```

---

### Module: `systems/debug_mode.cairo`

**Purpose:** Development and testing mode

**Dependencies:** All components

**Public Functions:**
```cairo
fn enable_debug_mode(player_inst: u32) -> Result<(), DebugError>
fn execute_debug_command(player_inst: u32, debug_command: DebugCommand) -> DebugResult
fn get_debug_info(entity_inst: u32) -> DebugInfo
fn validate_debug_permissions(player_inst: u32) -> bool
```

---

### Module: `systems/editor_mode.cairo`

**Purpose:** World editing and creation mode

**Dependencies:** `components/entity_manager`, `systems/world_builder`

**Public Functions:**
```cairo
fn enter_editor_mode(player_inst: u32) -> Result<(), EditorError>
fn create_world_template(template_data: WorldTemplate) -> Result<u32, EditorError>
fn save_world_state(world_inst: u32) -> Result<ByteArray, EditorError>
fn load_world_state(world_data: ByteArray) -> Result<u32, EditorError>
```

---

## Response Communication Strategy

### Maintaining Frontend Compatibility Without Return Values

Since external interfaces must remain void returns to preserve frontend compatibility, game responses are communicated through the existing Dojo event and state update mechanisms that the frontend already subscribes to.

### Event-Based Response System

**Player Response Events:**
```cairo
#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PlayerResponse {
    #[key]
    pub player: ContractAddress,
    pub message: ByteArray,
    pub response_type: ResponseType,
    pub timestamp: u64
}

#[derive(Copy, Drop, Serde)]
enum ResponseType {
    GameMessage,
    ErrorMessage,
    SystemMessage,
    DebugMessage
}
```

**State Update Pattern:**
```cairo
fn update_game_state_and_emit_events(result: CommandResult) {
    // 1. Update player's story log model
    player.add_story_entry(world, result.message);
    
    // 2. Apply state changes to relevant models
    for state_change in result.state_changes {
        apply_state_change(world, state_change);
    }
    
    // 3. Emit response event for immediate frontend feedback
    world.emit_event(@PlayerResponse {
        player: get_caller_address(),
        message: result.message,
        response_type: if result.success { ResponseType::GameMessage } else { ResponseType::ErrorMessage },
        timestamp: get_block_timestamp()
    });
    
    // 4. Trigger any follow-up actions
    for action_id in result.triggered_actions {
        action_system::execute_action(world, action_id);
    }
}
```

### Frontend Integration

The frontend already subscribes to Dojo events and model updates through Torii:

**Current Frontend Pattern (No Changes Required):**
```typescript
// Frontend already handles responses through:
// 1. Event subscriptions (Torii WebSocket)
// 2. Model state updates (reactive UI)
// 3. Story log updates (terminal display)

// This pattern is preserved - no frontend changes needed
```

### Benefits of Event-Based Approach

1. **Zero Breaking Changes:** Frontend interface remains identical
2. **Real-time Updates:** Events provide immediate feedback
3. **Persistent State:** Story log maintains conversation history
4. **Scalable:** Multiple players can receive updates simultaneously
5. **Debuggable:** All game actions are logged as events

---

## Migration Implementation Strategy

### Phase 1: Foundation Setup (Weeks 1-2)

#### Step 1.1: Create Helper Layer
```cairo
// Create directory structure
mkdir -p src/helpers/

// Implement utilities (in order)
1. helpers/validation.cairo - Basic validation functions
2. helpers/data_packer.cairo - Storage optimization
3. helpers/random_utils.cairo - RNG utilities
4. helpers/property_manager.cairo - Dynamic properties
5. helpers/text_utils.cairo - Dictionary and text processing
```

#### Step 1.2: Create Types Layer
```cairo
// Create directory structure  
mkdir -p src/types/

// Implement type definitions (in order)
1. types/direction_type.cairo - Movement directions
2. types/entity_type.cairo - Entity classification
3. types/action_type.cairo - Action system types
4. types/command_type.cairo - Command routing
```

#### Step 1.3: Update Import Statements
```cairo
// Update all existing files to use new helper imports
// Maintain 100% behavioral compatibility
// Add comprehensive unit tests for all helpers
```

**Testing Requirements:**
- Unit test every helper function
- Verify no behavioral changes in existing systems
- Performance benchmarks for optimization functions

---

### Phase 2: Models Layer (Weeks 3-4)

#### Step 2.1: Extract Data Models
```cairo
// Create directory structure
mkdir -p src/models/

// Extract pure data from existing components (in order)
1. models/entity.cairo - Core entity data
2. models/relationships.cairo - Parent-child data
3. models/player.cairo - Player state data
4. models/area.cairo - Area state data
5. models/item.cairo - Item state data
6. models/container.cairo - Container state data
7. models/exit.cairo - Exit state data
8. models/inspectable.cairo - Description data
9. models/action_system.cairo - Action/trigger/condition/effect data
```

#### Step 2.2: Update Component References
```cairo
// Modify existing components to use new models
// Maintain exact same external behavior
// Preserve all data fields and relationships
```

**Testing Requirements:**
- Data integrity validation
- Relationship preservation tests
- Storage layout compatibility verification

---

### Phase 3: Elements and Components (Weeks 5-7)

#### Step 3.1: Create Elements Layer
```cairo
// Create directory structure
mkdir -p src/elements/entities/
mkdir -p src/elements/descriptors/
mkdir -p src/elements/relationships/

// Implement entity behaviors
1. elements/entities/player.cairo
2. elements/entities/area.cairo
3. elements/entities/item.cairo
4. elements/entities/container.cairo
5. elements/entities/exit.cairo
6. elements/descriptors/inspectable.cairo
7. elements/relationships/spatial.cairo
```

#### Step 3.2: Create Components Layer
```cairo
// Create directory structure
mkdir -p src/components/

// Implement orchestration components
1. components/text_parser.cairo
2. components/entity_manager.cairo
3. components/action_system.cairo
4. components/movement_system.cairo
5. components/inventory_system.cairo
6. components/interaction_system.cairo
7. components/command_processor.cairo
```

**Testing Requirements:**
- Individual element behavior tests
- Component orchestration tests
- Integration tests with existing systems

---

### Phase 4: Systems Layer (Weeks 8-9)

#### Step 4.1: Create Interface Adapters
```cairo
// Create adapters to maintain external interface compatibility
// These ensure frontend sees no changes

struct GameEngineAdapter {
    // Exact same interface as prompt.cairo
    fn prompt(ref world: IWorldDispatcher, cmd: ByteArray) -> ByteArray
}

struct WorldBuilderAdapter {
    // Exact same interfaces as designer.cairo
    fn add_component(...) -> bool
    fn remove_component(...) -> bool
    // ... all other designer functions
}
```

#### Step 4.2: Implement New Systems
```cairo
// Create directory structure (systems already exists, so extend it)

// Implement new system files
1. systems/game_engine.cairo - Routes to components
2. systems/world_builder.cairo - Routes to entity_manager
3. systems/standard_mode.cairo - Game rules
4. systems/debug_mode.cairo - Debug functionality
5. systems/editor_mode.cairo - World editing
```

#### Step 4.3: Gradual Cutover
```cairo
// Use feature flags to gradually switch from old to new implementation
// Test each system individually before full cutover
```

**Testing Requirements:**
- Frontend integration tests must pass 100%
- Exact behavioral compatibility verification
- Performance regression testing

---

### Phase 5: Optimization and Cleanup (Weeks 10-11)

#### Step 5.1: Remove Legacy Code
```cairo
// Remove original component files once new system is proven
// Clean up unused imports and dependencies
```

#### Step 5.2: Performance Optimization
```cairo
// Optimize gas usage
// Improve storage efficiency
// Benchmark and validate performance improvements
```

#### Step 5.3: Documentation and Finalization
```cairo
// Update all Cairo doc comments
// Create architecture documentation
// Finalize testing suite
```

---

## Error Handling Strategy

### Error Type Hierarchy
```cairo
#[derive(Drop, Serde)]
enum SystemError {
    PlayerError(PlayerError),
    EntityError(EntityError),
    ActionError(ActionError),
    ValidationError(ValidationError),
    ProcessingError(ProcessingError),
    StorageError(StorageError)
}

// Specific error types for each component...
#[derive(Drop, Serde)]
enum PlayerError {
    PlayerNotFound,
    InvalidLocation,
    InsufficientPermissions,
    RateLimitExceeded
}
```

### Error Handling Patterns
```cairo
// All functions return Result types
fn process_command(player_inst: u32, cmd: ByteArray) -> Result<CommandResult, ProcessingError>

// Error propagation through layers
// Helpers return specific errors
// Components catch and wrap helper errors
// Systems provide user-friendly error messages
```

---

## Testing Strategy

### Unit Testing
```cairo
// Test each helper function individually
#[test]
fn test_normalize_text() {
    let input = "  Hello    World  ";
    let result = text_utils::normalize_text(input);
    assert!(result == "hello world");
}

// Test each element behavior
#[test]
fn test_player_movement() {
    let result = player::move_player(1, 2);
    assert!(result.is_ok());
}
```

### Integration Testing
```cairo
// Test component orchestration
#[test]
fn test_command_processing_flow() {
    let result = command_processor::process_command(1, "go north");
    // Verify full flow through all layers
}

// Test system-level behavior
#[test]
fn test_game_engine_prompt() {
    let result = game_engine::prompt(world, "look around");
    // Verify exact same behavior as original prompt.cairo
}
```

### Frontend Compatibility Testing
```cairo
// Verify exact interface compatibility
#[test]
fn test_prompt_interface_compatibility() {
    // Call new game_engine::prompt with void return
    // Verify same events are emitted as original
    // Verify same state changes occur as original
    // Must maintain exact same external behavior
}

#[test]
fn test_designer_interface_compatibility() {
    // Test all 20+ designer functions with void returns
    // Verify exact same model updates occur as original
    // Verify exact same side effects occur as original
    // All external behavior must be identical
}
```

### Performance Testing
```cairo
// Gas usage benchmarks
#[test]
fn benchmark_command_processing() {
    // Measure gas usage of command processing
    // Compare to original implementation
    // Must be within 5% of original
}
```

---

## Success Criteria Validation

### Automated Validation
1. **All unit tests pass** (>90% coverage requirement)
2. **All integration tests pass** (full system behavior)
3. **Frontend compatibility tests pass** (zero breaking changes)
4. **Performance benchmarks meet requirements** (≤5% regression)

### Manual Validation Checklist
- [ ] All game features work identically to original (same events, same state changes)
- [ ] Frontend team confirms zero interface changes needed
- [ ] All external function signatures remain exactly the same (void returns preserved)
- [ ] Event-based response system works seamlessly with existing frontend
- [ ] New developer can understand architecture quickly
- [ ] Code review confirms Shinigami pattern compliance
- [ ] Error handling is comprehensive and user-friendly
- [ ] Performance is equal or better than original
- [ ] All Dojo bindings remain unchanged (no regeneration needed)

---

## Appendix A: Complete Function Signatures

[This section would contain every function signature defined in the specification, organized by module, for easy reference during implementation]

---

## Appendix B: Data Structure Definitions

[This section would contain all struct and enum definitions, with detailed field descriptions and usage notes]

---

## Appendix C: Interface Compatibility Matrix

[This section would contain a detailed mapping of every original function to its new implementation path, ensuring 100% compatibility]

---

*This specification provides implementation-ready blueprints for the complete LORE contract refactoring. Every module, function, and data structure is defined with sufficient detail for parallel development by multiple team members.*