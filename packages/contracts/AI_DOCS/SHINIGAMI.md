# The Shinigami Design Pattern for Dojo Projects

This document provides a comprehensive guide to the **Shinigami Design Pattern** - a hierarchical, modular architecture framework for building fully on-chain games (FOCGs) using Dojo and Cairo on Starknet.

## 🎯 Overview

Shinigami is designed for creating fully onchain games within Autonomous Worlds on Starknet. It follows a structured, hierarchical approach that enables efficient development and maintenance of onchain games through modular design principles.

## 📐 Architecture Hierarchy

The Shinigami pattern organizes code into six distinct layers, each with specific responsibilities:

```
┌─────────────────────────────────────────┐
│                SYSTEMS                  │  ← Game Modes & Configurations
├─────────────────────────────────────────┤
│              COMPONENTS                 │  ← Multi-Model Operations
├─────────────────────────────────────────┤
│                MODELS                   │  ← Persistent Game State
├─────────────────────────────────────────┤
│                TYPES                    │  ← Entry Points & Enumerators
├─────────────────────────────────────────┤
│               ELEMENTS                  │  ← Game Entities & Logic
├─────────────────────────────────────────┤
│               HELPERS                   │  ← Reusable Utilities
└─────────────────────────────────────────┘
```

## 🏗️ Layer Definitions

### 1. Elements (Bottom Layer)
**Purpose**: Distinct game entities with specific traits and behaviors.

**Responsibilities**:
- Handle intrinsic game logic for specific entity types
- Implement unique traits for uniform processing
- Ensure consistency within their domain
- Provide foundation for higher-level abstractions

**Examples**: Achievements, Bonuses, Items, NPCs, Rooms, Combat Actions

**Implementation Pattern**:
```cairo
// Element trait definition
#[starknet::interface]
trait IGameElement<TState> {
    fn initialize(ref self: TState, config: ElementConfig);
    fn process(ref self: TState, input: ElementInput) -> ElementOutput;
    fn validate(self: @TState) -> bool;
}

// Specific element implementation
#[derive(Drop, Serde, Clone, Introspect)]
struct Achievement {
    id: felt252,
    name: ByteArray,
    description: ByteArray,
    requirements: Array<felt252>,
    reward_type: RewardType,
    is_active: bool,
}

impl AchievementImpl of AchievementTrait {
    fn new(id: felt252, name: ByteArray, description: ByteArray) -> Achievement {
        assert(id != 0, 'Achievement: invalid id');
        assert(name.len() > 0, 'Achievement: invalid name');
        Achievement {
            id, name, description,
            requirements: ArrayTrait::new(),
            reward_type: RewardType::Experience(100),
            is_active: true,
        }
    }

    fn check_completion(self: @Achievement, player_progress: @PlayerProgress) -> bool {
        // Implementation logic
        true
    }
}
```

### 2. Types (Type System Layer)
**Purpose**: Enumerators and custom types that define game states and direct workflows.

**Responsibilities**:
- Serve as entry points for associated Elements
- Define various states and functional intentions
- Direct workflows to appropriate Element logic
- Provide type safety and validation

**Examples**: ItemType, ActionType, RoomType, SkillType, EventType

**Implementation Pattern**:
```cairo
// Type enumeration with validation
#[derive(Drop, Serde, Clone, Copy, Introspect, PartialEq)]
enum ItemType {
    Weapon: WeaponType,
    Armor: ArmorType,
    Consumable: ConsumableType,
    Quest: QuestType,
    Material: MaterialType,
}

#[derive(Drop, Serde, Clone, Copy, Introspect, PartialEq)]
enum WeaponType {
    Sword,
    Bow,
    Staff,
    Dagger,
}

impl ItemTypeImpl of ItemTypeTrait {
    fn is_equipable(self: @ItemType) -> bool {
        match self {
            ItemType::Weapon(_) => true,
            ItemType::Armor(_) => true,
            ItemType::Consumable(_) => false,
            ItemType::Quest(_) => false,
            ItemType::Material(_) => false,
        }
    }

    fn get_element_handler(self: @ItemType) -> felt252 {
        match self {
            ItemType::Weapon(_) => 'weapon_handler',
            ItemType::Armor(_) => 'armor_handler',
            ItemType::Consumable(_) => 'consumable_handler',
            ItemType::Quest(_) => 'quest_handler',
            ItemType::Material(_) => 'material_handler',
        }
    }
}

// Type assertions for validation
impl ItemTypeAssert of AssertTrait {
    fn assert_valid_weapon_type(weapon_type: WeaponType) {
        // Validation logic
    }

    fn assert_can_equip(item_type: @ItemType, player_class: PlayerClass) {
        assert(item_type.is_equipable(), 'Item: not equipable');
        // Additional class-specific validation
    }
}
```

