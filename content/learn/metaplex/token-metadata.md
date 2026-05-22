---
slug: token-metadata
category: metaplex
name: Token Metadata
kind: account
status: live
program_id: metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s
program_label: Metaplex Token Metadata
size: 607
summary: MetadataV1 account — links a mint to its name, symbol, URI, royalties, creators, and optional collection. The foundation of every Solana NFT.
example_address: 5nav91dPXh4B6tXsG8duVQnrmyEbgRQBfYgn2BGs3Ag9
example_label: Mad Lads #7266
fields:
  - key
  - update_authority
  - mint
  - name
  - symbol
  - uri
  - seller_fee_basis_points
  - creators
  - primary_sale_happened
  - is_mutable
  - edition_nonce
  - token_standard
  - collection
  - uses
see_also:
  - mint
sources:
  - url: https://github.com/metaplex-foundation/mpl-token-metadata/blob/main/programs/token-metadata/program/src/state/metadata.rs
    label: Metaplex Metadata struct (mpl-token-metadata)
last_verified: 2026-05-19
---

## What it is

A Metaplex Token Metadata account attaches a name, symbol, image URI, and creator royalties to an SPL [Mint](/learn/spl-token/mint) — the foundation of every Solana NFT and most fungible-with-metadata tokens.

## Why it exists

SPL Mint accounts are just numbers: supply, decimals, authorities. For NFTs you need a name, a picture, creators to pay royalties to, and a way to point to off-chain JSON. Metaplex's Token Metadata program stores that on-chain as a separate account derived from the mint via a fixed PDA: `["metadata", program_id, mint_pubkey]`.

## Byte layout

The 607-byte MetadataV1 layout is dominated by three padded variable-length strings and several Option fields. Padding is zero-byte filled to fixed maxima.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0    | 1   | `key`                       | `u8` enum            | `4` = MetadataV1. |
| 1    | 32  | `update_authority`          | `Pubkey`             | Can update fields while `is_mutable`. |
| 33   | 32  | `mint`                      | `Pubkey`             | The SPL Mint this metadata describes. |
| 65   | 36  | `name`                      | padded string        | 4-byte length + up to 32 bytes UTF-8. |
| 101  | 14  | `symbol`                    | padded string        | 4-byte length + up to 10 bytes UTF-8. |
| 115  | 204 | `uri`                       | padded string        | 4-byte length + up to 200 bytes UTF-8. Points at off-chain JSON. |
| 319  | 2   | `seller_fee_basis_points`   | `u16` LE             | Royalty in basis points (500 = 5%). |
| 321  | var | `creators`                  | `Option<Vec<Creator>>` | 1-byte Option tag + 4-byte length + 34-byte Creator entries. |
| …    | 1   | `primary_sale_happened`     | `bool`               | |
| …    | 1   | `is_mutable`                | `bool`               | If false, fields are frozen forever. |
| …    | 2   | `edition_nonce`             | `Option<u8>`         | 1-byte Option tag + 1-byte nonce. |
| …    | 2   | `token_standard`            | `Option<u8>` enum    | NonFungible, Fungible, ProgrammableNonFungible, etc. |
| …    | var | `collection`                | `Option<Collection>` | Linked collection mint. |
| …    | var | `uses`                      | `Option<Uses>`       | Burn/multi/single use tracking. |

Total: **607 bytes** (padded to fixed size; variable fields fill to maximum).

## Where you see it

Wallets and marketplaces resolve any NFT mint to its Token Metadata account to render the name and image. Most fungible tokens use Metaplex too (USDC's logo and name come from a Metadata account). Token-2022 introduced an alternative inline metadata extension that avoids the separate account, but Metaplex remains dominant for NFTs.

## Common gotchas

- **Padded strings, not Borsh-style.** `name`/`symbol`/`uri` are length-prefixed but always padded to maximum size on-chain. The trailing zero bytes are part of the layout.
- **`is_mutable: false` is permanent.** Once set, no field can be changed. Many collections immutabilize after mint-out to prove provenance.
- **Metaplex uses Borsh `Option` (1-byte tag), not SPL's `COption` (4-byte tag).** The two encodings live side-by-side on Solana — easy source of off-by-3 bugs.
- **Royalties are advisory.** On-chain `seller_fee_basis_points` doesn't force marketplaces to pay — pNFTs (Programmable NFTs) added enforcement via a separate ruleset.
