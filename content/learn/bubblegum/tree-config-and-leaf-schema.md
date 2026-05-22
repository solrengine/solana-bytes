---
slug: tree-config-and-leaf-schema
category: bubblegum
name: Bubblegum — TreeConfig & Leaf Schema
kind: concept
status: live
program_id: BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY
program_label: Metaplex Bubblegum
size: null
summary: How compressed NFTs work — a small TreeConfig account governs a Merkle tree, and each NFT is a hashed leaf (LeafSchema) rather than its own account. Millions of NFTs for the cost of a few accounts.
fields:
  - tree_creator
  - tree_delegate
  - num_minted
  - leaf_schema
see_also:
  - token-metadata
  - master-edition
  - pda-derivation
sources:
  - url: https://github.com/metaplex-foundation/mpl-bubblegum/blob/main/programs/bubblegum/program/src/state/mod.rs
    label: TreeConfig struct (mpl-bubblegum)
  - url: https://github.com/metaplex-foundation/mpl-bubblegum/blob/main/programs/bubblegum/program/src/state/leaf_schema.rs
    label: LeafSchema enum (mpl-bubblegum)
last_verified: 2026-05-20
---

## What it is

Compressed NFTs (cNFTs) don't get their own accounts. Instead, Metaplex Bubblegum stores each NFT as a **hashed leaf** in a Merkle tree, and a single small **TreeConfig** account governs the whole tree. A tree holding a million NFTs costs a few accounts' worth of rent instead of a million — the core trick behind cheap, mass-scale NFT minting.

## Why it exists

A normal NFT needs a mint, a [token account](/learn/spl-token/token-account), and a [metadata](/learn/metaplex/token-metadata) account — too expensive for airdrops of millions. State compression hashes NFT data into a concurrent Merkle tree (stored off-chain, with only the 32-byte root and a change log on-chain). Ownership and metadata are proven against the root via Merkle proofs, so per-NFT on-chain storage drops to near zero.

## Byte layout

**TreeConfig** — the per-tree authority account (an Anchor account, so it starts with an 8-byte [discriminator](/learn/anchor/account-discriminator)):

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 8  | discriminator       | `[u8; 8]` | Anchor account discriminator. |
| 8  | 32 | `tree_creator`      | `Pubkey`  | Who created the tree. |
| 40 | 32 | `tree_delegate`     | `Pubkey`  | Authorized to mint into the tree. |
| 72 | 8  | `total_mint_capacity` | `u64` LE | Max leaves (set by tree depth). |
| 80 | 8  | `num_minted`        | `u64` LE  | Leaves minted so far. |
| 88 | 1  | `is_public`         | `bool`    | Whether anyone may mint. |
| 89 | 1  | `is_decompressible` | `u8` enum | Whether leaves can be decompressed to real NFTs. |
| 90 | 1  | `version`           | `u8` enum | Tree schema version. |

**LeafSchema V1** — the per-NFT data that gets keccak-hashed into one 32-byte tree node (it is *not* stored as an account):

| Field | Type | Notes |
|-------|------|-------|
| `id`           | `Pubkey`   | The asset id — a PDA from the tree + nonce. |
| `owner`        | `Pubkey`   | Current owner. |
| `delegate`     | `Pubkey`   | Approved delegate, if any. |
| `nonce`        | `u64`      | Leaf index / uniqueness nonce. |
| `data_hash`    | `[u8; 32]` | Hash of the NFT's metadata. |
| `creator_hash` | `[u8; 32]` | Hash of the creators array. |

The program computes `keccak(id, owner, delegate, nonce, data_hash, creator_hash)` → the 32-byte leaf node stored in the tree.

## Where you see it

Large airdrops, gaming items, and any high-volume NFT collection (Drip, Helium, etc.). You don't fetch a cNFT by account — you query an indexer (the DAS API) that reconstructs it from the tree and serves a Merkle proof.

## Common gotchas

- **The NFT has no account.** You can't `getAccountInfo` a cNFT. Ownership lives as a hash in the tree; transfers update the leaf and the tree root. Tooling that assumes one-account-per-NFT doesn't work.
- **You need a Merkle proof to act on one.** Transferring or burning a cNFT requires submitting the leaf data plus a proof path against the current root — usually fetched from a DAS-API provider, not derived locally.
- **The on-chain tree account is separate from TreeConfig.** TreeConfig (this account) holds authority/counters; the actual concurrent Merkle tree (root + change log) lives in a separate account owned by the SPL Account Compression program.
- **`data_hash`/`creator_hash` are commitments, not the data.** The real metadata lives off-chain; only its hash is on-chain. Verifying an NFT's metadata means re-hashing the off-chain data and checking it matches.
