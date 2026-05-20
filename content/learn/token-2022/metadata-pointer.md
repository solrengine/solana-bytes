---
slug: metadata-pointer
category: token-2022
name: MetadataPointer (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 64
summary: Mint-side Token-2022 extension that records where a token's metadata lives. It can point at an external account or at the mint itself for inline metadata — Token-2022's answer to Metaplex.
fields:
  - authority
  - metadata_address
see_also:
  - token-2022-base
  - tlv-layout-primer
  - token-metadata
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/metadata_pointer/mod.rs
    label: MetadataPointer extension (program/src/extension/metadata_pointer/mod.rs)
last_verified: 2026-05-20
---

## What it is

`MetadataPointer` records *where* a token's metadata lives. It's a layer of indirection: the pointer can reference an external metadata account (e.g., a [Metaplex Token Metadata](/learn/metaplex/token-metadata) account) or it can point at the mint itself, meaning the metadata is stored inline via the paired `TokenMetadata` extension.

## Why it exists

Metaplex stores NFT/token metadata in a separate account derived from the mint by PDA — a second account, a second program, a second rent payment. Token-2022 lets a mint hold its own metadata inline, removing the dependency on Metaplex entirely. But the ecosystem still has Metaplex metadata everywhere, so Token-2022 needs a way to say "my metadata is over there" *or* "my metadata is right here." MetadataPointer is that switch.

## Byte layout

This is the payload of a MetadataPointer TLV entry (`extension_type = 18`, `length = 64`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`        | `OptionalNonZeroPubkey` | Can update the pointer. All-zero means None — pointer frozen. |
| 32 | 32 | `metadata_address` | `OptionalNonZeroPubkey` | Where the metadata lives. All-zero means None (no metadata). |

Total payload: **64 bytes**.

## The two configurations

- **Inline:** `metadata_address == mint_address`. The mint also carries a `TokenMetadata` extension (type 19) holding the name, symbol, URI, and additional key-value pairs in the same account. No second account, no Metaplex.
- **External:** `metadata_address` points at some other account — typically a Metaplex Token Metadata PDA. The pointer is just a hint; the actual fields live in the referenced account and follow that program's layout.

A wallet rendering a Token-2022 token reads the pointer first, then fetches `metadata_address` to get the displayable fields.

## Where you see it

Most Token-2022 tokens that show a name and logo (PYUSD, regulated stablecoins, new NFT-style mints) carry a MetadataPointer. Inline metadata is increasingly the default for fresh launches because it's self-contained — one account holds the token *and* its identity.

## Common gotchas

- **The pointer is not the metadata.** MetadataPointer only stores an address. The actual name/symbol/URI lives either inline (TokenMetadata extension, type 19) or in the referenced external account. Two separate things to decode.
- **`metadata_address == mint` is the inline signal.** When the pointer points back at its own mint, look for a TokenMetadata extension in the same account's TLV list — that's where the fields are.
- **A trustworthy pointer needs a trusted authority.** Anyone can create a Token-2022 mint pointing its MetadataPointer at *someone else's* metadata account to impersonate a token. Wallets should verify the pointed-to metadata's update authority, not trust the pointer blindly.
- **`OptionalNonZeroPubkey`, not `COption`.** Both fields are 32 bytes with all-zeros meaning None — no tag byte. Same encoding family as the other Token-2022 extensions, distinct from the SPL base layout's 4-byte `COption`.
