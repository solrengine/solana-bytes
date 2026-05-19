---
slug: transfer-fee-config
category: token-2022
name: TransferFeeConfig (extension)
kind: account
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 108
summary: Mint-side Token-2022 extension that charges a percentage fee on every transfer. Fees accumulate as withheld balances on recipient TokenAccounts and are claimed later by the withdraw authority.
example_address: 2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo
example_label: PYUSD Mint (Token-2022)
fields:
  - transfer_fee_config_authority
  - withdraw_withheld_authority
  - withheld_amount
  - older_transfer_fee
  - newer_transfer_fee
see_also:
  - token-2022-base
  - tlv-layout-primer
  - mint
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/transfer_fee/mod.rs
    label: TransferFee extension (program/src/extension/transfer_fee/mod.rs)
last_verified: 2026-05-19
---

## What it is

`TransferFeeConfig` is a Token-2022 Mint extension that imposes a percentage-based fee on every transfer of the token. Fees don't flow to a treasury at transfer time — they accumulate as **withheld** balances inside the recipient's TokenAccount (via the paired `TransferFeeAmount` extension), and the `withdraw_withheld_authority` claims them later.

## Why it exists

SPL Token has no native fees. Protocols (DEXes, payment apps, NFT royalty enforcers) charge fees by routing through an extra wallet at the application layer — lossy, hard to audit, easy to bypass. Token-2022 lets the *Mint itself* enforce a fee policy, so every transfer of the token pays the fee whether it's going through a DEX, a wallet send, or a CPI from another protocol.

## Byte layout

This is the **payload** of a TransferFeeConfig TLV entry (`extension_type = 1`, `length = 108`). The full on-chain entry is 4 bytes of TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)) plus this 108-byte payload.

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `transfer_fee_config_authority` | `OptionalNonZeroPubkey` | Updates fee config. All-zero pubkey means None (disabled — fees frozen forever). No tag byte. |
| 32 | 32 | `withdraw_withheld_authority`   | `OptionalNonZeroPubkey` | Claims withheld fees from TokenAccounts. All-zero means None (fees uncollectable). |
| 64 | 8  | `withheld_amount`               | `u64` LE                | Total fees withheld at the Mint level (separate from per-account withheld amounts). |
| 72 | 18 | `older_transfer_fee`            | `TransferFee` struct    | Pre-update fee config — active until `newer.epoch` lands. |
| 90 | 18 | `newer_transfer_fee`            | `TransferFee` struct    | Active fee config from `newer.epoch` onwards. |

The nested `TransferFee` struct is **18 bytes**:

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 8 | `epoch`                     | `u64` LE | Epoch this fee config became (or becomes) active. |
| 8  | 8 | `maximum_fee`               | `u64` LE | Absolute cap in atomic units (per transfer). |
| 16 | 2 | `transfer_fee_basis_points` | `u16` LE | Fee rate in basis points (100 = 1%). |

Total payload: **108 bytes**.

## Why two fee configs

Fee changes don't take effect immediately. When the authority sets a new fee via `SetTransferFee`, the value goes into `newer_transfer_fee` with `epoch` set to two epochs ahead; until then, the network keeps charging `older_transfer_fee`. The two-config + epoch model gives holders a window to react before the new rate kicks in.

A decoder displaying the *current* fee must read the cluster's current epoch and pick `newer` if `current_epoch >= newer.epoch`, otherwise `older`. Showing only `newer.transfer_fee_basis_points` is the canonical bug here.

## Where you see it

PYUSD (PayPal's stablecoin) carries this extension with a 0 basis-point config — present for compliance auditability without actually charging. Real-fee deployments are rarer but growing: revenue-sharing community tokens, RWA tokens with transfer royalties, some experimental memecoins that route fees back to a creator wallet.

## Common gotchas

- **Token-2022 extensions use a third optional encoding: `OptionalNonZeroPubkey`.** Same 32-byte size as a plain `Pubkey` with no tag byte — all-zero bytes mean None. Distinct from both SPL's `COption<Pubkey>` (4-byte tag + 32 = 36 bytes) and Borsh's `Option<Pubkey>` (1-byte tag + 32 = 33 bytes). Three optional encodings coexist in a single Token-2022 account.
- **Fees withhold, they don't burn.** The fee subtracts from the sender's balance and lands in the recipient's per-account `TransferFeeAmount.withheld_amount` extension. The `withdraw_withheld_authority` then sweeps these via `WithdrawWithheldTokensFromAccounts` and `WithdrawWithheldTokensFromMint`.
- **`maximum_fee` is per-transfer, not per-period.** A 1% fee on a 1,000,000 USDC transfer with `maximum_fee = 1000` caps at $0.001 (atomic units = 1000), not the $10,000 the basis points would imply on an uncapped fee.
- **Two-epoch update delay.** Setting a new fee doesn't take effect until *next-next* epoch — roughly four to five days in production. Plan UI copy and notifications around that lag.
- **Reading the active fee requires the cluster's current epoch.** Don't display `newer_transfer_fee` parameters as "the fee" unless the epoch has rolled; otherwise users see a rate they aren't actually paying yet.
