---
slug: vote-instructions
category: native
name: Vote Program Instructions
kind: instruction
status: live
program_id: Vote111111111111111111111111111111111111111
program_label: Vote Program
size: null
summary: Instruction data layouts for the Vote Program — InitializeAccount, Authorize, Vote, Withdraw, UpdateCommission. A 4-byte enum discriminator followed by bincode fields. Mostly validator-internal.
fields:
  - discriminator
  - InitializeAccount
  - Authorize
  - Withdraw
  - UpdateCommission
see_also:
  - vote-account
  - stake-instructions
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/vote/instruction.rs
    label: VoteInstruction enum (agave sdk)
last_verified: 2026-05-20
---

## What it is

The Vote Program manages a validator's [Vote account](/learn/consensus/vote-account): creating it, rotating its authorities, recording votes, updating commission, and withdrawing earned rewards. Most of these run automatically from the validator client; a few (commission, withdraw, authorize) are operator actions.

## Why it exists

Validators vote on which blocks are valid, and that voting record drives reward distribution. The Vote Program is how those votes get recorded on-chain and how operators manage the account that represents their validator.

## Byte layout

Vote instruction data is **bincode**-encoded: a 4-byte little-endian `u32` discriminator, then fields. Notable variants:

| Discriminator (u32 LE) | Variant | Payload | Notes |
|----:|---------|---------|-------|
| `0` | `InitializeAccount` | `VoteInit{node_pubkey, authorized_voter, authorized_withdrawer, commission: u8}` | Create the vote account. |
| `1` | `Authorize`         | `pubkey: Pubkey`, `VoteAuthorize: u32` | Rotate voter or withdrawer authority. |
| `3` | `Withdraw`          | `lamports: u64` | Withdraw rewards (withdrawer only). |
| `5` | `UpdateCommission`  | `commission: u8` | Change the validator's commission percentage. |

Vote transactions themselves (the high-frequency ones the validator submits every slot) carry compact vote-state updates; commission and withdraw are the operator-facing ones you'll decode in dashboards.

## Where you see it

Validator operations and staking dashboards. `UpdateCommission` and `Withdraw` are the instructions delegators care about — a commission hike directly affects their rewards.

## Common gotchas

- **Most vote traffic is automated.** The validator client submits vote-state updates continuously; you rarely build those by hand. Operator instructions (commission, withdraw, authorize) are the ones in human-built transactions.
- **Commission changes are time-restricted.** The runtime limits when commission can change within an epoch to prevent validators from rugging delegators right before rewards. An `UpdateCommission` can be rejected for timing.
- **Withdraw requires the withdrawer authority.** Rewards can only be pulled by the `authorized_withdrawer` — typically a cold key separate from the voting key.
- **4-byte discriminator (bincode), like System and Stake.**
