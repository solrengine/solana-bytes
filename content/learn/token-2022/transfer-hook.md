---
slug: transfer-hook
category: token-2022
name: TransferHook (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 64
summary: Mint-side Token-2022 extension that calls a custom program on every transfer. The token program CPIs into the hook's Execute instruction, enabling allowlists, royalty enforcement, and per-transfer logic.
fields:
  - authority
  - program_id
see_also:
  - token-2022-base
  - tlv-layout-primer
  - transfer-fee-config
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/transfer_hook/mod.rs
    label: TransferHook extension (program/src/extension/transfer_hook/mod.rs)
  - url: https://github.com/solana-program/libraries/tree/main/transfer-hook
    label: SPL Transfer Hook Interface
last_verified: 2026-05-20
---

## What it is

`TransferHook` makes the token program call a custom program on **every transfer** of the token. After moving the tokens, the Token-2022 program CPIs into the hook program's `Execute` instruction, letting arbitrary on-chain logic run — allowlist checks, royalty collection, transfer logging, rate limiting. The hook program implements the SPL Transfer Hook Interface.

## Why it exists

`TransferFeeConfig` covers fees and `NonTransferable` covers soulbinding, but issuers wanted *programmable* transfer behavior: "only addresses on this allowlist may receive," "charge a dynamic royalty," "record every transfer to an audit account." Rather than bake every policy into the token program, Token-2022 delegates to a user-supplied program on each transfer.

## Byte layout

This is the payload of a TransferHook TLV entry (`extension_type = 14`, `length = 64`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`  | `OptionalNonZeroPubkey` | Can update the hook program id. All-zero means None — hook frozen. |
| 32 | 32 | `program_id` | `OptionalNonZeroPubkey` | The hook program CPI'd on every transfer. All-zero means None — no hook runs. |

Total payload: **64 bytes**.

## How a transfer flows

On `TransferChecked`, the token program: (1) moves the tokens, (2) reads the extra account metas the hook program published (via a PDA the hook owns), (3) CPIs into the hook's `Execute` with those accounts. If `Execute` errors, the whole transfer reverts. The account-side `TransferHookAccount` extension (type 15) carries a transferring flag the hook can check to know it's being called mid-transfer rather than directly.

## Where you see it

Allowlist-gated tokens, royalty-enforced NFTs (a hook that requires a royalty payment account in the transfer), and compliance tokens that log or screen each movement. It's the most flexible — and most integration-heavy — Token-2022 extension.

## Common gotchas

- **Transfers need extra accounts.** A hook usually requires accounts beyond the normal transfer set (its config PDA, an allowlist account, etc.). Clients must resolve these via the hook's extra-account-meta PDA *before* building the transfer, or it fails. This is the #1 transfer-hook integration bug.
- **A failing hook reverts the transfer.** The hook's `Execute` is part of the transaction. If it errors (address not allowlisted, royalty unpaid), the transfer doesn't happen. Surface hook failures distinctly from balance/fee failures.
- **The hook program is arbitrary code.** Treat a token with a transfer hook as carrying third-party logic on every move — audit the hook program before integrating, the same way you'd vet any program you CPI into.
- **`program_id = None` means no hook runs** even though the extension exists. The extension's presence isn't enough; the program id must be set.
