---
slug: collection-authority-record
category: metaplex
name: Collection Authority Record
kind: concept
status: live
program_id: metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s
program_label: Metaplex Token Metadata
size: 35
summary: A tiny delegate record that lets an address other than the collection's update authority verify NFTs into a Metaplex collection. The on-chain permission slip for delegated collection management.
fields:
  - key
  - bump
  - update_authority
see_also:
  - token-metadata
  - use-authority-record
sources:
  - url: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/programs/token-metadata/program/src/state/collection.rs
    label: CollectionAuthorityRecord struct (mpl-token-metadata)
last_verified: 2026-05-20
---

## What it is

A Collection Authority Record delegates the power to verify (and unverify) NFTs into a Metaplex collection to an address that isn't the collection's update authority. It's a small permission slip: "this key is allowed to mark NFTs as belonging to my collection."

## Why it exists

Verifying an NFT into a collection normally requires the collection's update authority to sign. But minting platforms and candy machines need to verify items on the issuer's behalf without holding the master update-authority key. The record delegates exactly that one capability, scoped to one collection.

## Byte layout

CollectionAuthorityRecord is Borsh-encoded. It's a PDA seeded with the collection mint and the delegated authority.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 1   | `key`              | `u8` enum       | `9` = CollectionAuthorityRecord. |
| 1 | 1   | `bump`             | `u8`            | Canonical bump of this record's PDA. |
| 2 | 1+32 | `update_authority` | `Option<Pubkey>` | Borsh option: 1-byte tag + 32-byte pubkey. The authority that created (and can revoke) this delegation. |

Total: **35 bytes** (1 + 1 + 1 + 32).

## Where you see it

Candy Machine and other minting infrastructure that verifies items into a collection at mint time. The existence of this record is what lets a delegated signer call `VerifyCollection` without being the collection's update authority.

## Common gotchas

- **It grants verify rights, not ownership.** The delegate can verify/unverify collection membership; it can't change the collection's metadata or transfer the collection NFT.
- **Revocable.** The `update_authority` that created the record can revoke it (closing the account), instantly removing the delegate's power.
- **Stores its own bump.** The `bump` field caches the [canonical bump](/learn/addressing/canonical-bumps) so the program doesn't re-derive it each call — a common pattern in small Metaplex records.
- **Superseded by MetadataDelegate in newer flows.** Recent Metaplex versions favor the generalized `MetadataDelegate` (key 12) record; CollectionAuthorityRecord (key 9) remains common on existing collections.
