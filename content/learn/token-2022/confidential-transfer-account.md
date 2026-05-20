---
slug: confidential-transfer-account
category: token-2022
name: ConfidentialTransferAccount (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 295
summary: Account-side Token-2022 extension holding a holder's ElGamal-encrypted balances. The 295-byte counterpart to ConfidentialTransferMint — where the actual hidden amounts and pending-balance machinery live.
fields:
  - approved
  - elgamal_pubkey
  - pending_balance_lo
  - pending_balance_hi
  - available_balance
  - decryptable_available_balance
see_also:
  - confidential-transfer-mint
  - confidential-transfer-fee
  - tlv-layout-primer
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/interface/src/extension/confidential_transfer/mod.rs
    label: ConfidentialTransferAccount struct (token-2022 interface)
last_verified: 2026-05-20
---

## What it is

This is the account-side half of confidential transfers. While [ConfidentialTransferMint](/learn/token-2022/confidential-transfer-mint) holds the mint's policy, this 295-byte extension on each [token account](/learn/spl-token/token-account) holds the holder's actual **ElGamal-encrypted balances** plus the pending-balance accounting that makes confidential deposits safe against replay and front-running.

## Why it exists

To transact confidentially, each account needs its own encryption key and encrypted balance ciphertexts that only the owner (and any auditor) can decrypt. The split between "pending" and "available" balances exists so incoming confidential transfers can't be used to grief the recipient — deposits land in pending and the owner applies them to available on their own schedule.

## Byte layout

Payload of a ConfidentialTransferAccount TLV entry (`extension_type = 5`, `length = 295`). Add the 4-byte TLV header for the full entry.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0   | 1  | `approved`                                 | `bool` | Whether the mint authority approved this account for confidential use. |
| 1   | 32 | `elgamal_pubkey`                           | `ElGamalPubkey` | The account's ElGamal public key (a Ristretto point — not an Ed25519 key). |
| 33  | 64 | `pending_balance_lo`                        | `EncryptedBalance` | Twisted-ElGamal ciphertext of the low 16 bits of pending balance. |
| 97  | 64 | `pending_balance_hi`                        | `EncryptedBalance` | Ciphertext of the high 48 bits of pending balance. |
| 161 | 64 | `available_balance`                         | `EncryptedBalance` | Ciphertext of the spendable balance. |
| 225 | 36 | `decryptable_available_balance`             | `DecryptableBalance` | AES-encrypted available balance the owner can cheaply decrypt. |
| 261 | 1  | `allow_confidential_credits`                | `bool` | Owner accepts incoming confidential transfers. |
| 262 | 1  | `allow_non_confidential_credits`            | `bool` | Owner accepts incoming non-confidential transfers. |
| 263 | 8  | `pending_balance_credit_counter`            | `u64` LE | Count of pending credits received. |
| 271 | 8  | `maximum_pending_balance_credit_counter`    | `u64` LE | Cap before the owner must apply pending → available. |
| 279 | 8  | `expected_pending_balance_credit_counter`   | `u64` LE | Counter the owner expected at last decrypt. |
| 287 | 8  | `actual_pending_balance_credit_counter`     | `u64` LE | Actual counter at last apply. |

Total payload: **295 bytes**.

## Why balance is split lo/hi and pending/available

Decrypting an ElGamal ciphertext to a full u64 is computationally hard (discrete log), so the balance is split into a 16-bit low and 48-bit high ciphertext to keep decryption tractable. The pending/available split plus the credit counters let the owner detect whether new deposits arrived since they last decrypted, preventing a race where they sign a transfer against a stale balance.

## Where you see it

Token accounts of confidential-transfer-enabled mints, after the owner configures the account and deposits into the confidential balance. The bytes are ciphertexts — opaque without the owner's (or auditor's) ElGamal key.

## Common gotchas

- **None of these are Ed25519 keys or plaintext amounts.** `elgamal_pubkey` is a Ristretto point; the balances are ciphertexts. Don't render them as addresses or numbers.
- **Two balance domains.** `*_balance` fields are twisted-ElGamal ciphertexts (64 bytes); `decryptable_available_balance` is a 36-byte AES blob the owner uses for cheap reads. They represent the same value via different schemes.
- **Pending must be applied to available before spending.** Incoming confidential credits accumulate in pending; `ApplyPendingBalance` moves them to available. A naive integration that ignores this sees deposits "missing" from the spendable balance.
- **Largest standard Token-2022 extension at 295 bytes.** A mint/account carrying it is substantially bigger than a bare one.
