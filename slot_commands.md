# Creating katana slot service

## development
slot d create lore-v3 katana --dev --dev.no-fee --cartridge.controllers --cartridge.paymaster

## Staging
slot d create lore-staging katana --dev --dev.no-fee --cartridge.controllers --cartridge.paymaster


# Creating torii slot service

## development
slot d create lore-v3 torii --world 0x5c3d1e0a776820633ffe4139dd851e3b578ea06ec4458c354059253ac857c01 --rpc https://api.cartridge.gg/x/lore-v3/katana --indexing.transactions --indexing.contracts erc721:0x0186b579a7737f0bff938016263bed78a587a7db297e1bda2106cba34f817649

## Staging
slot d create lore-staging torii --world 0x3ea527a0ef282892e25d18ca267e0cb81c88f02bb7b05e84c94414f7fc716de --rpc https://api.cartridge.gg/x/lore-staging/katana --indexing.transactions --indexing.contracts erc721:0x0325a05094c34c2ae74c2611fe09600c928a1f5865e161583e4380c71bb3e12f