- [ ] write additional extensions in Utils.ts (used in lexer postprocessing)

  - [ ] ends_with(string)
  - [ ] starts_with(string)
  - [ ] contains(string)
  - [ ] to_lowercase()

- [ ] implement map and filter function paradigms from Cairo docs : https://book.cairo-lang.org/ch11-01-closures.html

###

- [ ] Components
  - [ ] More generic implementations to avoid having to rewrite all fn for each component type
  - [ ] Entity handlers, to move easily between entity and component i.e. ->
    - player.entity(world).get_parent(world)
    - inspectable.entity(world).get_component(world)
