---
slug: use-authority-record
category: metaplex
name: Use Authority Record
kind: concept
status: live
program_id: metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s
program_label: Metaplex Token Metadata
size: 10
summary: A tiny delegate record that lets an address other than the NFT owner consume "uses" on a usable NFT, with its own quota. The permission slip behind redeemable/consumable NFTs.
fields:
  - key
  - allowed_uses
  - bump
see_also:
  - token-metadata
  - collection-authority-record
sources:
  - url: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/programs/token-metadata/program/src/state/uses.rs
    label: UseAuthorityRecord struct (mpl-token-metadata)
last_verified: 2026-05-20
---

## What it is

A Use Authority Record delegates the ability to consume "uses" on a usable NFT to an address other than the owner, capped by its own `allowed_uses` quota. It's the permission slip behind redeemable NFTs — concert tickets, in-game consumables, coupon-style assets that get "used up."

## Why it exists

The Metaplex `Uses` feature lets an NFT carry a finite number of uses (a 5-use pass, a single-redemption ticket). Often a third party — a venue scanner, a game server — needs to consume a use without being the NFT's owner. This record delegates that power with its own per-delegate limit, so the owner can authorize a scanner to burn at most N uses.

## Byte layout

UseAuthorityRecord is Borsh-encoded. It's a PDA seeded with the NFT mint and the delegated authority.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `key`          | `u8` enum | `8` = UseAuthorityRecord. |
| 1 | 8 | `allowed_uses` | `u64` LE  | How many uses this delegate may consume. |
| 9 | 1 | `bump`         | `u8`      | Canonical bump of this record's PDA. |

Total: **10 bytes**.

## The Uses field it draws against

The NFT's own [metadata](/learn/metaplex/token-metadata) carries an optional `Uses { use_method, remaining, total }` struct — the global counter. A Use Authority Record is a *delegate-scoped* allowance that draws against that global `remaining`. Consuming a use decrements both the delegate's `allowed_uses` and the NFT's `remaining`.

## Where you see it

Redeemable NFT systems: event ticketing, loyalty redemptions, game item consumption. The record exists whenever an NFT owner has delegated use-consumption to a service.

## Common gotchas

- **Two counters, both decrement.** The delegate's `allowed_uses` and the NFT's global `Uses.remaining` are separate; a use consumes from both. A delegate can't exceed its `allowed_uses` even if the NFT has uses left.
- **Smallest Metaplex record at 10 bytes.** No `Option` fields — just key, a u64, and a bump. Quick to decode.
- **`use_method` matters for semantics.** The NFT's `Uses.use_method` (Burn, Multiple, Single) determines what happens at zero remaining — Burn destroys the NFT. The record itself only tracks the allowance.
- **Revocable by the owner.** Closing the record revokes the delegate's remaining allowance immediately.
