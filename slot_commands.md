# THIS SHOULD BE DONE INSIDE /packages/contracts
# Creating katana slot service

## development AKA orug-slot
slot d create orug-slot katana --dev --dev.no-fee --cartridge.controllers --cartridge.paymaster

## Staging AKA lore-stage
slot d create lore-staging katana --dev --dev.no-fee --cartridge.controllers --cartridge.paymaster


# Creating torii slot service

## development AKA orug-slot
slot d create orug-slot torii --world 0x710c2c00bbec1d59cabd2f99fdc4f266530be026cf96a37bae4ddf0715031c --rpc https://api.cartridge.gg/x/orug-slot/katana --indexing.transactions --indexing.contracts erc721:0x04a8a5ba466533ff3a29533213fb8f4eef4fa61792cbe71ddc072808d46f4703 --sql.historical lore-TrophyProgression

# OR 
slot d create orug-slot torii --config ./config_torii_slot.toml

## Staging AKA lore-stage
slot d create lore-stage torii --world 0x1142a4bd443a08f68936caf2e6b5d32121eb3b0327ff5a75b0b92d50cbdc913 --rpc https://api.cartridge.gg/x/lore-stage/katana --indexing.transactions --indexing.contracts erc721:0x02fa73d2c20fef6f23a84f3ef3b6e99ec2fa819f0b5acf2be6695544b87922e5 --sql.historical lore-TrophyProgression

# OR 
slot d create lore-stage torii --config ./config_torii_stage.toml