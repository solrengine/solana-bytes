---
slug: token-account
category: spl-token
name: Token Account
kind: account
status: live
program_id: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
program_label: Token Program
size: 165
summary: Holds a balance of one specific token for one specific owner. Associated Token Accounts (ATAs) are the standard derivation.
example_address: ALZv1FW3Bc5uRtci2UHnYS34DEWCmfkN5btEYDKms9yU
example_label: Jupiter USDC
fields:
  - mint
  - owner
  - amount
  - delegate
  - state
  - is_native
  - delegated_amount
  - close_authority
see_also:
  - mint
  - multisig
  - token-2022-base
sources:
  - url: https://github.com/solana-program/token/blob/main/program/src/state.rs
    label: SPL Token Account struct (program/src/state.rs)
  - url: https://spl.solana.com/associated-token-account
    label: Associated Token Account (ATA) program
last_verified: 2026-05-19
---

## What it is

A Token Account holds one wallet's balance of one specific token. Every SPL token balance lives in its own 165-byte account.

## Why it exists

SPL Token deliberately separates mint metadata (the [Mint](/learn/spl-token/mint) account) from individual balances (Token Accounts). The same token — say USDC — exists as exactly one Mint and millions of Token Accounts, one per holder. Most wallets use Associated Token Accounts (ATAs): given a wallet pubkey and a mint, the ATA address is the deterministic PDA derived from the pair, so any tool can compute it without on-chain lookup.

## Byte layout

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0   | 32 | `mint`             | `Pubkey`            | Which token this account holds. |
| 32  | 32 | `owner`            | `Pubkey`            | Wallet that controls this account (signs transfers). |
| 64  | 8  | `amount`           | `u64` LE            | Balance in atomic units. |
| 72  | 36 | `delegate`         | `COption<Pubkey>`   | 4-byte tag + pubkey. Approved spender, if any. |
| 108 | 1  | `state`            | `u8` enum           | `0` Uninitialized, `1` Initialized, `2` Frozen. |
| 109 | 12 | `is_native`        | `COption<u64>`      | 4-byte tag + u64. Set on wrapped-SOL accounts; the u64 is the rent-exempt reserve. |
| 121 | 8  | `delegated_amount` | `u64` LE            | Atomic units the delegate may spend. |
| 129 | 36 | `close_authority`  | `COption<Pubkey>`   | 4-byte tag + pubkey. May close this account and reclaim rent. |

Total: **165 bytes**.

## Where you see it

You encounter Token Accounts every time a wallet holds an SPL token — in wallet UIs, transfer instructions, DEX swap routes, and balance lookups. An "account not found" error on a transfer usually means the recipient's ATA hasn't been created yet.

## Common gotchas

- **Frozen accounts can still receive tokens.** State `2` (Frozen) blocks outgoing transfers but not incoming. Used by issuers like Circle for compliance.
- **`is_native` is not a boolean.** It's `COption<u64>` — when Some, the account is wrapped SOL and the inner `u64` is the rent reserve to preserve on close.
- **ATAs are PDAs of the SPL Associated Token Account program**, not of the Token program. The derivation seeds are `[wallet, TOKEN_PROGRAM_ID, mint]`.
- **A Token Account's `owner` is the *wallet*, not the Token program.** The on-chain account's `owner` field (in the account header, not these 165 bytes) is the Token program; the data's `owner` field is the user wallet that authorizes spends.
