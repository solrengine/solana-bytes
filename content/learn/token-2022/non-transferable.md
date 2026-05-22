---
slug: non-transferable
category: token-2022
name: NonTransferable (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 0
summary: Mint-side Token-2022 extension that makes a token soulbound — it can be minted and burned but never transferred. Its byte payload is empty; the extension's presence is the entire signal.
fields:
  - (no payload)
see_also:
  - token-2022-base
  - tlv-layout-primer
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/non_transferable/mod.rs
    label: NonTransferable extension (program/src/extension/non_transferable/mod.rs)
last_verified: 2026-05-20
---

## What it is

`NonTransferable` makes a token soulbound: once it lands in an account, it can never move to another account. It can still be minted and burned, but `Transfer` and `TransferChecked` always fail. It's the canonical primitive for credentials, achievement badges, non-tradeable receipts, and proof-of-attendance tokens.

## Why it exists

Before Token-2022, "soulbound" tokens were enforced off-chain (a backend that refused to build transfer transactions) or by freezing every account — fragile and bypassable. Making non-transferability a Mint-level rule means the *program itself* rejects transfers, no matter what client constructs the transaction.

## Byte layout

This is the simplest extension in Token-2022 — it has **no payload**. The entire on-chain footprint is the 4-byte TLV header with a zero length:

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 2 | `extension_type` | `u16` LE | `9` = NonTransferable. |
| 2 | 2 | `length`         | `u16` LE | `0` — there is no payload. |

Total entry: **4 bytes** (header only), **0 bytes** of payload.

The extension is a pure flag: its *presence* in the mint's TLV list is the entire signal. A decoder doesn't read any value — it just notes that extension type 9 exists and concludes the token is soulbound.

## The account-side counterpart

Mints carry `NonTransferable` (type 9). TokenAccounts holding such a token automatically get a paired `NonTransferableAccount` (type 13) extension, *also* empty. The program adds it on account initialization so that account-level tooling can detect soulboundness without resolving the mint.

## Where you see it

Credential and identity tokens, hackathon POAPs, locked vesting receipts, and "you cannot sell this" reward tokens. Any time an issuer wants a token that proves something about the holder but must not become a tradeable asset.

## Common gotchas

- **An empty payload is still a real extension.** Decoders that assume every TLV entry has data will mis-walk the list if they try to read a payload here. The `length = 0` is correct and meaningful — advance by exactly 4 bytes.
- **Burning is still allowed.** NonTransferable blocks `Transfer`, not `Burn`. Holders can always destroy the token; they just can't move it.
- **Accounts of a NonTransferable mint also get `ImmutableOwner`.** This prevents the obvious bypass — transferring *ownership of the account* instead of the tokens. The program auto-adds it; you'll see ImmutableOwner (type 7) alongside NonTransferableAccount on these accounts.
- **It's mint-wide and permanent.** There's no authority to toggle it off. A token is either born soulbound or it isn't.
