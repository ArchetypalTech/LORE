# Creating katana slot service

## development
slot d create lore-v3 katana --dev --dev.no-fee --cartridge.controllers --cartridge.paymaster

## Staging
slot d create lore-staging katana --dev --dev.no-fee --cartridge.controllers --cartridge.paymaster


# Creating torii slot service

## development
slot d create lore-v3 torii --world 0x5c3d1e0a776820633ffe4139dd851e3b578ea06ec4458c354059253ac857c01 --rpc https://api.cartridge.gg/x/lore-v3/katana --indexing.transactions --indexing.contracts erc721:0x0186b579a7737f0bff938016263bed78a587a7db297e1bda2106cba34f817649

## Staging
slot d create lore-staging torii --world 0xc78460f5ff06e806f956d410c70e3c26c3948f34356eca4c401f1f8ded5dc --rpc https://api.cartridge.gg/x/lore-staging/katana --indexing.transactions --indexing.contracts erc721:0x02e7076c4edfe7e9bb0d896357e413de1c62e666dbc6f6985c8d2d0da2a34d1b