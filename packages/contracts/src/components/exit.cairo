use lore::constants::constants::Direction;

#[derive(Clone, Drop, Serde, Debug, Introspect, PartialEq)]
#[dojo::model]
pub struct Exit {
    #[key]
    pub inst: felt252,
    pub is_exit: bool,
    // properties
    pub is_enterable: bool,
    pub leads_to: felt252,
    pub direction_type: Direction,
    pub action_map: Array<ByteArray>,
}

#[generate_trait]
pub impl ExitImpl of ExitTrait {
    fn is_exit(self: Exit) -> bool {
        self.is_exit
    }

    fn get_action_map(self: Exit) -> Array<ByteArray> {
        self.action_map
    }

    fn can_player_enter(self: Exit) -> bool {
        self.is_enterable
    }
}
