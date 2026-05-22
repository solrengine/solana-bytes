---
slug: confidential-transfer-mint
category: token-2022
name: ConfidentialTransferMint (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 65
summary: Mint-side Token-2022 extension that enables confidential transfers — amounts are ElGamal-encrypted on-chain and proven correct with zero-knowledge proofs. This extension holds the policy; encrypted balances live on the account side.
fields:
  - authority
  - auto_approve_new_accounts
  - auditor_elgamal_pubkey
see_also:
  - token-2022-base
  - tlv-layout-primer
  - transfer-fee-config
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/confidential_transfer/mod.rs
    label: ConfidentialTransfer extension (program/src/extension/confidential_transfer/mod.rs)
last_verified: 2026-05-20
---

## What it is

`ConfidentialTransferMint` turns on confidential transfers for a token. When enabled, transfer amounts are **ElGamal-encrypted on-chain** — the ledger records that a transfer happened and proves it was valid (no negative balances, no inflation) using zero-knowledge proofs, but the amount itself is hidden from public view. This Mint-side extension is the *policy*; the actual encrypted balances live in the per-account `ConfidentialTransferAccount` extension.

## Why it exists

Public amounts are a real problem for payroll, B2B settlement, and any institutional use where transaction sizes are sensitive. Confidential Transfers give amount privacy while keeping Solana's trustless verification — the network never sees the plaintext but can still prove the math is sound. The auditor key provides a compliance escape hatch so a designated party can decrypt when required.

## Byte layout

This is the payload of a ConfidentialTransferMint TLV entry (`extension_type = 4`, `length = 65`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`                 | `OptionalNonZeroPubkey`            | Configures confidential-transfer settings on this mint. All-zero means None — config frozen. |
| 32 | 1  | `auto_approve_new_accounts` | `PodBool` (`u8`)                   | `1` = new accounts may use confidential transfers immediately; `0` = each account must be approved by the authority first. |
| 33 | 32 | `auditor_elgamal_pubkey`    | `OptionalNonZeroElGamalPubkey`     | Optional auditor who can decrypt every transfer amount. All-zero means None (no auditor). |

Total payload: **65 bytes**.

## Why the amount isn't here

This extension carries no balances — only policy. Each holder's encrypted balance, pending-balance counters, and per-account ElGamal pubkey live in the account-side `ConfidentialTransferAccount` extension. A confidential transfer instruction is accompanied by ZK proof instructions (range proofs, equality proofs) verified by the ZK ElGamal Proof program; the token program checks the proofs, then updates ciphertexts without ever seeing plaintext.

## Where you see it

Institutional stablecoins and payment rails that need amount privacy. Adoption is still early because the client-side cryptography (generating proofs, managing ElGamal keys) is heavier than a normal transfer, but it's the headline privacy feature of Token-2022.

## Common gotchas

- **An ElGamal pubkey is not an Ed25519 pubkey.** Both are 32 bytes, but `auditor_elgamal_pubkey` is a compressed Ristretto point used for ElGamal encryption — don't render or validate it as a normal Solana address.
- **`auto_approve_new_accounts = false` is an allowlist.** When false, the mint authority must approve each account before it can transact confidentially — a permissioning lever for regulated tokens.
- **The auditor can decrypt amounts, not seize funds.** The auditor key grants read access to ciphertexts, not transfer authority. Don't conflate it with [PermanentDelegate](/learn/token-2022/permanent-delegate).
- **Mint policy ≠ account state.** This extension only says confidential transfers are *possible*. A wallet must also configure the account-side extension and deposit into the confidential balance before it can send confidentially.
