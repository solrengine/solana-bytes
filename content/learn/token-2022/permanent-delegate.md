---
slug: permanent-delegate
category: token-2022
name: PermanentDelegate (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 32
summary: Mint-side Token-2022 extension that grants one address unlimited authority to transfer or burn tokens from any account of the mint, forever. The clawback primitive — powerful and dangerous.
fields:
  - delegate
see_also:
  - token-2022-base
  - tlv-layout-primer
  - default-account-state
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/permanent_delegate/mod.rs
    label: PermanentDelegate extension (program/src/extension/permanent_delegate/mod.rs)
last_verified: 2026-05-20
---

## What it is

`PermanentDelegate` names a single address that can transfer or burn tokens from **any** account holding this mint, in **any** amount, **without the account owner's approval** — permanently. It's the clawback primitive: the issuer keeps the ability to move or destroy tokens regardless of who holds them.

## Why it exists

Some assets legally require recovery powers: regulated stablecoins that must freeze and seize funds tied to sanctioned addresses, game studios that need to revoke items, enterprise tokens with compliance obligations. SPL Token has no such mechanism — once a token leaves your account, only the holder can move it. Token-2022 adds the permanent delegate so issuers who need clawback can have it (and holders can see it exists before they hold the token).

## Byte layout

This is the payload of a PermanentDelegate TLV entry (`extension_type = 12`, `length = 32`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 32 | `delegate` | `OptionalNonZeroPubkey` | The permanent delegate. All-zero means None — no permanent delegate (cannot be added later if the mint shipped without it). |

Total payload: **32 bytes**.

## Where you see it

Compliance-grade stablecoins, tokenized real-world assets with legal recovery requirements, and game economies. Any token where the issuer must retain control after distribution.

## Common gotchas

- **It overrides the owner entirely.** The permanent delegate doesn't need the holder's signature or a per-account delegate approval. It can act on every account of the mint at will. Treat any token with this extension as custodial in spirit.
- **Surface it loudly in wallets.** Users should know before acquiring a token that a third party can move or burn it. A reference-grade wallet flags PermanentDelegate the way it flags a freeze authority — arguably more loudly.
- **It can't be added after the fact.** Like most mint extensions, it must be present when the mint is created. A mint that shipped without it can never gain a permanent delegate — which is itself a useful trust signal.
- **Distinct from the auditor key.** The [ConfidentialTransferMint](/learn/token-2022/confidential-transfer-mint) auditor can only *read* amounts; the permanent delegate can *move and destroy* tokens. Don't conflate the two powers.
