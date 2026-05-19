---
slug: token-2022-base
category: token-2022
name: Token-2022 Mint/Account + Extensions
kind: account
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 165
summary: Token-2022 Mints and TokenAccounts share SPL Token's base layouts and append features as post-base TLV extension blocks — a 1-byte discriminator at offset 165 distinguishes Mint from TokenAccount.
example_address: 2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo
example_label: PYUSD (Token-2022)
fields:
  - base
  - padding
  - account_type
  - extensions
see_also:
  - mint
  - token-account
  - tlv-layout-primer
  - transfer-fee-config
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/state.rs
    label: Token-2022 base state (program/src/state.rs)
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/mod.rs
    label: Token-2022 extension layout
last_verified: 2026-05-19
---

## What it is

Token-2022 is a parallel SPL token program that keeps the base [Mint](/learn/spl-token/mint) and [TokenAccount](/learn/spl-token/token-account) layouts byte-identical to SPL Token and adds features through extensions. A Token-2022 Mint is owned by `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` rather than `TokenkegQ…`; everything else about the first 82 bytes (Mint) or 165 bytes (TokenAccount) is the same code path.

## Why it exists

SPL Token launched in 2020 with fixed account layouts. Adding fields would have invalidated every existing token on Solana, so new features — transfer fees, interest accrual, confidential transfers, metadata, transfer hooks, scaled UI amounts — landed in Token-2022 as **post-base TLV extensions** instead. The trade-off is intentional: SPL Token tokens stay forever stable, and new features live in a new program that explorers and wallets opt into.

## Byte layout

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 82 or 165 | base | SPL Token base | Byte-identical to [Mint](/learn/spl-token/mint) (82) or [TokenAccount](/learn/spl-token/token-account) (165). |
| 82 | 83 | padding (Mints only) | zero bytes | Mints are zero-padded out to 165 so the discriminator sits at a fixed offset regardless of base kind. |
| 165 | 1 | `account_type` | `u8` enum | `1` = Mint, `2` = TokenAccount. Only reliable on-chain way to tell them apart since both occupy 165 bytes before extensions start. |
| 166 | varies | extensions | TLV[] | One entry per active extension. See the [TLV layout primer](/learn/token-2022/tlv-layout-primer) for the 4-byte header format and walker algorithm. |

A bare Token-2022 Mint with no extensions is exactly 166 bytes (82 base + 83 padding + 1 discriminator). Anything larger has extensions attached.

## Where you see it

Token-2022 is the layer behind a growing slice of regulated and feature-rich tokens: PYUSD (PayPal's stablecoin), the BlackRock BUIDL token, USD Yield-style real-world-asset tokens, and most new payment-rail launches that need transfer fees or compliance controls. SPL Token still anchors the long tail of memecoins and pre-2024 issuances, so wallets and indexers must handle both programs.

## Common gotchas

- **Program owner is the only reliable type signal.** A 200-byte account could be a Token-2022 Mint with extensions, a custom account from an unrelated program, or anything else. Read `accountInfo.owner` first — if it's `Tokenz…`, the bytes follow this layout. Length alone tells you nothing.
- **A Token-2022 Mint and a TokenAccount can have the same size.** Both share offsets 0–164 after Mint padding; the `account_type` byte at offset 165 is the discriminator. Decoders that infer kind from length get this wrong for any Mint with even one small extension.
- **Base layout uses SPL's `COption` (4-byte tag).** Extensions don't — most use `OptionalNonZeroPubkey` (32 bytes, all-zeros = None) or Borsh `Option<T>` (1-byte tag). Three optional encodings coexist in a single Token-2022 account; pick the wrong one and your decoder slides three or four bytes off.
- **Extensions are append-only at the program level, but appear in a fixed order on-chain.** The Token-2022 program serializes them in a stable order determined by extension type number, not initialization order. If you write a decoder that depends on extension ordering, it will keep working — but don't assume a per-account ordering reflects the user's chronology.
