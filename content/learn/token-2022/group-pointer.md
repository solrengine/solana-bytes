---
slug: group-pointer
category: token-2022
name: GroupPointer (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 64
summary: Mint-side Token-2022 extension that records where a token's group (collection) configuration lives. The grouping analogue of MetadataPointer — can point at a TokenGroup account or the mint itself.
fields:
  - authority
  - group_address
see_also:
  - token-group
  - metadata-pointer
  - token-2022-base
  - tlv-layout-primer
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/group_pointer/mod.rs
    label: GroupPointer extension (program/src/extension/group_pointer/mod.rs)
  - url: https://github.com/solana-program/libraries/tree/main/token-group
    label: SPL Token Group Interface
last_verified: 2026-05-20
---

## What it is

`GroupPointer` records *where* a token's group (collection) configuration lives. It's the grouping counterpart to [MetadataPointer](/learn/token-2022/metadata-pointer): a layer of indirection that points at a [TokenGroup](/learn/token-2022/token-group) account — either an external one or the mint itself for an inline group.

## Why it exists

NFT collections, token families, and any "these tokens belong together" relationship need an on-chain anchor. Metaplex models this with a Collection NFT; Token-2022 models it with the SPL Token Group Interface. GroupPointer is the switch that says "the group config for this token is over here," mirroring how MetadataPointer works for metadata so the two systems compose predictably.

## Byte layout

This is the payload of a GroupPointer TLV entry (`extension_type = 20`, `length = 64`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`     | `OptionalNonZeroPubkey` | Can update the pointer. All-zero means None — frozen. |
| 32 | 32 | `group_address` | `OptionalNonZeroPubkey` | Where the group config lives. All-zero means None (not part of a group). |

Total payload: **64 bytes**.

## The two configurations

- **Inline:** `group_address == mint_address`. The mint also carries a `TokenGroup` extension holding the size/max-size config. This is the "group definition" mint — the collection itself.
- **External:** `group_address` points at another mint that holds the TokenGroup. This token is a *member* candidate pointing at its collection (members are formally tracked by the separate TokenGroupMember extension).

## Where you see it

Token-2022-native NFT collections and token families. Adoption trails Metaplex collections, but the Group Interface is the standards-track way to express collection membership without the Metaplex program.

## Common gotchas

- **Pointer is not the group.** GroupPointer only stores an address. The member count, max size, and update authority live in the [TokenGroup](/learn/token-2022/token-group) extension at the pointed-to account.
- **Verify the pointed-to group's authority.** As with MetadataPointer, anyone can point at someone else's group account to fake membership. Trust the group's `update_authority`, not the raw pointer.
- **`OptionalNonZeroPubkey`, not `COption`.** 32-byte fields, all-zeros = None, no tag byte — same encoding family as the other Token-2022 extensions.
