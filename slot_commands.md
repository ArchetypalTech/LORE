# Creating katana slot service

## development
slot d create lore-v3 katana --dev --dev.no-fee --cartridge.controllers --cartridge.paymaster

## Staging
slot d create lore-staging katana --dev --dev.no-fee --cartridge.controllers --cartridge.paymaster


# Creating torii slot service

## development
slot d create lore-v3 torii --world 0x5c3d1e0a776820633ffe4139dd851e3b578ea06ec4458c354059253ac857c01 --rpc https://api.cartridge.gg/x/lore-v3/katana --indexing.transactions --indexing.contracts erc721:0x0186b579a7737f0bff938016263bed78a587a7db297e1bda2106cba34f817649 --sql.historical lore-TrophyProgression

## Staging
slot d create lore-stage torii --world 0x1142a4bd443a08f68936caf2e6b5d32121eb3b0327ff5a75b0b92d50cbdc913 --rpc https://api.cartridge.gg/x/lore-stage/katana --indexing.transactions --indexing.contracts erc721:0x02fa73d2c20fef6f23a84f3ef3b6e99ec2fa819f0b5acf2be6695544b87922e5 --sql.historical lore-TrophyProgression