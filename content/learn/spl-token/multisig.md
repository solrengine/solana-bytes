---
slug: multisig
category: spl-token
name: Multisig
kind: account
status: draft
program_id: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
program_label: Token Program
size: 355
summary: An m-of-n multi-signature account that can act as any authority on a Mint or Token Account. Up to 11 signers; m signatures required.
example_address: BJE5MMbqXjVwjAF7oxwPYXnTXDyspzZyt4vwenNw5ruG
example_label: USDC Mint Authority
fields:
  - m
  - n
  - is_initialized
  - signers
see_also:
  - mint
  - token-account
sources:
  - url: https://github.com/solana-program/token/blob/main/program/src/state.rs
    label: SPL Token Multisig struct (program/src/state.rs)
last_verified: 2026-05-19
---
