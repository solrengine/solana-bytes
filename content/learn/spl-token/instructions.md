---
slug: instructions
category: spl-token
name: SPL Token Instructions
kind: instruction
status: live
program_id: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
program_label: Token Program
size: null
summary: Instruction data layouts for the SPL Token Program — Transfer, MintTo, Burn, Approve, and the Checked variants. A 1-byte discriminator followed by a u64 amount (and decimals for Checked).
fields:
  - discriminator
  - Transfer
  - TransferChecked
  - MintTo
  - Burn
  - Approve
see_also:
  - mint
  - token-account
  - token-2022-base
sources:
  - url: https://github.com/solana-program/token/blob/main/program/src/instruction.rs
    label: TokenInstruction enum (program/src/instruction.rs)
last_verified: 2026-05-20
---

## What it is

The SPL Token Program's instructions move and manage token balances: transfer, mint, burn, approve a delegate, freeze, close. They operate on [Mint](/learn/spl-token/mint) and [Token Account](/learn/spl-token/token-account) accounts. Token-2022 shares the same instruction layout plus extension-specific additions.

## Why it exists

Every token action — sending USDC, minting an NFT, burning a supply, approving a DEX to spend — is one of these instructions. They're among the most-executed instructions on Solana.

## Byte layout

SPL Token instruction data uses a **1-byte discriminator** followed by the variant's fields:

| Discriminator (u8) | Variant | Payload | Total |
|----:|---------|---------|------:|
| `3`  | `Transfer`        | `amount: u64` | 9 bytes |
| `4`  | `Approve`         | `amount: u64` | 9 bytes |
| `7`  | `MintTo`          | `amount: u64` | 9 bytes |
| `8`  | `Burn`            | `amount: u64` | 9 bytes |
| `9`  | `CloseAccount`    | (none) | 1 byte |
| `12` | `TransferChecked` | `amount: u64`, `decimals: u8` | 10 bytes |
| `14` | `MintToChecked`   | `amount: u64`, `decimals: u8` | 10 bytes |
| `15` | `BurnChecked`     | `amount: u64`, `decimals: u8` | 10 bytes |

`Transfer` is bytes `03` + an 8-byte little-endian amount. `TransferChecked` adds a `decimals` byte and requires the mint as an account so the program can verify the caller's decimals assumption.

## Where you see it

Every token movement on Solana. Wallet sends, DEX swaps (which approve + transfer), mint operations, and supply burns all decode to these.

## Common gotchas

- **Prefer the Checked variants.** `Transfer` (3) doesn't verify decimals, so a client using the wrong decimals can move 1000× the intended amount. `TransferChecked` (12) passes the mint and `decimals` so the program rejects a mismatch. New code should use Checked.
- **`amount` is atomic units, not display units.** Transferring "1 USDC" (6 decimals) is `amount = 1_000_000`. The instruction never sees the human number.
- **1-byte discriminator, unlike the 4-byte native programs.** SPL Token, SPL Associated Token Account, and most SPL programs use a single-byte tag.
- **Authority comes from accounts, not data.** Who's allowed to transfer (owner or delegate) is determined by which account signs, not by the instruction data. The data is just the discriminator + amount.
