# Advanced Dojo Framework Patterns for Shinigami Design System

This document outlines advanced Dojo framework patterns, ECS architecture principles, and best practices specifically for building fully on-chain games with Dojo v1.5.0 and the Shinigami design system.

## 1. Dojo ECS Architecture Patterns

### Model Design Philosophy in Dojo

Dojo follows Entity Component System (ECS) principles where Models represent Components containing specific data aspects:

```cairo
// Small, focused models following ECS principles
#[derive(Drop, Serde)]
#[dojo::model]
struct Position {
    #[key]
    entity_id: u32,
    x: u32,
    y: u32,
    z: u32
}

#[derive(Drop, Serde)]
#[dojo::model] 
struct Health {
    #[key]
    entity_id: u32,
    current: u32,
    maximum: u32
}

#[derive(Drop, Serde)]
#[dojo::model]
struct Inventory {
    #[key]
    entity_id: u32,
    items: Array<ItemId>,
    capacity: u32
}
```

### System Organization Pattern

```cairo
#[dojo::contract]
mod movement_system {
    use super::{Position, Velocity};
    
    #[external(v0)]
    fn move_entity(
        ref world: IWorldDispatcher,
        entity_id: u32,
        direction: Direction
    ) {
        // Validate movement
        let position = get!(world, entity_id, (Position));
        let new_position = calculate_new_position(position, direction);
        
        // Update state
        set!(world, (Position {
            entity_id,
            x: new_position.x,
            y: new_position.y,
            z: new_position.z
        }));
        
        // Emit event
        emit!(world, MovementEvent { entity_id, from: position, to: new_position });
    }
}
```

## 2. Dojo World Storage and Access Patterns

### Modern WorldStorage Pattern (Dojo v1.5.0)

```cairo
#[dojo::contract]
mod game_system {
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::ModelStorage;
    
    #[external(v0)]
    fn create_player(self: @ContractState, name: ByteArray) -> ContractAddress {
        // Access world with proper namespace
        let world = self.world(@"elysium_001");
        
        // Create player using ModelStorage
        let player = Player {
            player: get_caller_address(),
            name,
            level: 1,
            experience: 0,
        };
        
        // Write to world storage
        world.write_model(@player);
        
        player.player
    }
}
```

### Store Pattern for Model Access

```cairo
// Implement Store trait for semantic model operations
#[generate_trait]
pub impl StoreImpl of StoreTrait {
    fn get_player(self: Store, player: ContractAddress) -> Player {
        self.world.read_model(player)
    }
    
    fn get_player_inventory(self: Store, player: ContractAddress) -> PlayerInventory {
        self.world.read_model(player)
    }
    
    fn update_player_stats(self: Store, player: ContractAddress, health: u32, level: u32) {
        let mut player_data: Player = self.world.read_model(player);
        player_data.health = health;
        player_data.level = level;
        self.world.write_model(@player_data);
    }
}
```

## 3. Dojo Event System Patterns

### Structured Event Design

```cairo
#[derive(Drop, starknet::Event)]
struct GameEvent {
    #[key]
    event_type: EventType,
    #[key]
    entity_id: u32,
    timestamp: u64,
    data: Span<felt252>
}

#[derive(Drop, starknet::Event)]
struct CombatEvent {
    #[key]
    attacker_id: u32,
    #[key]
    target_id: u32,
    damage: u32,
    combat_type: CombatType
}
```

### Event Sourcing with Dojo

```cairo
// Store all state changes as events
#[derive(Drop, Serde)]
#[dojo::model]
struct EventLog {
    #[key]
    sequence_id: u64,
    event_type: EventType,
    entity_id: u32,
    data: EventData,
    timestamp: u64
}

// Rebuild state from events
fn rebuild_entity_state(
    world: IWorldDispatcher,
    entity_id: u32,
    up_to_sequence: u64
) -> EntityState {
    let events = query_events(world, entity_id, up_to_sequence);
    let mut state = EntityState::default();
    
    for event in events {
        state = apply_event(state, event);
    }
    
    state
}
```