### 3. Models (Persistence Layer)
**Purpose**: Entities with onchain persistence that store and manage game state.

**Responsibilities**:
- Implement data manipulation logic
- Ensure data integrity during transactions
- Provide consistent data access patterns
- Handle storage optimization

**Examples**: PlayerStats, GameState, Inventory, WorldMap

**Implementation Pattern**:
```cairo
// Model definition with Dojo
#[dojo::model]
#[derive(Clone, Drop, Serde)]
struct Player {
    #[key]
    player_id: felt252,
    name: ByteArray,
    level: u32,
    experience: u64,
    health: u32,
    max_health: u32,
    position: Position,
    inventory: Array<InventorySlot>,
    skills: Array<Skill>,
    last_action_timestamp: u64,
}

// Model operations
impl PlayerImpl of PlayerTrait {
    fn new(player_id: felt252, name: ByteArray) -> Player {
        Player {
            player_id,
            name,
            level: 1,
            experience: 0,
            health: 100,
            max_health: 100,
            position: Position { x: 0, y: 0 },
            inventory: ArrayTrait::new(),
            skills: ArrayTrait::new(),
            last_action_timestamp: get_block_timestamp(),
        }
    }

    fn gain_experience(ref self: Player, amount: u64) {
        self.experience += amount;
        let new_level = self.calculate_level();
        if new_level > self.level {
            self.level_up(new_level);
        }
    }

    fn take_damage(ref self: Player, damage: u32) -> bool {
        if damage >= self.health {
            self.health = 0;
            return false; // Player dies
        }
        self.health -= damage;
        true
    }
}

// Model storage interface
#[dojo::interface]
trait IPlayerStore {
    fn create_player(ref self: TContractState, player_id: felt252, name: ByteArray);
    fn get_player(self: @TContractState, player_id: felt252) -> Player;
    fn set_player(ref self: TContractState, player: Player);
    fn delete_player(ref self: TContractState, player_id: felt252);
}
```

### 4. Components (Orchestration Layer)
**Purpose**: Execute complex operations involving multiple Models with validation and coordination.

**Responsibilities**:
- Coordinate operations across multiple Models
- Implement business rules and validations
- Maintain game state coherence
- Handle complex workflows

**Examples**: CombatSystem, TradingSystem, QuestManager, MovementController

**Implementation Pattern**:
```cairo
// Component for complex game operations
#[starknet::component]
mod CombatComponent {
    use super::{Player, Enemy, CombatResult, DamageCalculation};

    #[storage]
    struct Storage {
        active_combats: LegacyMap<felt252, Combat>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CombatStarted: CombatStarted,
        CombatEnded: CombatEnded,
        DamageDealt: DamageDealt,
    }

    #[derive(Drop, starknet::Event)]
    struct CombatStarted {
        combat_id: felt252,
        player_id: felt252,
        enemy_id: felt252,
        timestamp: u64,
    }

    #[embeddable_as(CombatImpl)]
    impl CombatInternalImpl<
        TContractState, +HasComponent<TContractState>
    > of super::ICombat<ComponentState<TContractState>> {

        fn initiate_combat(
            ref self: ComponentState<TContractState>,
            player_id: felt252,
            enemy_id: felt252
        ) -> felt252 {
            // Validate participants
            let player = self.get_player(player_id);
            let enemy = self.get_enemy(enemy_id);

            assert(player.health > 0, 'Player: already defeated');
            assert(enemy.health > 0, 'Enemy: already defeated');

            // Create combat instance
            let combat_id = self.generate_combat_id(player_id, enemy_id);
            let combat = Combat {
                id: combat_id,
                player_id,
                enemy_id,
                turn: Turn::Player,
                round: 1,
                status: CombatStatus::Active,
                start_time: get_block_timestamp(),
            };

            self.active_combats.write(combat_id, combat);

            // Emit event
            self.emit(CombatStarted {
                combat_id,
                player_id,
                enemy_id,
                timestamp: get_block_timestamp(),
            });

            combat_id
        }

        fn execute_attack(
            ref self: ComponentState<TContractState>,
            combat_id: felt252,
            attack_type: AttackType
        ) -> CombatResult {
            let mut combat = self.active_combats.read(combat_id);
            assert(combat.status == CombatStatus::Active, 'Combat: not active');

            match combat.turn {
                Turn::Player => {
                    let player = self.get_player(combat.player_id);
                    let mut enemy = self.get_enemy(combat.enemy_id);

                    let damage = self.calculate_damage(player, enemy, attack_type);
                    enemy.take_damage(damage);

                    if enemy.health == 0 {
                        combat.status = CombatStatus::PlayerWin;
                        self.process_victory(combat.player_id, combat.enemy_id);
                    } else {
                        combat.turn = Turn::Enemy;
                    }

                    self.update_enemy(enemy);
                    CombatResult::Success(damage)
                },
                Turn::Enemy => {
                    // AI enemy turn logic
                    CombatResult::Error('Not player turn')
                }
            }
        }
    }
}
```

