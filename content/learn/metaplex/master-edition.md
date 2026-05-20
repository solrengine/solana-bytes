---
slug: master-edition
category: metaplex
name: Master Edition
kind: concept
status: live
program_id: metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s
program_label: Metaplex Token Metadata
size: null
summary: The account that marks an NFT as a one-of-one master and authorizes printing numbered editions of it. Stores current print supply and an optional maximum.
fields:
  - key
  - supply
  - max_supply
see_also:
  - edition-marker
  - token-metadata
sources:
  - url: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/programs/token-metadata/program/src/state/master_edition.rs
    label: MasterEditionV2 struct (mpl-token-metadata)
last_verified: 2026-05-20
---

## What it is

A Master Edition account turns a regular [Metaplex metadata](/learn/metaplex/token-metadata) NFT into a "master" that can mint numbered prints (editions) of itself — like an artist's signed master from which a limited run is printed. Its existence is also what makes a token a true non-fungible 1-of-1 (supply capped at 1, decimals 0).

## Why it exists

NFT use cases need both unique 1-of-1s and limited editions ("100 prints of this artwork"). The Master Edition account both certifies non-fungibility and tracks how many editions have been printed against an optional cap. A mint with a Master Edition is provably an NFT, not a divisible token.

## Byte layout

MasterEditionV2 is Borsh-encoded. Its account is a PDA of the mint with the seed suffix `"edition"`.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `key`        | `u8` enum   | `6` = MasterEditionV2. |
| 1 | 8 | `supply`     | `u64` LE    | Number of editions printed so far. |
| 9 | 1+8 | `max_supply` | `Option<u64>` | Borsh option: 1-byte tag (`0` None = unlimited, `1` Some) + `u64` cap when present. |

Total: **18 bytes** when `max_supply` is set, **10 bytes** when it's None (unlimited prints).

## Where you see it

Every 1-of-1 NFT (where `max_supply = Some(0)` — no prints allowed) and every limited-edition drop (where `max_supply = Some(N)`). Marketplaces read the Master Edition to confirm an asset is a genuine NFT and to show "edition X of N."

## Common gotchas

- **`max_supply = Some(0)` means a pure 1-of-1.** Zero prints allowed — the master itself is the only copy. `Some(100)` allows 100 numbered prints; `None` allows unlimited.
- **`supply` counts prints, not the master.** It starts at 0 and increments as editions are printed via [EditionMarker](/learn/metaplex/edition-marker) tracking.
- **It's a PDA seeded with `"edition"`.** Address = `findProgramAddress(["metadata", program_id, mint, "edition"])`. The same derivation locates a print edition's Edition account.
- **Borsh option (1-byte tag), not SPL COption.** `max_supply` is `Option<u64>` — a single `0` byte for None. Don't apply the [4-byte COption](/learn/encoding/coption-vs-option) convention here.
