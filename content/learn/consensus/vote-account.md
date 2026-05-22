---
slug: vote-account
category: consensus
name: Vote Account
kind: account
status: live
program_id: Vote111111111111111111111111111111111111111
program_label: Vote Program
size: 3762
summary: A validator's on-chain identity. Records voting authority, commission rate, and a rolling history of votes and epoch credits.
example_address: J2nUHEAgZFRyuJbFjdqPrAa9gyWDuc7hErtDQHPhsYRp
example_label: Vote Account
fields:
  - version
  - node_pubkey
  - authorized_voter
  - authorized_withdrawer
  - commission
  - vote_history
see_also:
  - stake-account
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/vote/state/mod.rs
    label: Vote program state (agave sdk/program/src/vote/state/mod.rs)
last_verified: 2026-05-19
---

## What it is

A Vote account is a validator's on-chain identity. It records the validator's voting authority, its commission rate, and a 3.7 KB rolling history of recent votes and epoch credits.

## Why it exists

Every validator on Solana has exactly one Vote account. [Stake accounts](/learn/consensus/stake-account) point at a Vote account to delegate; the Vote program records the validator's votes (which slots it confirmed and when), and the network uses that record to distribute staking rewards proportional to the validator's participation.

## Byte layout

The first 109 bytes are field-level decodable. The remaining ~3,653 bytes are a packed buffer of recent `LandedVote` entries.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0   | 4    | `version`               | `u32` enum     | Vote state version (`0` v0, `1` v1_14_11, `2` current). |
| 4   | 32   | `node_pubkey`           | `Pubkey`       | The validator's identity keypair. |
| 36  | 32   | `authorized_withdrawer` | `Pubkey`       | Claims rewards. Typically cold storage. |
| 68  | 1    | `commission`            | `u8`           | Validator commission percentage (0–100). |
| 69  | 40   | `authorized_voters`     | epoch map      | Active authorized voter pubkey by epoch. |
| 109 | 3653 | `vote_history`          | `LandedVote[]` | Packed buffer; each LandedVote ≈ 12 bytes (slot, confirmation count, latency). |

Total: **3,762 bytes**.

## Where you see it

Staking flows (looking up a validator's commission before delegating), validator dashboards, leader-schedule logic. RPC calls like `getVoteAccounts` return one entry per Vote account.

## Common gotchas

- **The on-chain layout is too dense to byte-annotate inline.** For the exact `LandedVote` struct, see the Agave source linked above or walk the buffer with `getProgramAccounts` on the Vote program.
- **`authorized_voter` rotates per epoch.** The on-chain layout stores a small map of `(epoch → pubkey)` entries, not a single pubkey.
- **Commission changes don't apply instantly.** Vote programs enforce timing limits to prevent rugging delegators mid-epoch.
