---
slug: mint
category: spl-token
name: Mint
kind: account
status: live
program_id: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
program_label: Token Program
size: 82
summary: Describes a token — its authority, total supply, decimals, and optional freeze authority. USDC, USDT, and wrapped SOL all have Mint accounts.
example_address: EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
example_label: USDC Mint
fields:
  - mint_authority
  - supply
  - decimals
  - is_initialized
  - freeze_authority
see_also:
  - token-account
  - multisig
sources:
  - url: https://github.com/solana-program/token/blob/main/program/src/state.rs
    label: SPL Token Mint struct (program/src/state.rs)
last_verified: 2026-05-19
---

## What it is

An SPL Mint account defines a fungible token on Solana — its authority, total supply, decimals, and optional freeze authority. USDC, USDT, and wrapped SOL are all defined by Mint accounts.

## Why it exists

Solana doesn't ship a built-in token primitive. The SPL Token program treats every fungible token the same way: each token has exactly one Mint account holding the canonical metadata, and many Token Accounts holding individual balances. This separation is what lets the same token live in millions of wallets without re-storing the metadata each time.

## Byte layout

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 36 | `mint_authority` | `COption<Pubkey>` | 4-byte tag (`0` = None, `1` = Some) + 32-byte pubkey. When None, minting is permanently locked. |
| 36 | 8 | `supply` | `u64` LE | Total atomic units in circulation. Divide by `10^decimals` for human-readable amount. |
| 44 | 1 | `decimals` | `u8` | Exponent — e.g., USDC's `6` means 1 USDC = 10⁶ atomic units. |
| 45 | 1 | `is_initialized` | `bool` | `1` once initialized; uninitialized Mints are unusable. |
| 46 | 36 | `freeze_authority` | `COption<Pubkey>` | 4-byte tag + 32-byte pubkey. When Some, can freeze any Token Account holding this mint. |

Total: **82 bytes**.

## Where you see it

You encounter a Mint anytime you read the `mint` field of a Token Account, call `getMint` over RPC, or look up an asset on Jupiter, a wallet UI, or an explorer.

## Common gotchas

- **The COption tag is 4 bytes, not 1.** SPL Token uses a 4-byte tag in front of each optional pubkey to preserve struct alignment for `Pack` (`36 = 4 + 32`). This is different from Borsh's `Option`, which uses a 1-byte tag. Token-2022 follows the same SPL convention.
- **`decimals` is an exponent, not a digit count.** A `decimals` of `9` means amounts are divided by 10⁹, not "displays 9 digits."
- **`mint_authority: None` is permanent.** Once an authority is removed (SetAuthority → None), nothing can re-enable minting. Many tokens lock minting after the initial issuance for trust.
