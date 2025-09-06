use dojo::{world::WorldStorage, model::{Model, ModelStorage}};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Instance, Component},
        player::{Player},
    },
    lib::game_instance::{GameImpl},
    types::{command_type::Command},
    constants::errors::Error,
};

#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct Area {
    #[key]
    pub inst: felt252,
    pub is_area: bool,
    /// Properties ///
    /// If the area is a spawn point for players
    pub is_spawn_point: bool,
}


//---------------------------------
// Component
//
pub impl AreaInstance of Instance<Area> {
    #[inline(always)]
    fn inst(self: @Area) -> felt252 {
        (*self.inst)
    }

    #[inline(always)]
    fn is_component(self: @Area) -> bool {
        (*self.is_area)
    }

    fn has_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<Area>::ptr_from_keys(inst), selector!("is_area")))
    }
}

pub impl AreaComponent of Component<Area> {
    type ComponentType = Area;

    fn entity(self: @Area, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst()).unwrap()
    }

    fn get_component(world: @WorldStorage, inst: felt252, game_id: u128) -> Option<Area> {
        let area: Area = world.read_game_inst(inst, game_id);
        if (area.is_component()) {
            Option::Some(area)
        } else {
            Option::None
        }
    }

    fn store(self: @Area, ref world: WorldStorage, game_id: u128) {
        // world.write_model(self);
        world.write_game_inst(self, game_id);
    }

    fn can_use_command(
        self: @Area, world: @WorldStorage, player: @Player, command: @Command,
    ) -> bool {
        true
    }

    fn execute_command(
        self: Area, ref world: WorldStorage, player: @Player, command: @Command,
    ) -> Result<(), Error> {
        // println!("Area execute_command");
        Result::Err(Error::Unimplemented)
    }

    // used for tests only
    fn add_component(ref world: WorldStorage, inst: felt252, game_id: u128) -> Area {
        let mut area: Area = world.read_model(inst);
        area.inst = inst;
        area.is_area = true;
        area.store(ref world, game_id);
        // Return the component
        area
    }
}



#[cfg(test)]
mod tests {
    // use dojo::{model::ModelStorage};
    use super::*;
    use lore::{
        tests::helpers,
        models::{
            entity::{EntityImpl},
        },
        lib::game_instance::{GameImpl},
    };

    #[test]
    fn test_area_create() {
        let (mut world, _, _, _, _) = helpers::setup_core();
        let game_id: u128 = 0;
        let area: Area = AreaComponent::add_component(ref world, 1, game_id);
        assert(area.is_area, 'area is area');
        assert(area.inst == 1, 'area.inst == 1');
        assert(AreaInstance::has_component(@world, area.inst), 'has_component()');
        let component: Option<Area> = AreaComponent::get_component(@world, area.inst, 0);
        assert(component.is_some(), 'component.is_some()');
        assert(component.unwrap().inst() == area.inst, 'component.is_some()');
    }

    #[test]
    fn test_area_game_inst() {
        let (mut world, _, _, _, _) = helpers::setup_core();
        //
        // create area
        let area: Area = AreaComponent::add_component(ref world, 1, 0);
        assert!(area.is_area);
        //
        // read game inst version, same as inst
        let comp_inst: Area = world.read_game_inst(area.inst, 0);
        let mut comp_game: Area = world.read_game_inst(area.inst, 1);
        assert!(comp_inst.is_component(), "baseline");
        assert!(comp_game.is_component(), "baseline");
        assert_eq!(comp_inst.inst(), area.inst, "baseline");
        assert_eq!(comp_game.inst(), area.inst, "baseline");
        assert_eq!(comp_game.is_spawn_point, false, "baseline");
        //
        // save game inst version
        comp_game.is_spawn_point = true;
        world.write_game_inst(@comp_game, 1);
        world.write_game_inst(@comp_inst, 0);
        // inst does not change!
        assert_eq!(comp_inst.inst(), area.inst, "saved");
        assert_eq!(comp_game.inst(), area.inst, "saved");
        //
        // read game inst version, updated, original is preserved
        let new_comp_inst: Area = world.read_game_inst(area.inst, 0);
        let new_comp_game: Area = world.read_game_inst(area.inst, 1);
        assert!(new_comp_inst.is_component(), "new_component");
        assert!(new_comp_game.is_component(), "new_component");
        assert_eq!(new_comp_inst.inst(), area.inst, "new_component");
        assert_eq!(new_comp_game.inst(), area.inst, "new_component");
        assert_eq!(new_comp_inst.is_spawn_point, false, "new_component");
        assert_eq!(new_comp_game.is_spawn_point, true, "new_component");
    }

    #[test]
    fn test_area_game_comp() {
        let (mut world, _, _, _, _) = helpers::setup_core();
        //
        // create area
        let area: Area = AreaComponent::add_component(ref world, 1, 0);
        assert!(area.is_area);
        //
        // read game inst version, same as inst
        let comp_null: Option<Area> = AreaComponent::get_component(@world, 1234, 0);
        let comp_inst: Option<Area> = AreaComponent::get_component(@world, area.inst, 0);
        let comp_game: Option<Area> = AreaComponent::get_component(@world, area.inst, 1);
        assert!(comp_null.is_none(), "null");
        assert!(comp_inst.is_some(), "baseline");
        assert!(comp_game.is_some(), "baseline");
        let comp_inst: Area = comp_inst.unwrap();
        let mut comp_game: Area = comp_game.unwrap();
        assert!(comp_inst.is_component(), "baseline");
        assert!(comp_game.is_component(), "baseline");
        assert_eq!(comp_inst.inst(), area.inst, "baseline");
        assert_eq!(comp_game.inst(), area.inst, "baseline");
        assert_eq!(comp_game.is_spawn_point, false, "baseline");
        //
        // save game inst version
        comp_game.is_spawn_point = true;
        comp_game.store(ref world, 1);
        comp_inst.store(ref world, 0);
        // inst does not change!
        assert_eq!(comp_inst.inst(), area.inst, "saved");
        assert_eq!(comp_game.inst(), area.inst, "saved");
        //
        // read game inst version, updated, original is preserved
        let new_comp_inst: Option<Area> = AreaComponent::get_component(@world, area.inst, 0);
        let new_comp_game: Option<Area> = AreaComponent::get_component(@world, area.inst, 1);
        assert!(new_comp_inst.is_some(), "new_component");
        assert!(new_comp_game.is_some(), "new_component");
        let new_comp_inst: Area = new_comp_inst.unwrap();
        let new_comp_game: Area = new_comp_game.unwrap();
        assert!(new_comp_inst.is_component(), "new_component");
        assert!(new_comp_game.is_component(), "new_component");
        assert_eq!(new_comp_inst.inst(), area.inst, "new_component");
        assert_eq!(new_comp_game.inst(), comp_game.inst(), "new_component");
        assert_eq!(new_comp_inst.is_spawn_point, false, "new_component");
        assert_eq!(new_comp_game.is_spawn_point, true, "new_component");
    }
}
