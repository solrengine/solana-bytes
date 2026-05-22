---
slug: multisig
category: spl-token
name: Multisig
kind: account
status: live
program_id: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
program_label: Token Program
size: 355
summary: An m-of-n multi-signature account that can act as any authority on a Mint or Token Account. Up to 11 signers; m signatures required to authorize an action.
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
  - instructions
sources:
  - url: https://github.com/solana-program/token/blob/main/program/src/state.rs
    label: SPL Token Multisig struct (program/src/state.rs)
last_verified: 2026-05-20
---

## What it is

An SPL Token Multisig is a 355-byte account that can stand in for any single authority on a [Mint](/learn/spl-token/mint) or [Token Account](/learn/spl-token/token-account) — mint authority, freeze authority, account owner, or delegate. It encodes an m-of-n policy: of up to 11 listed signers, any `m` of them must sign to authorize an action.

## Why it exists

A single key controlling a mint or a treasury is a single point of failure. SPL Token bakes in a native multisig so issuers can require, say, 3-of-5 approvals to mint new supply — without deploying a separate multisig program. The multisig account simply takes the place of the authority pubkey.

## Byte layout

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `m` | `u8` | Required number of signers (the threshold). |
| 1 | 1 | `n` | `u8` | Total number of valid signers currently set. |
| 2 | 1 | `is_initialized` | `bool` | `1` once initialized. |
| 3 | 352 | `signers` | `[Pubkey; 11]` | 11 fixed 32-byte signer slots. Unused slots are zeroed; only the first `n` are valid. |

Total: **355 bytes** (1 + 1 + 1 + 11 × 32).

## Where you see it

Treasury mints (a stablecoin issuer requiring multiple approvals to mint), DAO-controlled token accounts, and any setup where the authority must be shared. When a Mint's `mint_authority` points at a 355-byte account owned by the Token program, that authority is a multisig.

## Common gotchas

- **Always 11 signer slots, regardless of `n`.** The layout reserves space for 11 pubkeys even in a 2-of-3. Slots beyond `n` are zeroed — don't treat a zeroed slot as a real signer.
- **The multisig replaces the authority, not the account.** A multisig-controlled mint still has a normal `mint_authority` field — it just holds the multisig account's address. The "m-of-n" logic lives in the multisig account, checked at instruction time.
- **Signers are passed at transaction time.** To act, `m` of the listed signer keys must sign the transaction; the Token program verifies them against the slots. The account stores *who can sign*, not signatures.
- **It's distinct from program-based multisig (Squads).** This is the Token program's built-in primitive, limited to token authorities and 11 signers. Squads and similar offer richer, program-level multisig for arbitrary instructions.
