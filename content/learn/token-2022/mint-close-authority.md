---
slug: mint-close-authority
category: token-2022
name: MintCloseAuthority (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 32
summary: Mint-side Token-2022 extension that names an authority allowed to close the mint and reclaim its rent — but only once supply is zero. SPL Token mints could never be closed.
fields:
  - close_authority
see_also:
  - token-2022-base
  - tlv-layout-primer
  - mint
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/mint_close_authority/mod.rs
    label: MintCloseAuthority extension (program/src/extension/mint_close_authority/mod.rs)
last_verified: 2026-05-20
---

## What it is

`MintCloseAuthority` names an address allowed to close the mint account itself and recover the rent-exempt lamports locked in it — provided the mint's supply is zero. It's a small extension that fixes a long-standing SPL Token annoyance: a created-then-abandoned mint locked its rent forever.

## Why it exists

In SPL Token, a [Mint](/learn/spl-token/mint) account can never be closed. Every test mint, every mistaken deployment, every wound-down token left ~0.0015 SOL of rent stranded permanently. Token-2022 lets a designated authority close a fully-burned mint and reclaim that rent, which matters at scale for issuers who spin up and retire many mints.

## Byte layout

This is the payload of a MintCloseAuthority TLV entry (`extension_type = 3`, `length = 32`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 32 | `close_authority` | `OptionalNonZeroPubkey` | May close the mint to reclaim rent. All-zero means None — the mint can never be closed (SPL Token behavior). |

Total payload: **32 bytes**.

## Where you see it

Issuers that programmatically create and retire mints (test environments, ephemeral campaign tokens, factory-style token launchers). Most long-lived tokens leave this as None.

## Common gotchas

- **Supply must be zero to close.** The program rejects `CloseAccount` on a mint with any outstanding supply. Every token must be burned first; otherwise the close fails and the rent stays locked.
- **Closing the mint is permanent and frees the address.** After close, the account is gone and its address could in principle be reused by a new account. Don't cache a closed mint's metadata as if the address is stable.
- **It's a separate authority from mint/freeze authority.** The close authority can be a different key than the mint authority or freeze authority. Don't assume one key holds all three.
- **None at creation is forever.** Like other mint extensions, if the mint shipped without a close authority it can never gain one — the rent is locked for good, exactly as in SPL Token.
