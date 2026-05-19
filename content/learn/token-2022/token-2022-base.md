---
slug: token-2022-base
category: token-2022
name: Token-2022 Mint/Account + Extensions
kind: account
status: draft
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 165
summary: Same base layout as SPL Token, followed by extension blocks (TLV) — TransferFee, InterestBearing, ConfidentialTransfer, MetadataPointer, and more.
example_address: 2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo
example_label: PYUSD (Token-2022)
fields:
  - base_fields
  - discriminator_165
  - account_type
  - extension_tlv
see_also:
  - mint
  - token-account
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/mod.rs
    label: Token-2022 extension TLV layout
last_verified: 2026-05-19
---
