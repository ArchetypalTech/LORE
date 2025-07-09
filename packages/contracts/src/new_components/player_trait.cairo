use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    models::{
        index::{Entity, Inspectable, Container, Player, PlayerStory}, components::Component,
        inspectable::InspectableComponent, container::ContainerComponent,
    },
    new_components::{entity_trait::EntityImpl, inspectable_trait::InspectableImpl},
    constants::errors::Error,
};


#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    fn describe_room(mut self: @Player, mut world: WorldStorage) -> Result<(), Error> {
        let context = self.get_context(@world);
        let room = self.get_room(@world);
        if room.is_none() {
            return Result::Err(Error::ActionFailed);
        }
        self.say(world, format!("{}", room.unwrap().name));
        for item in context {
            // Don't add the player to the description
            if (item.inst == *self.inst) {
                continue;
            }
            let inspectable_opt: Option<Inspectable> = Component::get_component(world, item.inst);
            if inspectable_opt.is_some() {
                let mut inspectable = inspectable_opt.unwrap();
                if inspectable.already_shown {
                    self.say(world, format!("{}", inspectable.new_entry));
                } else {
                    let description = inspectable.get_first_description(world);
                    self.say(world, format!("{}", description));
                    inspectable.already_shown = true;
                    inspectable.store(world);
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
        world.write_model(@self);
        if self.use_debug {
            self.clone().say(world, format!("You {:?} enter {:?}", ent, room));
        }
    }

    // TODO: improve name and better description
    fn say(mut self: @Player, mut world: WorldStorage, text: ByteArray) {
        const MAX_LENGTH_LIMIT: usize = 2000;
        let new_text_len = text.len();
        let mut total_len = 0;

        loop {
            let playerStoryLoop: PlayerStory = world.read_model(*self.inst);
            let mut storyLine = playerStoryLoop.story.clone();

            total_len = 0;
            for line in storyLine.clone() {
                total_len += line.len();
            };

            if *self.use_debug {
                self.clone().say(world, format!("Total length: {:?}", total_len));
                self.clone().say(world, format!("New text length: {:?}", new_text_len));
            }

            if total_len + new_text_len <= MAX_LENGTH_LIMIT {
                storyLine.append(text);
                world.write_model(@PlayerStory { inst: *self.inst, story: storyLine });
                break;
            }

            if storyLine.len() == 0 {
                // Edge case: nothing left to remove, but still too large
                break;
            }

            let removed = storyLine.pop_front();
            total_len -= removed.unwrap().len();
            if *self.use_debug {
                self.clone().say(world, format!("Total length after pop: {:?}", total_len));
            }

            world.write_model(@PlayerStory { inst: *self.inst, story: storyLine });
        }
    }


    fn add_command_text(mut self: @Player, mut world: WorldStorage, text: ByteArray) {
        let mut playerStory: PlayerStory = world.read_model(*self.inst);
        let mut storyLine = playerStory.story.clone();
        if (storyLine.len() > 10) {
            let _ = storyLine.pop_front();
        }
        storyLine.append(format!("> {}", text));
        world.write_model(@PlayerStory { inst: *self.inst, story: storyLine });
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
