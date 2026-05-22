---
slug: interest-bearing-mint
category: token-2022
name: InterestBearingConfig (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 52
summary: Mint-side Token-2022 extension that makes a token accrue interest continuously. The stored balance never changes — the UI amount is computed from a rate and elapsed time.
fields:
  - rate_authority
  - initialization_timestamp
  - pre_update_average_rate
  - last_update_timestamp
  - current_rate
see_also:
  - token-2022-base
  - tlv-layout-primer
  - transfer-fee-config
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/interest_bearing_mint/mod.rs
    label: InterestBearing extension (program/src/extension/interest_bearing_mint/mod.rs)
last_verified: 2026-05-20
---

## What it is

`InterestBearingConfig` is a Token-2022 Mint extension that makes a token *appear* to accrue continuously-compounded interest. The crucial detail: no interest is ever written to any account. The raw `amount` in every TokenAccount stays exactly what was minted or transferred — interest is a **display transformation** applied by `amount_to_ui_amount`, computed from the rate and the time elapsed.

## Why it exists

Rebasing tokens (where balances grow on-chain) break composability — every transfer would have to touch a global index, and integrators see balances change out from under them. Token-2022's approach keeps the on-chain balance immutable and pushes the interest math into a deterministic function of `(principal, rate, elapsed_time)`. Wallets and explorers call `amountToUiAmount` to show the grown value; the ledger stays clean.

## Byte layout

This is the payload of an InterestBearingConfig TLV entry (`extension_type = 10`, `length = 52`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `rate_authority`            | `OptionalNonZeroPubkey` | Can change the rate. All-zero means None — rate frozen forever. |
| 32 | 8  | `initialization_timestamp`  | `i64` LE (unix seconds) | When the extension was initialized. |
| 40 | 2  | `pre_update_average_rate`   | `i16` LE basis points   | Time-weighted average rate that applied *before* the last update. |
| 42 | 8  | `last_update_timestamp`     | `i64` LE (unix seconds) | When `current_rate` took effect. |
| 50 | 2  | `current_rate`              | `i16` LE basis points   | Rate in effect since `last_update_timestamp`. Signed — can be negative. |

Total payload: **52 bytes**.

## Why two rates

Interest must be continuous across rate changes. The amount accrued *before* the last update is computed with `pre_update_average_rate` over `(initialization_timestamp → last_update_timestamp)`; the amount accrued *since* uses `current_rate` over `(last_update_timestamp → now)`. The "average" field collapses the entire pre-update history into one blended rate so the math stays O(1) regardless of how many times the rate has changed.

## Where you see it

Yield-bearing stablecoins and tokenized treasury products use this so a holder's displayed balance grows without any on-chain transaction. It's most common in RWA (real-world-asset) tokens where the issuer publishes an APY as a basis-point rate.

## Common gotchas

- **The on-chain `amount` never reflects interest.** If you read a TokenAccount's raw `amount` and show it directly, you'll under-report the holder's value. Always run it through `amountToUiAmount` for interest-bearing mints.
- **The rate is signed (`i16`).** Negative rates are legal — a demurrage token that shrinks over time. Don't parse it as unsigned.
- **Basis points, continuously compounded.** `current_rate = 500` is 5% APR compounded continuously, not 5% simple. The program uses `e^(rate × t)`, so the displayed amount diverges from naive simple-interest math over long horizons.
- **`rate_authority = None` freezes the rate, not the interest.** Interest keeps accruing at the last set rate forever; None just means nobody can change it.
