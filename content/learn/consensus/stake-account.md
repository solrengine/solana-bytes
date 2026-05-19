---
slug: stake-account
category: consensus
name: Stake Account
kind: account
status: live
program_id: Stake11111111111111111111111111111111111111
program_label: Stake Program
size: 200
summary: Delegates SOL to a validator's Vote account. Tracks staker/withdrawer authorities, lockup, delegated amount, and activation epochs.
example_address: CbrKVVDv6irzm4SYv8YnhJkN6wCTnYw9S7SqdwavCrRt
example_label: Stake Account
fields:
  - state
  - rent_exempt_reserve
  - authorized_staker
  - authorized_withdrawer
  - lockup
  - voter_pubkey
  - stake_amount
  - activation_epoch
  - credits_observed
see_also:
  - vote-account
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/stake/state.rs
    label: Stake program state (agave sdk/program/src/stake/state.rs)
last_verified: 2026-05-19
---

## What it is

A Stake account delegates SOL to a validator's Vote account to earn staking rewards. The 200-byte layout tracks who can manage the stake, how much is delegated, and when activation or deactivation lands.

## Why it exists

Solana's proof-of-stake consensus runs on these delegations. SOL holders create Stake accounts pointing at a validator's [Vote account](/learn/consensus/vote-account); the Stake program manages epoch-based activation, computes per-epoch rewards, and records the credits the validator has earned. Liquid staking protocols like Marinade and Jito hold large pools of Stake accounts on behalf of their depositors.

## Byte layout

The layout is a 4-byte state enum followed by a `Meta` struct and (when state = `Stake`) a `Delegation` struct.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0   | 4  | `state`                 | `u32` enum    | `0` Uninitialized, `1` Initialized, `2` Stake, `3` RewardsPool. |
| 4   | 8  | `rent_exempt_reserve`   | `u64` LE      | SOL reserved for rent exemption. |
| 12  | 32 | `authorized_staker`     | `Pubkey`      | May delegate, deactivate, split, merge. |
| 44  | 32 | `authorized_withdrawer` | `Pubkey`      | May withdraw funds. Typically held in cold storage. |
| 76  | 8  | `lockup.unix_timestamp` | `i64` LE      | Lockup expires at this UNIX time. |
| 84  | 8  | `lockup.epoch`          | `u64` LE      | Lockup expires at this epoch. |
| 92  | 32 | `lockup.custodian`      | `Pubkey`      | May bypass the lockup. |
| 124 | 32 | `voter_pubkey`          | `Pubkey`      | Vote account this stake delegates to. |
| 156 | 8  | `stake_amount`          | `u64` LE      | Delegated SOL in lamports. |
| 164 | 8  | `activation_epoch`      | `u64` LE      | Epoch when delegation activates. |
| 172 | 8  | `deactivation_epoch`    | `u64` LE      | `u64::MAX` if still active. |
| 180 | 8  | `credits_observed`      | `u64` LE      | Validator credits at last reward calc. |

Total: **200 bytes** (offsets 188-199 are warmup/cooldown padding in older layouts, zero in current).

## Where you see it

Validator dashboards, liquid staking flows, and any RPC call that walks delegations (`getStakeActivation`, `getProgramAccounts` on the Stake program).

## Common gotchas

- **Two-step authorities.** `authorized_staker` and `authorized_withdrawer` can be different keys — cold storage holds the withdrawer while a hot key manages delegations.
- **`deactivation_epoch = u64::MAX` means "still active."** A finite value means deactivation has been requested; the stake cools down over one epoch before funds become withdrawable.
- **Stake doesn't immediately earn rewards.** Activation takes one full epoch. Rewards land at the start of each subsequent epoch.
