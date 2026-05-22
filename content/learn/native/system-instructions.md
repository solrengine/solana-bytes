---
slug: system-instructions
category: native
name: System Program Instructions
kind: instruction
status: live
program_id: "11111111111111111111111111111111"
program_label: System Program
size: null
summary: Instruction data layouts for the System Program — CreateAccount, Transfer, Allocate, Assign, and the nonce instructions. A 4-byte little-endian enum discriminator followed by bincode-serialized fields.
fields:
  - discriminator
  - CreateAccount
  - Transfer
  - Allocate
  - Assign
see_also:
  - compute-budget
  - legacy-transaction
  - borsh-vs-bincode
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/system_instruction.rs
    label: SystemInstruction enum (agave sdk)
last_verified: 2026-05-20
---

## What it is

The System Program owns every account before any other program does. Its instructions create accounts, fund them, allocate space, assign ownership, and manage durable nonce accounts. Every account's life begins with a System instruction.

## Why it exists

You can't write to an account a program doesn't own, and new accounts start owned by the System Program. So creating an account, giving it space, and transferring ownership to your program are all System instructions — the bootstrap layer beneath everything else on Solana.

## Byte layout

System instruction data is **bincode**-encoded: a 4-byte little-endian `u32` enum discriminator, then the variant's fields. The common variants:

| Discriminator (u32 LE) | Variant | Payload | Total |
|----:|---------|---------|------:|
| `0` | `CreateAccount`     | `lamports: u64`, `space: u64`, `owner: Pubkey(32)` | 52 bytes |
| `1` | `Assign`            | `owner: Pubkey(32)` | 36 bytes |
| `2` | `Transfer`          | `lamports: u64` | 12 bytes |
| `3` | `CreateAccountWithSeed` | base, seed string, lamports, space, owner | variable |
| `4` | `AdvanceNonceAccount` | (none) | 4 bytes |
| `8` | `Allocate`          | `space: u64` | 12 bytes |

The most common instruction on the entire chain is `Transfer`: bytes `02 00 00 00` followed by an 8-byte little-endian lamport amount — 12 bytes total.

## Where you see it

Every account creation, every SOL transfer, every `createAccount` + `assign` pair that precedes initializing a program account. Wallet "send SOL" is a single System Transfer.

## Common gotchas

- **4-byte discriminator, not 1.** System (and Stake and Vote) use a 4-byte `u32` enum tag via bincode — unlike SPL Token's 1-byte tag. Reading the wrong width slides every field.
- **`lamports`, not SOL.** `Transfer`'s amount is in lamports (1 SOL = 1,000,000,000 lamports). A "1 SOL" transfer is `02 00 00 00` + `00 ca 9a 3b 00 00 00 00`.
- **CreateAccount needs the account to be a signer.** The new account address must sign its own creation (it's a brand-new keypair) — a frequent surprise for first-time builders. PDAs sidestep this via `createAccountWithSeed`/CPI invoke_signed.
- **`owner` defaults to System.** After CreateAccount, the account is owned by whatever `owner` you passed; if you forget to assign your program, your program can't write to it.