### 5. Systems (Configuration Layer)
**Purpose**: Game modes and configurations that define how Components interact.

**Responsibilities**:
- Manage game modes and scenarios
- Configure Component interactions
- Define gameplay rulesets
- Enable mode-specific behaviors

**Examples**: StandardMode, TutorialMode, ArenaMode, StoryMode

**Implementation Pattern**:
```cairo
// System for game mode configuration
#[dojo::contract]
mod GameSystem {
    use super::{IGameSystem, GameMode, GameConfig, PlayerClass};

    component!(path: CombatComponent, storage: combat, event: CombatEvent);
    component!(path: QuestComponent, storage: quest, event: QuestEvent);
    component!(path: InventoryComponent, storage: inventory, event: InventoryEvent);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        combat: CombatComponent::Storage,
        #[substorage(v0)]
        quest: QuestComponent::Storage,
        #[substorage(v0)]
        inventory: InventoryComponent::Storage,
        current_mode: GameMode,
        game_config: GameConfig,
    }

    #[abi(embed_v0)]
    impl GameSystemImpl of IGameSystem<ContractState> {
        fn initialize_game(
            ref self: ContractState,
            mode: GameMode,
            player_id: felt252,
            player_class: PlayerClass
        ) {
            let config = match mode {
                GameMode::Tutorial => GameConfig {
                    max_health: 50,
                    starting_items: array!['wooden_sword', 'health_potion'],
                    xp_multiplier: 2,
                    permadeath: false,
                },
                GameMode::Standard => GameConfig {
                    max_health: 100,
                    starting_items: array!['basic_weapon'],
                    xp_multiplier: 1,
                    permadeath: false,
                },
                GameMode::Hardcore => GameConfig {
                    max_health: 75,
                    starting_items: array![],
                    xp_multiplier: 1,
                    permadeath: true,
                },
            };

            self.current_mode.write(mode);
            self.game_config.write(config);

            // Initialize player with mode-specific configuration
            self.create_player_with_config(player_id, player_class, config);
        }

        fn process_player_action(
            ref self: ContractState,
            player_id: felt252,
            action: GameAction
        ) -> ActionResult {
            let mode = self.current_mode.read();
            let config = self.game_config.read();

            match action {
                GameAction::Move(direction) => {
                    self.process_movement(player_id, direction, config)
                },
                GameAction::Attack(target) => {
                    self.combat.initiate_combat(player_id, target)
                },
                GameAction::UseItem(item_id) => {
                    self.inventory.use_item(player_id, item_id, config)
                },
                GameAction::StartQuest(quest_id) => {
                    self.quest.start_quest(player_id, quest_id, mode)
                },
            }
        }
    }
}
```

### 6. Helpers (Utility Layer)
**Purpose**: Reusable utility functions without game-specific data.

**Responsibilities**:
- Provide common utility functions
- Handle data transformations
- Implement algorithms and calculations
- Reduce code duplication

**Examples**: Packers, Solvers, Battle Calculators, Random Generators

