---
slug: v0-transaction
category: transactions
name: v0 (Versioned) Transaction
kind: concept
status: live
program_id: null
program_label: Transaction encoding
size: null
summary: The versioned transaction format — a 1-byte version prefix, the same message body as a legacy transaction, plus an address-table-lookups section that references accounts stored in Address Lookup Tables.
fields:
  - version_prefix
  - message_body
  - address_table_lookups
see_also:
  - legacy-transaction
  - address-lookup-table
  - compact-u16
sources:
  - url: https://docs.solana.com/developing/versioned-transactions
    label: Solana docs — Versioned Transactions
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/message/versions/v0/mod.rs
    label: v0 Message struct (agave)
last_verified: 2026-05-20
---

## What it is

A v0 transaction is the versioned wire format. It's a [legacy transaction](/learn/transactions/legacy-transaction) with two additions: a 1-byte version prefix at the start of the message, and an address-table-lookups section at the end that pulls extra accounts from [Address Lookup Tables](/learn/transactions/address-lookup-table) by index instead of inlining their 32-byte keys.

## Why it exists

Legacy transactions inline every account as 32 raw bytes, and the 1,232-byte size limit caps you at ~35 accounts. Modern DeFi routes (a Jupiter swap across five pools) blow past that. v0 transactions reference accounts stored on-chain in lookup tables by 1-byte index, so a transaction can touch hundreds of accounts while staying under the size limit.

## Byte layout

The signatures vector and the core message body are identical to a legacy transaction. The differences are the leading version byte and the trailing lookups section.

| Section | Field | Type | Notes |
|---------|-------|------|-------|
| signatures | count + `signature[]` | `compact-u16` + 64 bytes each | Same as legacy. |
| message | `prefix` | 1 byte | High bit set (`0x80`) marks "versioned"; low 7 bits are the version (`0` for v0). So the first message byte is `0x80`. |
| message | header (3 bytes) | 3 × `u8` | `num_required_signatures`, `num_readonly_signed`, `num_readonly_unsigned` — same as legacy. |
| message | account-keys count + `account_keys[]` | `compact-u16` + 32 bytes each | The *statically* included keys (signers + any not coming from a table). |
| message | `recent_blockhash` | 32 bytes | Same as legacy. |
| message | instruction count + `instructions[]` | `compact-u16` + … | Same instruction sub-structure as legacy. |
| message | lookup count + `address_table_lookups[]` | `compact-u16` + … | New in v0 — see below. |

Each **address table lookup** is:

| Field | Type | Notes |
|-------|------|-------|
| `account_key` | 32 bytes | The Address Lookup Table account to read from. |
| writable count + `writable_indexes[]` | `compact-u16` + 1 byte each | Indexes into the table for accounts loaded **writable**. |
| readonly count + `readonly_indexes[]` | `compact-u16` + 1 byte each | Indexes into the table for accounts loaded **read-only**. |

## How the account index space works

Instructions still reference accounts by a single index, but in v0 that index space is *concatenated*: first the static `account_keys`, then all writable accounts pulled from lookup tables (in lookup order), then all read-only ones. A decoder must resolve the lookups against the actual on-chain tables to know which pubkey an instruction's account index really points to.

## Where you see it

Every modern Jupiter swap, Drift order, Kamino action, and most aggregator routes. Wallets and `getTransaction` return these constantly; `maxSupportedTransactionVersion` in RPC calls controls whether you get them decoded.

## Common gotchas

- **The version prefix steals the high bit.** Legacy transactions begin with `num_required_signatures`, a small number whose high bit is always clear. v0 sets the high bit, so `0x80` as the first message byte = "v0." That one bit is the entire legacy-vs-versioned discriminator.
- **You can't fully decode a v0 transaction in isolation.** The lookup indexes are meaningless without fetching the referenced lookup tables. A transaction blob alone doesn't tell you every account it touches.
- **Resolved account order is static-then-writable-then-readonly.** Get this ordering wrong and every instruction's account references point at the wrong pubkeys.
- **Signers must be in the static keys.** Accounts loaded from lookup tables can never be signers — only the statically-listed keys can sign. Lookups are for non-signer accounts only.
