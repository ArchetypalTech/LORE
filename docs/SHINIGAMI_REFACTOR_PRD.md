# LORE Contract Refactoring PRD
# Shinigami Design Pattern Implementation

**Document Version:** 1.0  
**Date:** 2025-06-24  
**Author:** Development Team  
**Status:** Planning Phase

---

## Executive Summary

This PRD outlines the refactoring of LORE's Cairo smart contracts from the current mixed architecture to the standardized **Shinigami Design Pattern**. The goal is to improve maintainability, scalability, and developer onboarding while preserving all existing frontend interfaces and game functionality.

---

## Problem Statement

### Current Issues
1. **Mixed Responsibilities**: Components contain both data models AND business logic
2. **Tight Coupling**: Components directly implement command execution, making testing difficult
3. **Inconsistent Patterns**: Some logic in components, some in handlers, no unified approach
4. **Limited Extensibility**: Hard to add new component types or game modes
5. **Developer Confusion**: Non-standard architecture makes onboarding difficult

### Impact
- **Maintainability**: Changes require touching multiple coupled files
- **Scalability**: Adding new features requires architectural decisions
- **Testing**: Business logic mixed with data makes unit testing complex
- **Onboarding**: New developers need to learn project-specific patterns

---

## Success Criteria

### Primary Goals
- ✅ **Zero Breaking Changes**: All frontend interfaces remain identical
- ✅ **Shinigami Compliance**: Full 6-layer architecture implementation
- ✅ **Improved Maintainability**: Clear separation of concerns
- ✅ **Enhanced Testability**: Isolated, unit-testable components

### Success Metrics
- All existing frontend tests pass without modification
- 100% functional parity with current implementation
- Reduced cyclomatic complexity per file
- Improved code coverage potential
- Faster developer onboarding (subjective measure)

---

## Current State Analysis

### Existing Architecture
```
📁 Current Structure:
├── systems/
│   ├── prompt.cairo      # Main entry point
│   └── designer.cairo    # World creation
├── components/ (Mixed responsibilities)
│   ├── area.cairo        # Data + Logic
│   ├── container.cairo   # Data + Logic
│   ├── exit.cairo        # Data + Logic
│   ├── inspectable.cairo # Data + Logic
│   ├── inventoryItem.cairo # Data + Logic
│   └── player.cairo      # Data + Logic
└── lib/ (Various utilities and core systems)
    ├── entity.cairo      # Core entity system
    ├── a_lexer.cairo     # Text parsing
    ├── c_handler.cairo   # Command routing
    └── [12 other utility files]
```

### Critical Preservation Requirements

#### External Interfaces (MUST NOT CHANGE)
1. **Frontend Command Interface**: `execCommand(command: string)` → `prompt.cairo`
2. **Frontend Designer Interface**: `execDesignerCall(call: DesignerCall, args)` → `designer.cairo`

#### Designer Operations (Full List)
```cairo
// Entity Management
create_player, create_entity, create_inspectable, create_area, 
create_exit, create_inventory_item, create_container

// Action System  
create_trigger, create_condition, create_effect, create_action

// Relationships
create_parent, create_child

// Property System
register_property_registry

// Deletion (all corresponding delete_* variants)
```

#### Internal Systems to Preserve
- Entity-Component-System foundation
- Parent-child relationship hierarchy
- Trigger-condition-effect action system
- Context-aware text parsing with player state
- Dynamic property system
- Custom Component<T> trait patterns

---

## Target Architecture: Shinigami Pattern

### Layer 1: Helpers (Pure Utilities)
```
📁 helpers/
├── text_utils.cairo      # Dictionary + text processing
├── random_utils.cairo    # RNG utilities  
├── property_manager.cairo # Dynamic properties
├── validation.cairo      # Input validation
└── data_packer.cairo     # Storage optimization
```
**Responsibility**: Stateless utility functions, no game data access

### Layer 2: Elements (Game Entities)
```
📁 elements/
├── entities/
│   ├── player.cairo      # Player entity behavior
│   ├── area.cairo        # Room/location behavior
│   ├── item.cairo        # Item behavior
│   ├── container.cairo   # Container behavior
│   └── exit.cairo        # Exit behavior
├── descriptors/
│   └── inspectable.cairo # Description behavior
└── relationships/
    └── spatial.cairo     # Spatial relationships
```
**Responsibility**: Individual entity behaviors and traits

### Layer 3: Types (Entry Points)
```
📁 types/
├── entity_type.cairo     # Entity classification
├── command_type.cairo    # Command routing enums
├── action_type.cairo     # Action system types
└── direction_type.cairo  # Movement directions
```
**Responsibility**: Type definitions and routing logic