## 4. Dojo Component Composition Patterns

### Component-Based Architecture

```cairo
// Use components instead of inheritance
#[derive(Drop, Serde)]
#[dojo::model]
struct CharacterCore {
    #[key]
    entity_id: u32,
    name: ByteArray,
    level: u32
}

#[derive(Drop, Serde)] 
#[dojo::model]
struct PlayerData {
    #[key]
    entity_id: u32,
    experience: u64,
    skill_points: u32
}

// Compose functionality through multiple models
fn get_character_info(world: IWorldDispatcher, entity_id: u32) -> CharacterInfo {
    let core = get!(world, entity_id, (CharacterCore));
    let player_data = get!(world, entity_id, (PlayerData));
    let position = get!(world, entity_id, (Position));
    
    CharacterInfo { core, player_data, position }
}
```

## 5. Dojo State Management Patterns

### Efficient Storage with Dojo Models

```cairo
// Models act as key-value stores
#[derive(Drop, Serde)]
#[dojo::model]
struct GameState {
    #[key]
    game_id: u32,
    #[key] 
    state_type: StateType,
    data: Span<felt252>
}

// Nested storage for complex data
#[derive(Drop, Serde)]
#[dojo::model]
struct WorldMap {
    #[key]
    world_id: u32,
    #[key]
    chunk_x: u32,
    #[key]
    chunk_y: u32,
    terrain_data: TerrainChunk
}
```

### State Compression in Dojo

```cairo
// Compress game state for efficient storage
#[derive(Drop, Serde)]
#[dojo::model]
struct CompressedPlayerState {
    #[key]
    player_id: u32,
    // Pack multiple values into single felt252
    packed_stats: felt252, // Contains level, hp, mp, etc.
    packed_position: felt252, // Contains x, y, z coordinates
    items_hash: felt252 // Hash of inventory contents
}

fn unpack_stats(packed: felt252) -> PlayerStats {
    // Bit manipulation to extract individual values
    let level = (packed / 0x1000000) % 0x100;
    let hp = (packed / 0x10000) % 0x100;
    let mp = (packed / 0x100) % 0x100;
    PlayerStats { level, hp, mp }
}
```

## 6. Dojo System Integration Patterns

### Hierarchical System Organization

```cairo
// Base system traits
#[starknet::interface]
trait IGameSystem<TContractState> {
    fn process_action(
        ref self: TContractState,
        player_id: u32,
        action: GameAction
    ) -> ActionResult;
    
    fn get_game_state(
        self: @TContractState,
        game_id: u32
    ) -> GameState;
}

// Specialized systems
#[derive(Drop, Serde)]
#[dojo::model]
struct BaseEntity {
    #[key]
    id: u32,
    entity_type: EntityType,
    created_at: u64
}

#[derive(Drop, Serde)]
#[dojo::model]
struct Character {
    #[key]
    id: u32,
    name: ByteArray,
    class: CharacterClass
}

#[derive(Drop, Serde)]
#[dojo::model]
struct NPC {
    #[key]
    id: u32,
    dialogue_tree: DialogueTreeId,
    ai_behavior: AIBehaviorType
}
```

### System Dependencies and Coordination

```cairo
// Game manager that coordinates systems
#[dojo::contract]
mod game_manager {
    #[storage]
    struct Storage {
        movement_system: ContractAddress,
        combat_system: ContractAddress
    }
    
    #[external(v0)]
    fn process_turn(
        ref self: ContractState,
        player_id: u32,
        actions: Array<GameAction>
    ) {
        for action in actions {
            match action {
                GameAction::Move(direction) => {
                    let movement = IMovementSystemDispatcher {
                        contract_address: self.movement_system.read()
                    };
                    movement.move_entity(player_id, direction);
                },
                GameAction::Attack(target) => {
                    let combat = ICombatSystemDispatcher {
                        contract_address: self.combat_system.read()
                    };
                    combat.attack_entity(player_id, target);
                }
            }
        }
    }
}
```

