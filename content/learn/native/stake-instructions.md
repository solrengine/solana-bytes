---
slug: stake-instructions
category: native
name: Stake Program Instructions
kind: instruction
status: live
program_id: Stake11111111111111111111111111111111111111
program_label: Stake Program
size: null
summary: Instruction data layouts for the Stake Program — Initialize, DelegateStake, Deactivate, Split, Merge, Withdraw, Authorize. A 4-byte enum discriminator followed by bincode fields.
fields:
  - discriminator
  - Initialize
  - DelegateStake
  - Split
  - Withdraw
  - Deactivate
see_also:
  - stake-account
  - vote-instructions
  - system-instructions
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/stake/instruction.rs
    label: StakeInstruction enum (agave sdk)
last_verified: 2026-05-20
---

## What it is

The Stake Program manages the lifecycle of a [Stake account](/learn/consensus/stake-account): initializing it, delegating to a validator, deactivating, splitting, merging, and withdrawing. These instructions are how SOL holders and liquid-staking protocols operate stake.

## Why it exists

Staking isn't a single action — it's a state machine across epochs. You initialize a stake account, delegate it (activation takes an epoch), optionally split or merge, deactivate (cooldown takes an epoch), then withdraw. Each transition is a Stake instruction.

## Byte layout

Stake instruction data is **bincode**-encoded: a 4-byte little-endian `u32` discriminator, then the variant's fields. Key variants:

| Discriminator (u32 LE) | Variant | Payload | Notes |
|----:|---------|---------|-------|
| `0` | `Initialize`     | `Authorized{staker, withdrawer}`, `Lockup{ts, epoch, custodian}` | Sets authorities + lockup. |
| `1` | `Authorize`      | `new_authority: Pubkey`, `StakeAuthorize: u32` | Rotate staker or withdrawer. |
| `2` | `DelegateStake`  | (none) | Accounts carry the vote account to delegate to. |
| `3` | `Split`          | `lamports: u64` | Move part of the stake into a new account. |
| `4` | `Withdraw`       | `lamports: u64` | Withdraw unlocked, deactivated funds. |
| `5` | `Deactivate`     | (none) | Begin cooldown. |
| `7` | `Merge`          | (none) | Merge two compatible stake accounts. |

`DelegateStake` and `Deactivate` carry no data — the target validator and the stake account are passed as *accounts*, not instruction fields.

## Where you see it

Validator delegation flows, liquid-staking protocols (Marinade, Jito) managing pools of stake, and any wallet "stake SOL" button.

## Common gotchas

- **Activation and deactivation each take a full epoch.** `DelegateStake` doesn't earn rewards until the next epoch boundary; `Deactivate` funds aren't withdrawable until cooldown completes. The instruction lands instantly; the *effect* is epoch-gated.
- **Authorities are referenced two ways.** `Initialize` sets them as instruction data; `Authorize` rotates one of them. Don't confuse the staker (manages delegation) with the withdrawer (moves funds).
- **Split creates a new account.** `Split` needs a pre-funded, rent-exempt destination stake account — the lamports field is what moves *into* it, separate from the rent.
- **4-byte discriminator (bincode), like System and Vote** — not the 1-byte SPL convention.