### Layer 4: Models (Data Persistence)
```
📁 models/
├── player.cairo         # Player state data
├── area.cairo          # Area state data  
├── item.cairo          # Item state data
├── container.cairo     # Container state data
├── exit.cairo          # Exit state data
├── inspectable.cairo   # Description data
├── entity.cairo        # Core entity data
├── relationships.cairo # Relationship data
└── action_system.cairo # Action/trigger/condition/effect data
```
**Responsibility**: Pure data models, no business logic

### Layer 5: Components (Orchestration)
```
📁 components/
├── command_processor.cairo   # Command parsing & routing
├── entity_manager.cairo     # Entity lifecycle management
├── text_parser.cairo        # Natural language processing
├── action_system.cairo      # Trigger-condition-effect orchestration
├── movement_system.cairo    # Navigation logic
├── inventory_system.cairo   # Item management logic
└── interaction_system.cairo # Inspection/use logic
```
**Responsibility**: Multi-model operations with business logic

### Layer 6: Systems (Game Modes)
```
📁 systems/
├── game_engine.cairo      # Main entry (from prompt.cairo)
├── world_builder.cairo    # World creation (from designer.cairo)  
├── standard_mode.cairo    # Default gameplay rules
├── debug_mode.cairo       # Development/testing mode
└── editor_mode.cairo      # World editing mode
```
**Responsibility**: High-level game configuration and rule sets

---

## Migration Strategy

### Phase 1: Foundation (Weeks 1-2)
**Goal**: Establish base layers without breaking changes

**Tasks**:
1. Create `helpers/` layer - move utility functions
2. Create `types/` layer - extract enums and constants  
3. Update imports but maintain current behavior
4. Add comprehensive unit tests for utilities

**Risk Level**: 🟢 Low - No external interface changes  
**Testing**: Unit tests for each helper function  
**Rollback**: Simple - revert file moves

### Phase 2: Models (Weeks 3-4)  
**Goal**: Separate data from behavior

**Tasks**:
1. Create pure data models in `models/` 
2. Extract data structures from current components
3. Maintain all existing fields and relationships
4. Remove behavior logic from data models

**Risk Level**: 🟡 Medium - Internal structure changes  
**Testing**: Data integrity tests, relationship validation  
**Rollback**: Revert to original component structure

### Phase 3: Elements & Components (Weeks 5-7)
**Goal**: Implement business logic separation

**Tasks**:
1. Create `elements/` with focused entity behaviors
2. Create `components/` for orchestration logic
3. Extract business logic from current components
4. Implement clean component interfaces

**Risk Level**: 🟡 Medium - Logic reorganization  
**Testing**: Comprehensive integration tests  
**Rollback**: Revert to Phase 2 state

### Phase 4: Systems (Weeks 8-9)
**Goal**: Refactor entry points while preserving interfaces

**Tasks**:
1. Create `systems/game_engine.cairo` from `prompt.cairo` logic
2. Create `systems/world_builder.cairo` from `designer.cairo` logic
3. **CRITICAL**: Maintain identical external function signatures
4. Route calls through new component layer

**Risk Level**: 🔴 High - External interface preservation critical  
**Testing**: Full frontend integration testing  
**Rollback**: Revert to original systems if frontend breaks

### Phase 5: Optimization & Cleanup (Weeks 10-11)
**Goal**: Optimize and remove legacy code

**Tasks**:
1. Remove original component files
2. Optimize storage and gas usage
3. Update documentation
4. Performance testing and optimization

**Risk Level**: 🟢 Low - Cleanup phase  
**Testing**: Performance benchmarks  
**Rollback**: N/A - optimization only

---

## Risk Assessment & Mitigation

### High Risk Areas

#### 1. External Interface Preservation
**Risk**: Breaking frontend integration  
**Mitigation**: 
- Maintain exact function signatures
- Comprehensive integration testing
- Staged deployment with rollback plan

#### 2. Complex Entity Relationships  
**Risk**: Breaking parent-child hierarchy system  
**Mitigation**:
- Extensive relationship testing
- Data migration validation
- Relationship integrity checks

#### 3. Action System Complexity
**Risk**: Breaking trigger-condition-effect chains  
**Mitigation**:
- Isolated action system testing
- Behavior preservation validation
- Complex scenario testing

#### 4. Performance Regression
**Risk**: Increased gas costs or slower execution  
**Mitigation**:
- Performance benchmarking at each phase
- Gas usage monitoring
- Optimization iterations

### Low Risk Areas
- Utility function extraction
- Type definition organization  
- Documentation updates
- Code style improvements

---

## Technical Requirements

