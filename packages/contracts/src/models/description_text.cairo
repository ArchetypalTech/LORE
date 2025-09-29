
#[derive(Clone, Drop, Serde, Introspect, PartialEq, Debug)]
#[dojo::model]
pub struct DescriptionText {
    /// Unique identifier from the Entity it is attached to
    #[key]
    pub inst: felt252,
    /// Unique identifier of the description
    #[key]
    pub key: u32,
    /// Description text
    pub text: ByteArray,
}

