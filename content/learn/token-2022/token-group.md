---
slug: token-group
category: token-2022
name: TokenGroup (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 80
summary: Mint-side Token-2022 extension that defines a group (collection) — its update authority, the group mint, and the current/maximum member count. The Group Interface analogue of a Metaplex Collection.
fields:
  - update_authority
  - mint
  - size
  - max_size
see_also:
  - group-pointer
  - token-metadata-extension
  - token-2022-base
  - tlv-layout-primer
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/token_group/mod.rs
    label: TokenGroup extension (program/src/extension/token_group/mod.rs)
  - url: https://github.com/solana-program/libraries/tree/main/token-group
    label: SPL Token Group Interface
last_verified: 2026-05-20
---

## What it is

`TokenGroup` defines a collection: a named group that other tokens can belong to, with a current member count and a hard cap. It implements the SPL Token Group Interface and is the Token-2022-native equivalent of a Metaplex Collection NFT — the "parent" that members point back at.

## Why it exists

Collections need a canonical on-chain definition: who controls the collection, how many members exist, and the maximum allowed. Without a cap, a collection can be diluted; without a count, you can't display "#42 of 100." TokenGroup stores exactly that, and the [GroupPointer](/learn/token-2022/group-pointer) extension is how a mint advertises that it carries (or references) one.

## Byte layout

This is the payload of a TokenGroup TLV entry (`extension_type = 21`, `length = 80`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `update_authority` | `OptionalNonZeroPubkey` | Can update the group (e.g., raise max_size). All-zero means None — frozen. |
| 32 | 32 | `mint`             | `Pubkey`                | The group's own mint. Should equal the containing account for an inline group. |
| 64 | 8  | `size`             | `u64` LE                | Current number of members. Maintained by the program as members are added. |
| 72 | 8  | `max_size`         | `u64` LE                | Maximum members allowed. Adding a member past this fails. |

Total payload: **80 bytes**.

## How members join

A member token carries a `TokenGroupMember` extension pointing at this group's mint, and the group's `size` increments when the member is initialized. The group's `update_authority` controls whether `max_size` can change. Together GroupPointer + TokenGroup + TokenGroupMember mirror Metaplex's collection/verified-creator machinery in the Group Interface.

## Where you see it

Token-2022-native NFT collections and bounded token families. Most production NFT collections still use Metaplex, but the Group Interface is the standards-track path for collection semantics without a separate program.

## Common gotchas

- **`size` is program-maintained, not user-set.** Don't write it directly — it reflects how many members have been initialized against the group. Trust it as a counter, but verify member tokens individually if provenance matters.
- **`max_size` can be raised by the update authority** (if one exists). "Limited to 100" is only as firm as the authority being None. Surface the authority status when displaying scarcity.
- **The `mint` field should match the account.** As with TokenMetadata, a group could claim a different mint pubkey. Cross-check before trusting.
- **Inline vs external mirrors GroupPointer.** When `group-pointer.group_address == mint`, look for this extension in the same account; otherwise it lives at the referenced mint.