### Development Environment
- **Cairo Version**: 2.10.1 (maintain current)
- **Dojo Version**: 1.5.0 (maintain current)
- **Testing Framework**: Cairo test framework + integration tests
- **Gas Optimization**: Maintain or improve current gas usage

### Code Quality Standards
- **Documentation**: All new functions must have Cairo doc comments
- **Testing**: 90%+ code coverage for new components
- **Error Handling**: Comprehensive error types and messages
- **Performance**: No regression in execution time or gas usage

### Compatibility Requirements  
- **Frontend**: Zero changes required in TypeScript client
- **Blockchain**: Compatible with current Starknet deployment
- **Data**: All existing game state must remain accessible
- **APIs**: All current contract interfaces preserved

---

## Success Validation

### Automated Testing
1. **Unit Tests**: Each helper and component individually tested
2. **Integration Tests**: Full command execution flows
3. **Frontend Tests**: Existing TypeScript test suite passes
4. **Performance Tests**: Gas usage and execution time benchmarks

### Manual Validation
1. **Functional Testing**: All game features work identically  
2. **Edge Case Testing**: Complex scenarios and error conditions
3. **Developer Experience**: New developer onboarding improved
4. **Code Review**: Architecture compliance verification

### Acceptance Criteria Checklist
- [ ] All existing frontend tests pass without modification
- [ ] No breaking changes to external interfaces
- [ ] Shinigami pattern fully implemented across all 6 layers
- [ ] Code coverage >90% for new components
- [ ] Gas usage within 5% of current implementation
- [ ] Developer onboarding documentation complete
- [ ] Migration rollback procedures documented and tested

---

## Dependencies & Constraints

### Dependencies
- **Frontend Stability**: Cannot modify client-side interfaces
- **Data Integrity**: Must preserve all existing game state
- **Performance**: Cannot degrade user experience
- **Cairo Ecosystem**: Must remain compatible with Dojo toolchain

### Constraints  
- **Timeline**: 11-week maximum window
- **Resources**: Development team availability
- **Testing**: Comprehensive testing at each phase required
- **Rollback**: Must be possible at each phase

### External Factors
- **Dojo Updates**: Monitor for framework updates during migration
- **Starknet Changes**: Watch for network upgrades affecting contracts
- **Frontend Development**: Coordinate with frontend team for testing

---

## Post-Migration Benefits

### Short Term (0-3 months)
- Improved code maintainability
- Easier debugging and testing
- Reduced coupling between components
- Better error isolation

### Long Term (3+ months)  
- Faster feature development
- Easier new developer onboarding
- Better code reusability across projects
- Improved testing and validation capabilities
- Foundation for advanced game features

### Strategic Benefits
- **Standardization**: Alignment with Dojo ecosystem best practices
- **Scalability**: Architecture supports complex game features
- **Maintainability**: Reduced technical debt and easier updates
- **Team Velocity**: Improved development speed and quality

---

## Appendix A: Current Contract Analysis

### File Structure Analysis
```
packages/contracts/src/
├── systems/ (2 files - entry points)
├── components/ (6 files - mixed data/logic)  
├── lib/ (15 files - utilities and core systems)
├── constants/ (2 files - definitions)
└── tests/ (testing files)

Total: ~25 Cairo files with mixed responsibilities
```

### Complexity Metrics
- **Lines of Code**: ~3,000 lines across all contracts
- **Cyclomatic Complexity**: High in current components (mixed responsibilities)
- **Coupling**: High between components and command handling
- **Testability**: Limited due to mixed concerns

### Interface Preservation Map
```cairo
// MUST PRESERVE: prompt.cairo interface  
fn prompt(cmd: ByteArray) -> ByteArray

// MUST PRESERVE: designer.cairo interfaces
fn add_component(entity_inst: u32, component_type: ComponentType, ...) 
fn remove_component(entity_inst: u32, component_type: ComponentType)
// ... (20+ designer functions)
```

---

## Appendix B: Migration Scripts & Tools

### Automated Migration Tools
1. **Import Updater**: Script to update import statements
2. **Test Migrator**: Tool to migrate existing tests to new structure  
3. **Interface Validator**: Ensures external interfaces remain unchanged
4. **Gas Benchmark**: Tool to measure performance impact

### Testing Frameworks
1. **Unit Test Suite**: Individual component testing
2. **Integration Test Suite**: Full system behavior validation
3. **Frontend Test Suite**: Client-side compatibility validation
4. **Performance Test Suite**: Gas and execution time monitoring

---

*This PRD serves as the definitive guide for LORE's contract refactoring project. All implementation decisions should reference this document for consistency and alignment with project goals.*