#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct ParentToChildren {
    #[key]
    pub inst: felt252,
    pub is_parent: bool,
    // properties
    pub children: Array<felt252>,
}

#[derive(Clone, Drop, Serde, Introspect)]
#[dojo::model]
pub struct ChildToParent {
    #[key]
    pub inst: felt252,
    pub is_child: bool,
    // properties
    pub parent: felt252,
}