**Implementation Pattern**:
```cairo
// Helper modules for reusable logic
mod RandomHelper {
    use core::pedersen::PedersenTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};

    fn generate_seed(player_id: felt252, block_number: u64) -> felt252 {
        PedersenTrait::new()
            .update_with(player_id)
            .update_with(block_number.into())
            .finalize()
    }

    fn random_range(seed: felt252, min: u32, max: u32) -> u32 {
        assert(min < max, 'Random: invalid range');
        let range = max - min;
        let random = seed.try_into().unwrap() % range.into();
        min + random.try_into().unwrap()
    }
}

mod DamageCalculator {
    use super::{Player, Enemy, AttackType, DamageModifier};

    fn calculate_base_damage(
        attacker_strength: u32,
        weapon_damage: u32,
        attack_type: AttackType
    ) -> u32 {
        let base = attacker_strength + weapon_damage;
        match attack_type {
            AttackType::Light => base * 80 / 100,
            AttackType::Heavy => base * 120 / 100,
            AttackType::Critical => base * 200 / 100,
        }
    }

    fn apply_modifiers(
        base_damage: u32,
        modifiers: Array<DamageModifier>
    ) -> u32 {
        let mut final_damage = base_damage;
        let mut i = 0;
        loop {
            if i >= modifiers.len() {
                break;
            }
            let modifier = modifiers.at(i);
            final_damage = match *modifier {
                DamageModifier::Percentage(percent) =>
                    final_damage * percent / 100,
                DamageModifier::Flat(amount) =>
                    final_damage + amount,
                DamageModifier::Resistance(resistance) =>
                    final_damage - (final_damage * resistance / 100),
            };
            i += 1;
        };
        final_damage
    }
}

mod DataPacker {
    // Efficient data packing for storage optimization
    fn pack_position(x: u32, y: u32) -> felt252 {
        (x.into() * 0x100000000) + y.into()
    }

    fn unpack_position(packed: felt252) -> (u32, u32) {
        let x = (packed / 0x100000000).try_into().unwrap();
        let y = (packed % 0x100000000).try_into().unwrap();
        (x, y)
    }

    fn pack_inventory_slot(item_id: felt252, quantity: u32) -> felt252 {
        item_id + (quantity.into() * 0x1000000000000000000000000000000000000000000000000000000000000000)
    }
}
```

## 🎮 Practical Implementation for Elysium Descent

### Project Structure
```
contracts/src/
├── elements/           # Game entities
│   ├── items/
│   │   ├── weapon.cairo
│   │   ├── armor.cairo
│   │   └── consumable.cairo
│   ├── npcs/
│   │   ├── enemy.cairo
│   │   └── merchant.cairo
│   └── rooms/
│       ├── dungeon_room.cairo
│       └── boss_room.cairo
├── types/              # Enumerators & entry points
│   ├── item_type.cairo
│   ├── action_type.cairo
│   ├── room_type.cairo
│   └── player_class.cairo
├── models/             # Persistent state
│   ├── player.cairo
│   ├── game_state.cairo
│   ├── inventory.cairo
│   └── world_map.cairo
├── components/         # Multi-model operations
│   ├── combat.cairo
│   ├── movement.cairo
│   ├── trading.cairo
│   └── quest_manager.cairo
├── systems/            # Game modes
│   ├── standard_mode.cairo
│   ├── tutorial_mode.cairo
│   └── arena_mode.cairo
├── helpers/            # Utilities
│   ├── random.cairo
│   ├── damage_calc.cairo
│   ├── pathfinding.cairo
│   └── data_packer.cairo
└── lib.cairo           # Module declarations
```

### Example Implementation Flow

1. **Player picks up an item**:
   - **Element**: `Weapon` element validates item properties
   - **Type**: `ItemType::Weapon` directs to weapon handler
   - **Model**: `Player` and `Inventory` models updated
   - **Component**: `InventoryComponent` orchestrates the pickup
   - **System**: `StandardMode` applies mode-specific rules
   - **Helper**: `DataPacker` optimizes storage

2. **Combat encounter**:
   - **Element**: `Enemy` element defines behavior
   - **Type**: `ActionType::Attack` routes to combat logic
   - **Model**: `Player` and `Enemy` health updated
   - **Component**: `CombatComponent` manages battle flow
   - **System**: Current game mode applies damage rules
   - **Helper**: `DamageCalculator` computes damage

## 🏛️ Architectural Principles

### 1. **Separation of Concerns**
Each layer has distinct responsibilities with minimal overlap.

### 2. **Hierarchical Dependencies**
Higher layers depend on lower layers, never the reverse:
- Systems → Components → Models → Types → Elements
- Helpers can be used by any layer

