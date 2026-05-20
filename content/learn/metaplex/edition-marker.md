---
slug: edition-marker
category: metaplex
name: Edition Marker
kind: concept
status: live
program_id: metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s
program_label: Metaplex Token Metadata
size: 32
summary: A 32-byte bitfield that tracks which numbered editions of a Master Edition have already been printed. Each bit is one edition number; one marker covers 248 editions.
fields:
  - key
  - ledger
see_also:
  - master-edition
  - token-metadata
sources:
  - url: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/programs/token-metadata/program/src/state/edition_marker.rs
    label: EditionMarker struct (mpl-token-metadata)
last_verified: 2026-05-20
---

## What it is

An Edition Marker is a compact bitfield that records which edition numbers of a [Master Edition](/learn/metaplex/master-edition) have been printed. Rather than store a flag per edition in separate accounts, Metaplex packs 248 edition flags into a single 31-byte ledger.

## Why it exists

Printing limited editions needs a way to prevent double-printing edition #42. Storing a boolean per edition in its own account would be wasteful; a bitfield lets one small account track hundreds of editions, with new marker accounts created only as edition numbers climb past each 248-edition block.

## Byte layout

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 1  | `key`    | `u8` enum    | `7` = EditionMarker. |
| 1 | 31 | `ledger` | `[u8; 31]`   | Bitfield: 31 bytes × 8 bits = 248 edition slots. Bit set = that edition number is printed. |

Total: **32 bytes**.

## How edition numbers map to bits

Edition number `N` lives in marker block `N / 248`; within that marker, it's bit `N % 248`, addressed as byte `(N % 248) / 8` and bit `(N % 248) % 8`. The marker account itself is a PDA seeded with the edition number's block, so editions 1–248 share one marker, 249–496 the next, and so on.

## Where you see it

Behind every limited-edition NFT drop. When you print edition #5 of a master, the program sets bit 5 in the relevant Edition Marker so #5 can never be printed again.

## Common gotchas

- **One marker covers 248 editions, not all of them.** Large editions span multiple marker accounts, each a separate PDA. Don't expect a single marker to hold the whole run.
- **It's a bitfield, not a counter.** The `supply` counter lives in the [Master Edition](/learn/metaplex/master-edition); the marker only records *which specific numbers* are taken. The two are updated together when printing.
- **Bit ordering matters.** Edition `N`'s bit is at byte `(N % 248) / 8`, MSB-first within the byte in Metaplex's scheme. Off-by-one here prints the wrong slot.
- **EditionMarkerV2 exists for very large editions** in newer Metaplex versions; the classic 32-byte EditionMarker (key 7) is what you'll see on most collections.
