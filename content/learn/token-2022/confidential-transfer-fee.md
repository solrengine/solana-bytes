---
slug: confidential-transfer-fee
category: token-2022
name: ConfidentialTransferFee (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 129
summary: The pair of extensions that let transfer fees work on confidential transfers — a mint-side config with an ElGamal key for encrypted withheld fees, and an account-side encrypted withheld amount.
fields:
  - authority
  - withdraw_withheld_authority_elgamal_pubkey
  - harvest_to_mint_enabled
  - withheld_amount
see_also:
  - transfer-fee-config
  - confidential-transfer-mint
  - confidential-transfer-account
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/interface/src/extension/confidential_transfer_fee/mod.rs
    label: ConfidentialTransferFee structs (token-2022 interface)
last_verified: 2026-05-20
---

## What it is

When a token has both [transfer fees](/learn/token-2022/transfer-fee-config) and [confidential transfers](/learn/token-2022/confidential-transfer-mint), the withheld fees themselves must stay encrypted — otherwise the fee would leak the transfer amount. This pair of extensions handles that: a mint-side `ConfidentialTransferFeeConfig` and an account-side `ConfidentialTransferFeeAmount`, both keeping withheld fees as ElGamal ciphertexts.

## Why it exists

A plaintext withheld fee on a percentage-fee token reveals the transfer amount (amount = fee / rate). To preserve confidentiality, the withheld fee is encrypted under a dedicated ElGamal key held by the withdraw-withheld authority, who can decrypt and collect without the public seeing individual amounts.

## Byte layout

**ConfidentialTransferFeeConfig** — mint-side (`extension_type = 16`):

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`                                  | `OptionalNonZeroPubkey` | Configures the confidential fee. All-zero = None. |
| 32 | 32 | `withdraw_withheld_authority_elgamal_pubkey` | `ElGamalPubkey`         | ElGamal key withheld fees are encrypted under. |
| 64 | 1  | `harvest_to_mint_enabled`                    | `bool`                  | Whether accounts may harvest withheld fees to the mint. |
| 65 | 64 | `withheld_amount`                            | `EncryptedWithheldAmount` | ElGamal ciphertext of fees withheld at the mint. |

Total: **129 bytes**.

**ConfidentialTransferFeeAmount** — account-side (`extension_type = 17`):

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 64 | `withheld_amount` | `EncryptedWithheldAmount` | ElGamal ciphertext of fees withheld on this account. |

Total: **64 bytes**.

## How it relates to the plaintext fee

A token can have a [TransferFeeConfig](/learn/token-2022/transfer-fee-config) (the rate/cap policy) *and* this confidential pair (the encrypted withholding) at once. Non-confidential transfers withhold plaintext into `TransferFeeAmount`; confidential transfers withhold ciphertext into `ConfidentialTransferFeeAmount`. The withdraw authority sweeps both.

## Where you see it

Tokens combining percentage fees with amount privacy — early and rare, but the standards-track way to do "private but fee-bearing" assets.

## Common gotchas

- **The withheld fee is encrypted under a separate ElGamal key**, distinct from any holder's account key — the one in `withdraw_withheld_authority_elgamal_pubkey`. Only that authority can decrypt withheld totals.
- **Two extensions, two sides.** Config (16) is mint-side; Amount (17) is account-side. Don't expect the 64-byte account-side blob to carry the policy fields.
- **Requires both confidential transfers and transfer fees enabled.** This pair only appears on mints that have both features — it's the bridge between them.
- **`withheld_amount` is a ciphertext, not a number.** 64 bytes of ElGamal, not a u64. Decode only with the withdraw authority's key.
