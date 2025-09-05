use dojo::{world::WorldStorage, model::ModelStorage, model::Model};
use lore::{
    models::{
        index::{Entity, Reactable, Container, Player, PlayerStory, StoryLine},
        components::Component, reactable::ReactableComponent, container::ContainerComponent,
        player::PlayerComponent,
    },
    new_components::{entity_trait::EntityImpl, reactable_trait::ReactableImpl},
    constants::errors::Error,
};


#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    fn describe_room(mut self: @Player, mut world: WorldStorage) -> Result<(), Error> {
        let context = self.get_context(@world);
        let room = self.get_room(@world);
        if room.is_none() {
            return Result::Err(Error::NoRoom);
        }
        self.say(world, format!("{}", room.unwrap().name));
        for item in context {
            // Don't add the player to the description
            if (item.inst == *self.inst) {
                continue;
            }
            let reactable_opt: Option<Reactable> = Component::get_component(world, item.inst);
            if reactable_opt.is_some() {
                let mut reactable = reactable_opt.unwrap();
                if reactable.is_visible {
                    if reactable.already_shown {
                        self.say(world, format!("{}", reactable.new_entry));
                    } else {
                        let description = reactable.get_first_description(world);
                        self.say(world, format!("{}", description));
                        reactable.already_shown = true;
                        world
                            .write_member(
                                Model::<Reactable>::ptr_from_keys(reactable.inst),
                                selector!("already_shown"),
                                reactable.already_shown,
                            );
                        // reactable.store(world);
                    }
                }
            }
        };
        Result::Ok(())
    }

    fn move_to_room(mut self: Player, mut world: WorldStorage, room_id: felt252) {
        self.location = room_id;
        let ent: Entity = EntityImpl::get_entity(@world, @self.inst).unwrap();
        let room = EntityImpl::get_entity(@world, @room_id).unwrap();
        ent.set_parent(world, @room);
        world
            .write_member(
                Model::<Player>::ptr_from_keys(self.inst), selector!("location"), self.location,
            );
        //world.write_model(@self);
        if self.use_debug {
            self.clone().say(world, format!("You {:?} enter {:?}", ent, room));
        }
    }

    // TODO: improve name and better description
    fn say(self: @Player, mut world: WorldStorage, text: ByteArray) {
        let mut story: PlayerStory = world.read_model(*self.inst);
        // Get the current story line counter
        let counter: u32 = story.story_line;
        let increase: u32 = 1;
        // Increase the counter
        let new_counter: u32 = counter + increase;
        // Create a new story line
        let story_line = StoryLine { inst: *self.inst, key: new_counter, line: text };
        world.write_model(@story_line);

        // Set the new story line counter
        story.story_line = new_counter;
        world
            .write_member(
                Model::<PlayerStory>::ptr_from_keys(*self.inst),
                selector!("story_line"),
                story.story_line,
            );
    }


    fn add_command_text(self: @Player, mut world: WorldStorage, text: ByteArray) {
        // read counter from PlayerStory
        let mut story: PlayerStory = world.read_model(*self.inst);
        let mut counter = story.story_line;
        // increase counter
        let increase: u32 = 1;
        let new_counter = counter + increase;
        // create new story line
        let mut story_line = StoryLine { inst: *self.inst, key: new_counter, line: text };
        // write story line to world
        world.write_model(@story_line);

        // update PlayerStory
        story.story_line = new_counter;
        world
            .write_member(
                Model::<PlayerStory>::ptr_from_keys(*self.inst),
                selector!("story_line"),
                story.story_line,
            );
    }

    fn get_room(self: @Player, world: @WorldStorage) -> Option<Entity> {
        let player_entity: Entity = EntityImpl::get_entity(world, self.inst).unwrap();
        let parent = player_entity.get_parent(world);
        if parent.is_none() {
            return Option::None;
        }
        parent
    }

    // Get the 1st level context of the room
    fn get_context(self: @Player, world: @WorldStorage) -> Array<Entity> {
        match self.get_room(world) {
            Option::Some(room) => {
                let mut context: Array<Entity> = array![];
                context.append(room.clone());
                let children = room.get_children(world);
                // Go over 1st level children
                for child in children.clone() {
                    context.append(child.clone());
                };
                context
            },
            Option::None => array![],
        }
    }

    // Get the full context of the room
    fn get_full_context(self: @Player, world: @WorldStorage) -> Array<Entity> {
        match self.get_room(world) {
            Option::Some(room) => {
                let mut context: Array<Entity> = array![];
                context.append(room.clone());
                let children = room.get_children(world);
                // Go over 1st level children
                for child in children.clone() {
                    context.append(child.clone());
                    // Go over 2nd level children
                    let children_2 = child.get_children(world);
                    for child_2 in children_2 {
                        context.append(child_2.clone());
                        // Go over 3rd level children
                        let children_3 = child_2.get_children(world);
                        for child_3 in children_3 {
                            context.append(child_3);
                        }
                    };
                };
                context
            },
            Option::None => array![],
        }
    }

    // Get the player personal inventory container component
    fn get_personal_container(self: @Player, world: @WorldStorage) -> Option<Container> {
        let mut personal_container: Option<Container> = Option::None;
        match ContainerComponent::get_component(*world, *self.inst) {
            Option::Some(c) => { personal_container = Option::Some(c); },
            Option::None => {
                personal_container = Option::None;
                self.say(*world, format!("You don't have a personal inventory container"));
            },
        }
        personal_container
    }
}
