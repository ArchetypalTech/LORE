use dojo::{world::WorldStorage, model::{Model, ModelStorage}};
use lore::{
    models::{
        entity::{Entity, EntityImpl},
        components::{Component},
        game_instance::{Instance, GameModelImpl},
        player::{Player},
    },
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
    /// progress percentage when entering this area
    pub progress_percentage: u8, // 0-100
    /// when entering, preserve original children (editors can add children to this area)
    pub preserve_children: bool,
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
    fn set_inst(ref self: Area, new_inst: felt252) {
        self.inst = new_inst;
    }
    #[inline(always)]
    fn is_component(self: @Area) -> bool {
        (*self.is_area)
    }
    fn has_component(self: @WorldStorage, inst: felt252) -> bool {
        (inst != 0 && self.read_member(Model::<Area>::ptr_from_keys(inst), selector!("is_area")))
    }
    fn is_partially_mapped() -> bool {
        (true)
    }
    fn partially_map_from(ref self: Area, game_model: @Area) {
        // map properties declared in VariablePropertyHelperTrait::register_properties()
        self.is_area = *game_model.is_area;
        self.is_spawn_point = *game_model.is_spawn_point;
    }
}

pub impl AreaComponent of Component<Area> {
    type ComponentType = Area;

    fn entity(self: @Area, world: @WorldStorage) -> Entity {
        EntityImpl::get_entity(world, self.inst()).unwrap()
    }

    fn get_component(world: @WorldStorage, inst: felt252, game_id: u128) -> Option<Area> {
        let area: Area = world.read_game_model(inst, game_id);
        if (area.is_component()) {
            Option::Some(area)
        } else {
            Option::None
        }
    }

    fn store(self: @Area, ref world: WorldStorage, game_id: u128) {
        world.write_game_model(self, game_id);
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
    fn add_component(ref world: WorldStorage, inst: felt252) -> Area {
        let mut area: Area = world.read_model(inst);
        area.inst = inst;
        area.is_area = true;
        area.progress_percentage = 0;
        area.preserve_children = false;
        area.store(ref world, 0);
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
            game_instance::{GameModelImpl, GameInstanceMap},
        },
    };

    #[test]
    fn test_area_create() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        let area: Area = AreaComponent::add_component(ref sys.world, 1);
        assert(area.is_area, 'area is area');
        assert(area.inst == 1, 'area.inst == 1');
        assert(AreaInstance::has_component(@sys.world, area.inst), 'has_component()');
        let component: Option<Area> = AreaComponent::get_component(@sys.world, area.inst, 0);
        assert(component.is_some(), 'component.is_some()');
        assert(component.unwrap().inst() == area.inst, 'component.is_some()');
    }

    #[test]
    fn test_area_game_inst() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create area
        let area: Area = AreaComponent::add_component(ref sys.world, 111);
        assert!(area.is_area);
        assert_eq!(area.inst, 111);
        //
        // read game inst version, same as inst
        let game_id: u128 = 222;
        let comp_inst: Area = sys.world.read_game_model(area.inst, 0);
        let mut comp_game: Area = sys.world.read_game_model(area.inst, game_id);
        assert!(comp_inst.is_component(), "baseline");
        assert!(comp_game.is_component(), "baseline");
        assert_eq!(comp_inst.inst(), area.inst, "baseline");
        assert_eq!(comp_game.inst(), area.inst, "baseline");
        assert_eq!(comp_game.is_spawn_point, false, "baseline");
        assert_eq!(comp_game.preserve_children, false, "baseline");
        // GameInstanceMap model does not exist yet
        let map: GameInstanceMap = sys.world.read_model((game_id, area.inst),);
        assert_eq!(map.game_inst, 0, "baseline");
        //
        // save game inst version
        comp_game.is_spawn_point = true;
        sys.world.write_game_model(@comp_game, game_id);
        sys.world.write_game_model(@comp_inst, 0);
        // inst does not change!
        assert_eq!(comp_inst.inst(), area.inst, "saved");
        assert_eq!(comp_game.inst(), area.inst, "saved");
        // GameInstanceMap was created
        let map: GameInstanceMap = sys.world.read_model((game_id, area.inst),);
        assert_ne!(map.game_inst, 0, "saved");
        //
        // read game inst version, updated, original is preserved
        let new_comp_inst: Area = sys.world.read_game_model(area.inst, 0);
        let new_comp_game: Area = sys.world.read_game_model(area.inst, game_id);
        assert!(new_comp_inst.is_component(), "new_component");
        assert!(new_comp_game.is_component(), "new_component");
        assert_eq!(new_comp_inst.inst(), area.inst, "new_component");
        assert_eq!(new_comp_game.inst(), area.inst, "new_component");
        assert_eq!(new_comp_inst.is_spawn_point, false, "new_component");
        assert_eq!(new_comp_game.is_spawn_point, true, "new_component");
    }

    #[test]
    fn test_area_game_comp() {
        let mut sys: helpers::HelperSystems = helpers::setup_core();
        //
        // create area
        let area: Area = AreaComponent::add_component(ref sys.world, 111);
        assert!(area.is_area);
        assert_eq!(area.inst, 111);
        //
        // read game inst version, same as inst
        let game_id: u128 = 222;
        let comp_null: Option<Area> = AreaComponent::get_component(@sys.world, 1234, 0);
        let comp_inst: Option<Area> = AreaComponent::get_component(@sys.world, area.inst, 0);
        let comp_game: Option<Area> = AreaComponent::get_component(@sys.world, area.inst, game_id);
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
        // GameInstanceMap model does not exist yet
        let map: GameInstanceMap = sys.world.read_model((game_id, area.inst),);
        assert_eq!(map.game_inst, 0, "baseline");
        //
        // save game inst version
        comp_game.is_spawn_point = true;
        comp_game.store(ref sys.world, game_id);
        comp_inst.store(ref sys.world, 0);
        // inst does not change!
        assert_eq!(comp_inst.inst(), area.inst, "saved");
        assert_eq!(comp_game.inst(), area.inst, "saved");
        // GameInstanceMap was created
        let map: GameInstanceMap = sys.world.read_model((game_id, area.inst),);
        assert_ne!(map.game_inst, 0, "saved");
        //
        // read game inst version, updated, original is preserved
        let new_comp_inst: Option<Area> = AreaComponent::get_component(@sys.world, area.inst, 0);
        let new_comp_game: Option<Area> = AreaComponent::get_component(@sys.world, area.inst, game_id);
        assert!(new_comp_inst.is_some(), "new_component");
        assert!(new_comp_game.is_some(), "new_component");
        let new_comp_inst: Area = new_comp_inst.unwrap();
        let new_comp_game: Area = new_comp_game.unwrap();
        assert!(new_comp_inst.is_component(), "new_component");
        assert!(new_comp_game.is_component(), "new_component");
        assert_eq!(new_comp_inst.inst(), area.inst, "new_component");
        assert_eq!(new_comp_game.inst(), area.inst, "new_component");
        assert_eq!(new_comp_inst.is_spawn_point, false, "new_component");
        assert_eq!(new_comp_game.is_spawn_point, true, "new_component");
    }
}
