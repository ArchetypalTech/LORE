use lore::models::index::Exit;


#[generate_trait]
pub impl ExitImpl of ExitTrait {
    fn is_exit(self: Exit) -> bool {
        self.is_exit
    }

    fn can_player_enter(self: Exit) -> bool {
        self.is_enterable
    }
}
