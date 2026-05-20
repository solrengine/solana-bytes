---
slug: scaled-ui-amount
category: token-2022
name: ScaledUiAmount (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 56
summary: Mint-side Token-2022 extension that multiplies displayed balances by a configurable factor. The on-chain amount is unchanged; the UI amount is amount × multiplier — used for rebasing and stock-split-style display.
fields:
  - authority
  - multiplier
  - new_multiplier_effective_timestamp
  - new_multiplier
see_also:
  - interest-bearing-mint
  - token-2022-base
  - tlv-layout-primer
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/interface/src/extension/scaled_ui_amount/mod.rs
    label: ScaledUiAmountConfig struct (token-2022 interface)
last_verified: 2026-05-20
---

## What it is

ScaledUiAmount applies a multiplier to a token's *displayed* balance. Like [InterestBearing](/learn/token-2022/interest-bearing-mint), the raw on-chain `amount` never changes — `amount_to_ui_amount` multiplies it by the current multiplier. Unlike interest (which compounds over time), this is a single configurable factor the authority sets, ideal for rebases and stock-split-style adjustments.

## Why it exists

Some assets need their unit value restated: a tokenized fund doing a 2:1 split, a rebasing stablecoin, a reward token that periodically scales. Rather than mint/burn against every holder (which breaks composability), the mint just changes one multiplier and every wallet's displayed balance scales uniformly.

## Byte layout

This is the payload of a ScaledUiAmount TLV entry (`extension_type = 25`, `length = 56`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`                          | `OptionalNonZeroPubkey` | Can update the multiplier. All-zero = None (frozen). |
| 32 | 8  | `multiplier`                         | `f64` (IEEE-754 LE)     | Current display multiplier. |
| 40 | 8  | `new_multiplier_effective_timestamp` | `i64` LE (unix seconds) | When `new_multiplier` takes over. |
| 48 | 8  | `new_multiplier`                     | `f64` (IEEE-754 LE)     | Scheduled next multiplier. |

Total payload: **56 bytes**.

## Why two multipliers + a timestamp

Like the fee config's older/newer pattern, a multiplier change can be scheduled: set `new_multiplier` with a future `new_multiplier_effective_timestamp`, and decoders apply `multiplier` until that time, then `new_multiplier`. A correct UI picks the active multiplier based on the cluster clock.

## Where you see it

Tokenized funds, rebasing tokens, and any asset that periodically restates unit value. Newer than most extensions (type 25), so adoption is early but growing for RWA products.

## Common gotchas

- **Floating point on-chain — rare and notable.** The multiplier is an actual IEEE-754 `f64` (8 bytes, little-endian). Most Solana fields are integers; this is one of the few f64s. Decode the 8 bytes as a double, not a u64.
- **The raw `amount` is never scaled.** As with interest-bearing tokens, reading a [token account](/learn/spl-token/token-account) `amount` directly under-/over-reports value. Run it through `amountToUiAmount`.
- **Scheduled multiplier needs the clock.** Don't display `new_multiplier` as current until `new_multiplier_effective_timestamp` has passed.
- **Distinct from interest-bearing.** Interest compounds continuously from a rate; ScaledUiAmount is a discrete factor the authority sets. A token uses one or the other, not both, for the same purpose.
