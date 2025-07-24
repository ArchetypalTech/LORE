use dojo::{world::WorldStorage, model::ModelStorage};
use lore::{
    models::{
        index::{Entity, Inspectable, Container, Player, PlayerStory, StoryLine},
        components::Component, inspectable::InspectableComponent, container::ContainerComponent,
        player::PlayerComponent,
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
        let mut player: Player = world.read_model(*self.inst);
        let mut counter: u32 = player.story_line;
        let increase: u32 = 1;
        let new_counter: u32 = counter + increase;

        let story_line = StoryLine {
            inst: *self.inst,
            key: new_counter,
            line: text,
        };
        world.write_model(@story_line);

        let mut player_story: PlayerStory = world.read_model(*self.inst);
        player_story.story.append(new_counter);
        world.write_model(@player_story);

        // Update the player
        let mut player: Player = world.read_model(*self.inst);
        player.story_line = new_counter;
        player.store(world);
        // try to store only the story variable but doesn't work
        // world.write_member(Model::<PlayerStory>::ptr_from_keys(self.inst), selector!("story"),
        // @player_story.story);
    }


    fn add_command_text(mut self: @Player, mut world: WorldStorage, text: ByteArray) {
        // read counter from player
        let mut counter = *self.story_line;
        // increase counter
        let increase: u32 = 1;
        counter += increase;
        // create new story line
        let mut story_line = StoryLine { inst: *self.inst, key: counter, line: text };
        // write story line to world
        world.write_model(@story_line);
        // add story line to player story
        let mut player_story: PlayerStory = world.read_model(*self.inst);
        player_story.story.append(counter);
        // update player_story.story
        world.write_model(@player_story);
        // let mut playerStory: PlayerStory = world.read_model(*self.inst);
    // let mut storyLine = playerStory.story.clone();
    // if (storyLine.len() > 10) {
    //     let _ = storyLine.pop_front();
    // }
    // storyLine.append(format!("> {}", text));
    // world.write_model(@PlayerStory { inst: *self.inst, story: storyLine });
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
