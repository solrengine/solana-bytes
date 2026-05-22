---
slug: token-metadata-extension
category: token-2022
name: TokenMetadata (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: null
summary: Mint-side Token-2022 extension that stores name, symbol, URI, and arbitrary key-value pairs inline in the mint account — Token-2022's self-contained alternative to a separate Metaplex metadata account.
fields:
  - update_authority
  - mint
  - name
  - symbol
  - uri
  - additional_metadata
see_also:
  - metadata-pointer
  - token-2022-base
  - tlv-layout-primer
  - token-metadata
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/token_metadata/mod.rs
    label: TokenMetadata extension (program/src/extension/token_metadata/mod.rs)
  - url: https://github.com/solana-program/libraries/tree/main/token-metadata
    label: SPL Token Metadata Interface
last_verified: 2026-05-20
---

## What it is

`TokenMetadata` stores a token's name, symbol, off-chain URI, and an arbitrary list of key-value pairs **inline in the mint account itself**. It implements the SPL Token Metadata Interface, and it's what makes a Token-2022 mint self-describing — no separate account, no Metaplex program, no PDA derivation.

## Why it exists

Metaplex's [Token Metadata](/learn/metaplex/token-metadata) account is a second account, owned by a second program, requiring a second rent payment and a CPI to create. For tokens that just need a name and a logo, that's a lot of moving parts. Token-2022 collapses it: the metadata lives in the mint, gated by the [MetadataPointer](/learn/token-2022/metadata-pointer) pointing back at the mint's own address.

## Byte layout

This is a **variable-length** extension (`extension_type = 19`); its TLV `length` field gives the total payload size. Unlike Metaplex's fixed-padded strings, every string here is a true Borsh length-prefixed string: a 4-byte `u32` LE length followed by exactly that many UTF-8 bytes, with no padding.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `update_authority`     | `OptionalNonZeroPubkey` | Can update fields. All-zero means None — metadata frozen. |
| 32 | 32 | `mint`                 | `Pubkey`                | The mint this metadata describes. Should equal the containing account. |
| 64 | 4+N | `name`                | Borsh `String`          | 4-byte LE length + UTF-8 bytes. No fixed maximum. |
| …  | 4+N | `symbol`              | Borsh `String`          | 4-byte LE length + UTF-8 bytes. |
| …  | 4+N | `uri`                 | Borsh `String`          | 4-byte LE length + UTF-8 bytes. Points at off-chain JSON. |
| …  | 4+… | `additional_metadata` | `Vec<(String, String)>` | 4-byte LE count, then that many key/value string pairs, each a Borsh `String`. |

Total length is whatever the strings add up to — there is no fixed account size.

## How it pairs with MetadataPointer

A wallet rendering the token reads [MetadataPointer](/learn/token-2022/metadata-pointer) first. When the pointer's `metadata_address` equals the mint's own address, the renderer looks for *this* extension in the same account's TLV list and decodes the fields here. The pointer is the "where," TokenMetadata is the "what."

## Where you see it

Self-contained Token-2022 launches: PYUSD, regulated stablecoins, and the wave of 2025–2026 mints that skip Metaplex entirely. `additional_metadata` is increasingly used for things like `["description", …]`, `["category", …]`, or issuer-specific compliance tags.

## Common gotchas

- **Variable-length strings, not Metaplex's padded fields.** Metaplex pads name to 32, symbol to 10, uri to 200 bytes. TokenMetadata uses true Borsh strings — 4-byte length prefix, exact byte count, no trailing zeros. A decoder built for one will mis-read the other.
- **`additional_metadata` is unbounded.** It's a `Vec` of string pairs with no schema. Treat keys as untrusted input — sanitize before rendering (control chars, bidi overrides, length).
- **The `mint` field should match the account, but verify it.** A malicious mint could embed metadata claiming a different mint pubkey. Cross-check `metadata.mint == account_pubkey` before trusting it.
- **This extension grows the account.** Because it's variable-length and usually the last extension, adding `additional_metadata` entries reallocates the account and requires more rent. The Token-2022 program handles the realloc, but the fee payer covers the new rent.