### 3. **Composability**
Components can be mixed and matched across different Systems.

### 4. **Extensibility**
New Elements, Types, and Components can be added without modifying existing code.

### 5. **Reusability**
Helpers provide common functionality across the entire application.

### 6. **Type Safety**
Strong typing through Cairo's type system and comprehensive validation.

### 7. **Event-Driven Communication**
Systems communicate through events rather than direct calls.

## 🔄 Integration with Dojo

### World Configuration
```cairo
#[dojo::contract]
mod world {
    // All models automatically registered
    use super::{Player, GameState, Inventory, Enemy};

    // Systems registered as contracts
    use super::{StandardMode, TutorialMode, ArenaMode};

    // Components available for composition
    use super::{CombatComponent, MovementComponent, QuestComponent};
}
```

### Client Integration (Bevy)
```rust
// Synchronize with blockchain state
fn sync_game_state(
    mut commands: Commands,
    dojo_client: Res<DojoClient>,
    mut player_query: Query<(Entity, &mut PlayerStats)>,
) {
    // Fetch updated models from Dojo
    let blockchain_players = dojo_client.get_models::<Player>();

    for blockchain_player in blockchain_players {
        // Update or create Bevy entities based on blockchain state
        update_bevy_player(&mut commands, blockchain_player);
    }
}
```

## 📋 Best Practices

### 1. **Element Design**
- Keep Elements focused on single responsibilities
- Use traits for uniform interfaces
- Implement comprehensive validation
- Design for reusability across different contexts

### 2. **Type Safety**
- Use enums for finite state spaces
- Implement custom validation traits
- Provide clear error messages
- Design type hierarchies thoughtfully

### 3. **Model Persistence**
- Optimize storage layout for gas efficiency
- Use appropriate data structures
- Implement atomic operations
- Design for concurrent access

### 4. **Component Orchestration**
- Validate all inputs before processing
- Maintain transaction atomicity
- Emit events for state changes
- Handle edge cases gracefully

### 5. **System Configuration**
- Design for different gameplay modes
- Make systems configurable
- Support dynamic rule changes
- Separate logic from configuration

### 6. **Helper Utilities**
- Keep functions pure when possible
- Design for performance
- Provide comprehensive test coverage
- Document complex algorithms

## 🔮 Advanced Patterns

### State Machine Implementation
```cairo
#[derive(Drop, Serde, Clone, Copy, PartialEq)]
enum GameState {
    Lobby,
    InGame,
    Paused,
    GameOver,
}

impl GameStateImpl of GameStateTrait {
    fn can_transition(from: GameState, to: GameState) -> bool {
        match (from, to) {
            (GameState::Lobby, GameState::InGame) => true,
            (GameState::InGame, GameState::Paused) => true,
            (GameState::InGame, GameState::GameOver) => true,
            (GameState::Paused, GameState::InGame) => true,
            (GameState::GameOver, GameState::Lobby) => true,
            _ => false,
        }
    }
}
```

### Plugin Architecture
```cairo
#[starknet::interface]
trait IGamePlugin<TState> {
    fn initialize(ref self: TState, config: PluginConfig);
    fn process_event(ref self: TState, event: GameEvent) -> PluginResult;
    fn get_metadata(self: @TState) -> PluginMetadata;
}

// Allows for modular game features
#[dojo::contract]
mod plugin_manager {
    use super::{IGamePlugin, PluginRegistry};

    fn register_plugin(ref self: ContractState, plugin: ContractAddress) {
        // Dynamic plugin registration
    }

    fn execute_plugins(ref self: ContractState, event: GameEvent) {
        // Execute all registered plugins for event
    }
}
```

## 🎯 Conclusion

The Shinigami Design Pattern provides a robust foundation for building complex, maintainable fully on-chain games. By following its hierarchical structure and architectural principles, developers can create scalable game systems that leverage the unique advantages of blockchain technology while maintaining code quality and developer productivity.

This pattern is particularly well-suited for:
- **Roguelike games** with complex state and procedural generation
- **Strategy games** requiring intricate rule systems
- **RPGs** with deep character progression and world state
- **Multiplayer games** needing fair, transparent mechanics

The combination of Shinigami's architectural principles with Dojo's powerful framework creates an ideal environment for building the next generation of blockchain games.
