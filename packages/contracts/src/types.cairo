//! Shinigami Layer 3: Types - Entry Points & Routing
//! 
//! This module provides type definitions and routing logic for the LORE game engine.
//! It serves as the entry point layer in the Shinigami architecture, handling 
//! classification and routing of entities, commands, directions, and actions.

pub mod direction_type;
pub mod entity_type;
pub mod action_type;
pub mod command_type;

// Re-export commonly used types for convenience
pub use direction_type::{DirectionType, DirectionError};
pub use entity_type::{EntityType, ComponentType, TypeError};
pub use action_type::{TriggerType, ConditionType, EffectType, ActionStatus, TriggerContext, EffectContext, ConditionContext};
pub use command_type::{CommandType, InteractionType, InspectionType, ParseError, ParsedCommand, PlayerContext};