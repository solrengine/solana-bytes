---
slug: default-account-state
category: token-2022
name: DefaultAccountState (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 1
summary: Mint-side Token-2022 extension that sets the state new TokenAccounts start in. Setting it to Frozen turns the token into an allowlist — accounts must be thawed before they can transact.
fields:
  - state
see_also:
  - token-2022-base
  - tlv-layout-primer
  - token-account
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/default_account_state/mod.rs
    label: DefaultAccountState extension (program/src/extension/default_account_state/mod.rs)
last_verified: 2026-05-20
---

## What it is

`DefaultAccountState` controls what state a newly created TokenAccount starts in. Normally accounts open `Initialized` and can transact immediately. Set this extension to `Frozen` and every new account opens frozen — it can't send or receive until the mint's freeze authority explicitly thaws it. That turns the token into an allowlist.

## Why it exists

Permissioned tokens (KYC'd stablecoins, regulated securities, gated communities) need to vet holders before letting them transact. Without this extension you'd have to race a freeze instruction against the user's first transfer. DefaultAccountState makes "deny by default" the ground truth: nobody can move the token until the issuer approves their account.

## Byte layout

This is the payload of a DefaultAccountState TLV entry (`extension_type = 6`, `length = 1`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `state` | `u8` enum | The `AccountState` new accounts inherit: `0` Uninitialized, `1` Initialized, `2` Frozen. In practice this is `1` (normal) or `2` (allowlist). |

Total payload: **1 byte**.

## Where you see it

KYC/AML stablecoins, tokenized securities, and permissioned DeFi pools. Any token whose issuer must approve a holder before they can use it. The same `AccountState` enum value also appears in the base [TokenAccount](/learn/spl-token/token-account) `state` field — this extension just sets the default new accounts copy from.

## Common gotchas

- **Changing the default doesn't re-freeze existing accounts.** Updating `DefaultAccountState` only affects accounts created *after* the change. Already-thawed accounts stay thawed; the issuer must freeze them individually if needed.
- **Requires a freeze authority on the mint.** "Default frozen" is useless if there's no freeze authority to thaw accounts. The two go together — a mint with default-frozen state and no freeze authority bricks every new account permanently.
- **It's one byte, but it gates the whole token's UX.** A wallet that doesn't check this extension will let a user open an account, attempt a transfer, and hit an opaque "account frozen" failure. Reference-grade tooling surfaces "this token requires approval" up front.
