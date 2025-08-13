use dojo::world::WorldStorage;
use lore::{
    models::index::Player,
    new_components::player_trait::PlayerImpl,
    constants::errors::Error,
    lib::random::random_text,
};

#[generate_trait]
pub impl ErrorOutputterImpl of ErrorOutputterTrait {
    fn output_error(self: Error, player: Player, world: WorldStorage) {
        let texts = match self {
            Error::Unimplemented => array!["This is not ready yet"],

            Error::NameNotMatch => array![
                "Does not exist",
                "No, that only exists in your mind",
                "What are you referring to?",
                "What do you mean?"
            ],

            Error::DirectionNotMatch => array![
                "No, wrong direction",
                "Can you even go there?",
                "You can't go there"
            ],

            Error::Unenterable => array![
                "You can't go there",
                "It's not open",
                "It's closed",
                "It's unenterable"
            ],

            Error::FailToReactTo => array![
                "Nothing happens if it's not reactable",
                "You can't imagine things",
                "That only happens in your imagination"
            ],

            Error::NoTarget => array![
                "What are you trying to look at?",
                "Looking at what?",
                "You can't look at the nothingness"
            ],

            Error::NotOpen => array!["It's not open", "It's closed"],

            Error::ContainerFull => array![
                "It's already full",
                "You can't put anything more in there",
                "You can't store anything more",
                "Can't exceed capacity limit"
            ],

            Error::CantStore => array![
                "It can't store",
                "Is that even possible?",
                "Can't store anything here"
            ],

            Error::NoContainer => array![
                "That is not a container",
                "It's not a container",
                "It doesn't have an extradimensional space"
            ],

            Error::NoPersonalContainer => array![
                "You don't have a personal container",
                "You are not a blackhole, therefore you can't do that",
                "You don't have magical pockets to do that"
            ],

            Error::CantBePicked => array![
                "It can't be picked",
                "Its weight is something not from this world",
                "It won't budge in this lifetime"
            ],

            Error::CantBeStored => array![
                "It can't be stored",
                "It won't fit anywhere",
                "That won't happen"
            ],

            Error::AlreadyStored => array![
                "It's already there",
                "You already have it",
                "You already have that"
            ],

            Error::NotStored => array![
                "It's not there",
                "You don't have it",
                "You don't have that"
            ],

            Error::NoRoom => array![
                "You are in the LIMBO, you exist but don't exist",
                "The void surrounds you as you can't escape",
                "Darkness envelops you, you can't see the light"
            ],

            Error::NoTargetEntity | Error::ActionFailed => array![
                "I don't know what that means",
                "Nope",
                "Can you repeat that?",
                "I'm at a loss",
                "You're not helping",
                "I can't imagine"
            ],

            Error::NoPlayerComponent => array![
                "It doesn't have a player component",
                "It is not a player, therefore you can't do that"
            ],

            Error::NoContainerComponent => array![
                "It doesn't have a container component",
                "It is not a container, therefore you can't do that"
            ],

            Error::NoInventoryItemComponent => array![
                "It doesn't have an inventory item component",
                "It is not an inventory item, therefore you can't do that"
            ],

            Error::NoReactableComponent => array![
                "It doesn't have a reactable component",
                "It is not a reactable, therefore you can't do that"
            ],

            Error::NoExitComponent => array![
                "It doesn't have an exit component",
                "It is not an exit, therefore you can't do that"
            ],

            Error::NoAreaComponent => array![
                "It doesn't have an area component",
                "It is not an area, therefore you can't do that"
            ],

            Error::NoComponent => array![
                "It doesn't have a component",
                "It is not a component, therefore you can't do that"
            ],

            _ => array![], // For errors with no message
        };

        if texts.len() > 0 {
            player.say(world, random_text(world, texts));
        }
    }
}