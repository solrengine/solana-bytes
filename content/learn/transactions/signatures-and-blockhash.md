---
slug: signatures-and-blockhash
category: transactions
name: Signatures & Recent Blockhash
kind: concept
status: live
program_id: null
program_label: Transaction encoding
size: null
summary: How a transaction is signed and kept fresh — Ed25519 signatures over the message bytes, a recent blockhash that expires in ~80 seconds, and durable nonces for transactions that need to outlive that window.
fields:
  - signatures
  - recent_blockhash
  - durable_nonce
see_also:
  - legacy-transaction
  - v0-transaction
sources:
  - url: https://docs.solana.com/developing/programming-model/transactions#recent-blockhash
    label: Solana docs — recent blockhash
  - url: https://docs.solana.com/implemented-proposals/durable-tx-nonces
    label: Solana docs — durable transaction nonces
last_verified: 2026-05-20
---

## What it is

Two mechanisms keep transactions authentic and fresh: **signatures** prove the required keys authorized the transaction, and the **recent blockhash** proves it was created recently (and prevents replay). Together they're the security envelope around the message body.

## Why it exists

Without signatures, anyone could move anyone's tokens. Without a freshness marker, a captured transaction could be replayed forever. The blockhash solves both — it expires quickly *and* uniquely identifies the transaction, so the same signed bytes can't be re-submitted after the blockhash ages out.

## Byte layout

| Field | Location | Type | Notes |
|-------|----------|------|-------|
| `signatures` | top of transaction | `compact-u16` count + 64 bytes each | Ed25519 signatures over the serialized **message** bytes. Order matches the first `num_required_signatures` account keys. |
| `recent_blockhash` | inside message | 32 bytes | A blockhash from the last ~150 blocks. Doubles as the replay-protection nonce. |

A signature is the standard 64-byte Ed25519 signature: it signs the exact message byte range (everything after the signatures vector), and is verified against the corresponding signer pubkey from `account_keys`.

## Blockhash expiry

A recent blockhash is valid for **150 blocks** — roughly 80–90 seconds at mainnet block times. After that, validators reject the transaction with a "blockhash not found" error. This is why a transaction sitting in a wallet too long fails: its blockhash expired. Clients must fetch a fresh blockhash shortly before signing and submit promptly.

## Durable nonces — escaping the 80-second window

Some flows (offline signing, multisig collection over hours, custody approvals) can't sign and submit within 80 seconds. **Durable nonces** solve this: a Nonce account stores a fixed nonce value that acts as the blockhash, and it only advances when an `AdvanceNonceAccount` instruction runs. A durable transaction:

1. Uses the Nonce account's stored value in the `recent_blockhash` field instead of a real blockhash.
2. Has `AdvanceNonceAccount` as its **first instruction**, which consumes-and-rotates the nonce so the transaction can't be replayed.

The transaction stays valid until the nonce is advanced — days or weeks later if needed.

## Where you see it

Every transaction has signatures and a blockhash. Durable nonces appear in custody products, Squads multisig, exchange withdrawal pipelines, and any offline-signing flow.

## Common gotchas

- **Signatures cover the message, not the whole transaction.** Verification starts at the message offset (after the signatures vector), not byte 0. Signing the wrong byte range is a classic bug.
- **Blockhash is replay protection, not just freshness.** Two identical transactions with the same blockhash are *the same transaction* and only land once. Change the blockhash and it's a new, separately-landable transaction.
- **A durable-nonce transaction must put `AdvanceNonceAccount` first.** If it isn't the first instruction, the runtime won't treat the stored nonce as a valid blockhash and the transaction fails.
- **Fee payer signs even if it does nothing else.** The first required signer is the fee payer; it must sign and hold enough SOL for fees regardless of what the instructions do.
