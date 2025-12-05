pub mod systems {
    pub mod permit_token;
    pub mod fact_registry_mock;
}

pub mod components {
    pub mod coin_component;
    pub mod coin_config;
}

pub mod models {
    pub mod actions_supply;
    pub mod messaging;
    pub mod constants;
}

pub mod lib {
    pub mod dns;
}

#[cfg(test)]
pub mod tests {
    pub mod helpers;
    pub mod permit_token_test;
}
