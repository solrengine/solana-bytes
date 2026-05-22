---
slug: legacy-transaction
category: transactions
name: Legacy Transaction
kind: concept
status: live
program_id: null
program_label: Transaction encoding
size: null
summary: The original Solana transaction wire format — a signatures array followed by a message (header, account keys, recent blockhash, instructions). Byte-by-byte, every array prefixed by compact-u16.
fields:
  - signatures
  - header
  - account_keys
  - recent_blockhash
  - instructions
see_also:
  - compact-u16
  - address-lookup-table
sources:
  - url: https://docs.solana.com/developing/programming-model/transactions
    label: Solana docs — Transactions
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/src/transaction/mod.rs
    label: Transaction struct (agave sdk)
last_verified: 2026-05-20
---

## What it is

A legacy transaction is the original Solana wire format: a vector of signatures followed by a *message* that names the accounts involved, pins a recent blockhash, and lists the instructions to run. It's "legacy" only in contrast to [v0 transactions](/learn/transactions/address-lookup-table) (which add address-table lookups) — the message body is otherwise identical, and legacy transactions are still valid and common.

## Why it exists

Every state change on Solana arrives as a transaction. Understanding its byte layout is what lets you decode a raw transaction blob, debug a malformed instruction, or hand-build one. The format is deliberately compact: every variable array is length-prefixed with [compact-u16](/learn/transactions/compact-u16) rather than a fixed-width count.

## Byte layout

A transaction is two top-level parts — `signatures` then `message`:

| Section | Field | Type | Notes |
|---------|-------|------|-------|
| signatures | count | `compact-u16` | Number of signatures. |
| signatures | `signature[]` | 64 bytes each | Ed25519 signatures over the message bytes, in the same order as the required signer keys. |
| message | `num_required_signatures` | 1 byte | How many leading account keys must sign. |
| message | `num_readonly_signed_accounts` | 1 byte | Of the signers, how many are read-only. |
| message | `num_readonly_unsigned_accounts` | 1 byte | Of the non-signers, how many are read-only. |
| message | account-keys count | `compact-u16` | Number of account keys. |
| message | `account_keys[]` | 32 bytes each | All pubkeys this transaction touches, ordered: writable-signers, readonly-signers, writable-non-signers, readonly-non-signers. |
| message | `recent_blockhash` | 32 bytes | A recent blockhash; the transaction is rejected if it's too old. |
| message | instruction count | `compact-u16` | Number of instructions. |
| message | `instructions[]` | (see below) | Each instruction, executed in order. |

Each **instruction** is:

| Field | Type | Notes |
|-------|------|-------|
| `program_id_index` | 1 byte | Index into `account_keys` of the program to invoke. |
| accounts count | `compact-u16` | Number of account indexes. |
| `accounts[]` | 1 byte each | Indexes into `account_keys` for this instruction's accounts. |
| data length | `compact-u16` | Byte length of the instruction data. |
| `data[]` | N bytes | Opaque instruction payload (the program decodes it). |

## The 3-byte header is the access list

`num_required_signatures` + the two `num_readonly_*` counts, combined with the strict ordering of `account_keys`, are how Solana derives which accounts are writable vs read-only and which must sign — without storing a flag per account. The first `num_required_signatures` keys are signers; within each signer/non-signer block, the trailing `num_readonly_*` keys are read-only.

## Where you see it

Any raw transaction you pull from `getTransaction`, simulate, or build with a client SDK. Wallet "approve" screens decode this structure to show you what you're signing.

## Common gotchas

- **Accounts are referenced by index, not pubkey.** Instructions store 1-byte indexes into `account_keys`, not the 32-byte keys themselves. That's the whole reason the ~35-account ceiling exists in legacy transactions and why [Address Lookup Tables](/learn/transactions/address-lookup-table) were added.
- **Key ordering encodes permissions.** The four-way ordering (writable-signer → readonly-signer → writable-nonsigner → readonly-nonsigner) is load-bearing. Reorder the keys and you change which accounts are writable. Decoders must respect the header counts to classify each key.
- **Signatures sign the message, not the whole transaction.** The Ed25519 signatures cover the serialized *message* bytes only. When verifying, hash/verify from the message start, not byte 0.
- **`recent_blockhash` is also the dedup key.** Two otherwise-identical transactions with the same blockhash are the same transaction. It's not just freshness — it's replay protection.
- **A legacy vs v0 transaction is distinguished by the first byte of the message.** If the high bit of the first message byte is set, it's a versioned (v0) transaction and the byte is a version prefix; otherwise it's legacy and that byte is `num_required_signatures`. Real values for `num_required_signatures` are small, so the high bit is free to use as the discriminator.
