---
slug: address-lookup-table
category: transactions
name: Address Lookup Table
kind: account
status: live
program_id: AddressLookupTab1e1111111111111111111111111
program_label: Address Lookup Table Program
size: null
summary: Stores an array of pubkeys that v0 transactions reference by 1-byte index. 56-byte header + tightly-packed 32-byte addresses, up to 256 entries.
example_address: GbL3KvBBRXJArvft1KQPMUworMDormXNfo97hkbftsT5
example_label: Jupiter v6 LUT
fields:
  - discriminator
  - deactivation_slot
  - last_extended_slot
  - last_extension_start_index
  - authority
  - addresses
see_also: []
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/address_lookup_table/state.rs
    label: ALT state (agave sdk/program/src/address_lookup_table/state.rs)
  - url: https://docs.solana.com/developing/lookup-tables
    label: Solana docs — Address Lookup Tables
last_verified: 2026-05-19
---

## What it is

An Address Lookup Table (ALT) lets v0 transactions reference accounts by 1-byte index instead of inlining each 32-byte pubkey, lifting the ~35-account ceiling of legacy transactions.

## Why it exists

Legacy Solana transactions inline every account address as 32 raw bytes. With a hard 1,232-byte transaction size limit, that capped composability — multi-hop swaps and complex DeFi routes hit the wall. ALTs are stored on-chain; a v0 transaction names one or more lookup tables in its header and then references accounts in those tables by 1-byte index. The transaction stays small, but the runtime sees the full pubkey set.

## Byte layout

A 56-byte fixed header followed by tightly-packed 32-byte pubkeys.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0   | 4   | `discriminator`              | `u32` enum     | `1` = LookupTable. |
| 4   | 8   | `deactivation_slot`          | `u64` LE       | `u64::MAX` if still active. |
| 12  | 8   | `last_extended_slot`         | `u64` LE       | Last slot at which an Extend ran. |
| 20  | 1   | `last_extension_start_index` | `u8`           | Index where the last Extend began appending. |
| 21  | 1   | `authority` tag              | `u8` Option    | `0` None (frozen forever), `1` Some. |
| 22  | 32  | `authority`                  | `Pubkey`       | Zeroed when the Option tag is None. |
| 54  | 2   | padding                      | —              | Zero-fill to align addresses to offset 56. |
| 56  | 32 × N | `addresses[]`             | `Pubkey[]`     | Up to 256 entries. Total size: `56 + 32 × addresses.len()`. |

Maximum total: **8,248 bytes** (56 header + 256 × 32).

## Where you see it

Every modern Jupiter swap, Drift trade, Kamino position update, and Squads multisig action walks through one or more ALTs. You encounter ALTs whenever you simulate or decode a v0 transaction, or compose one from scratch via `@solana/web3.js` ≥ 1.95 or `anchor-cli`.

## Common gotchas

- **ALTs are mutable until frozen.** Anyone with `authority` can call ExtendLookupTable to append new addresses; setting the authority Option to None makes the table immutable forever.
- **Deactivation is two-phase.** DeactivateLookupTable sets `deactivation_slot`; the table is unusable after that slot lands but can't be `CloseLookupTable`'d until ~513 slots later (the "cooldown") to prevent in-flight transactions from breaking.
- **The 1-byte index limits a single ALT to 256 entries**, but a v0 transaction can reference multiple ALTs to compose larger account sets.
- **`size` is dynamic.** Unlike Mint (82) or Token Account (165), an ALT's size depends on how many addresses have been Extended in.