## 7. Dojo Performance Optimization Patterns

### Gas-Optimized Dojo Operations

```cairo
// Batch operations for efficiency
fn batch_update_entities(
    world: IWorldDispatcher,
    updates: Array<EntityUpdate>
) {
    let mut position_updates = ArrayTrait::new();
    let mut health_updates = ArrayTrait::new();
    
    // Group updates by type
    for update in updates {
        match update {
            EntityUpdate::Position(pos_update) => position_updates.append(pos_update),
            EntityUpdate::Health(health_update) => health_updates.append(health_update)
        }
    }
    
    // Apply batched updates
    batch_set_positions(world, position_updates);
    batch_set_health(world, health_updates);
}
```

### Dojo Model Indexing Patterns

```cairo
// Use multiple keys for efficient querying
#[derive(Drop, Serde)]
#[dojo::model]
struct PlayerByLevel {
    #[key]
    level: u32,
    #[key]
    player_id: u32,
    player_address: ContractAddress,
    experience: u64
}

// Query players by level range
fn get_players_in_level_range(
    world: IWorldDispatcher,
    min_level: u32,
    max_level: u32
) -> Array<ContractAddress> {
    let mut players = ArrayTrait::new();
    let mut level = min_level;
    
    while level <= max_level {
        // Query all players at this level
        let level_players = get_players_at_level(world, level);
        players.extend(level_players);
        level += 1;
    }
    
    players
}
```

## 8. Shinigami Pattern Integration with Dojo

### Elements Layer with Dojo Models

```cairo
// Elements as Dojo models with specific behaviors
#[derive(Drop, Serde)]
#[dojo::model]
struct Weapon {
    #[key]
    id: u32,
    weapon_type: WeaponType,
    damage: u32,
    durability: u32,
    owner: ContractAddress
}

#[generate_trait]
pub impl WeaponImpl of WeaponTrait {
    fn calculate_damage(self: @Weapon, target_armor: u32) -> u32 {
        let base_damage = *self.damage;
        let armor_reduction = target_armor.min(base_damage / 2);
        base_damage - armor_reduction
    }
}
```

### Types Layer with Dojo Integration

```cairo
// Types that route to Dojo systems
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum ActionType {
    Move,
    Attack,
    UseItem,
    Trade
}

#[generate_trait]
pub impl ActionTypeImpl of ActionTypeTrait {
    fn execute(self: ActionType, world: IWorldDispatcher, player: ContractAddress, params: ActionParams) {
        match self {
            ActionType::Move => {
                let movement_system = IMovementSystemDispatcher { contract_address: get_system_address(world, "Movement") };
                movement_system.move_player(player, params.direction);
            },
            ActionType::Attack => {
                let combat_system = ICombatSystemDispatcher { contract_address: get_system_address(world, "Combat") };
                combat_system.attack(player, params.target);
            },
            // ... other actions
        }
    }
}
```

## Key Dojo Architectural Principles

1. **ECS Over OOP**: Use small, focused Models instead of large hierarchical structures
2. **WorldStorage Centralization**: All persistent state flows through the World contract
3. **System Coordination**: Systems communicate through the World, not directly
4. **Event-Driven Updates**: Use events for loose coupling between systems
5. **Gas-Optimized Queries**: Design Models with efficient key structures for common queries
6. **Namespace Isolation**: Use proper namespaces to separate game logic domains
7. **Store Pattern Abstraction**: Provide semantic interfaces over raw ModelStorage operations

This pattern collection provides a foundation for building sophisticated, gas-efficient, and maintainable Dojo applications following the Shinigami design methodology specifically within the Dojo framework context.