---
slug: cpi-guard
category: token-2022
name: CpiGuard (extension)
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: 1
summary: Account-side Token-2022 extension that, when enabled, blocks certain token actions from happening inside a CPI — protecting users from malicious programs that try to redirect approvals or close accounts mid-call.
fields:
  - lock_cpi
see_also:
  - token-2022-base
  - tlv-layout-primer
  - permanent-delegate
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/interface/src/extension/cpi_guard/mod.rs
    label: CpiGuard struct (token-2022 interface)
last_verified: 2026-05-20
---

## What it is

CpiGuard is an account-side opt-in that, when enabled, prevents certain token operations from being performed via cross-program invocation (CPI). With the guard on, a program a user interacts with can't silently approve a delegate, change the account's owner/close authority, or close the account into an attacker-chosen destination — those actions must come directly from the user, not from inside another program's call.

## Why it exists

A user signing a transaction to "use" some dapp implicitly authorizes whatever CPIs that dapp makes. A malicious or compromised program could abuse that to, say, set itself as a delegate and drain the account later. CpiGuard lets cautious users (or wallets) lock the dangerous operations to direct, non-CPI calls only.

## Byte layout

This is the payload of a CpiGuard TLV entry (`extension_type = 11`, `length = 1`). The full on-chain entry adds the 4-byte TLV header (see the [TLV layout primer](/learn/token-2022/tlv-layout-primer)).

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `lock_cpi` | `bool` (`u8`) | `1` = CPI guard active for this account; `0` = inactive. |

Total payload: **1 byte**.

## What it blocks when active

With `lock_cpi = 1`, the following are rejected if attempted within a CPI: `Approve` (setting a delegate), `SetAuthority` for the close/owner authorities, `CloseAccount` to an arbitrary destination, and using a delegate that was set via CPI. The user must perform these directly.

## Where you see it

Wallet-managed accounts that opt into extra safety, and cautious power users. It's account-level (set by the owner), not mint-level — the token issuer doesn't impose it.

## Common gotchas

- **It's account-side, not mint-side.** The account owner enables it on their own [token account](/learn/spl-token/token-account); it has nothing to do with the mint's policy. Contrast with mint extensions like [PermanentDelegate](/learn/token-2022/permanent-delegate).
- **Single byte, but it changes call semantics.** A program integrating Token-2022 must handle the case where a guarded account rejects an in-CPI approval/close — surface a clear error rather than a generic failure.
- **Doesn't block direct actions.** The user can still approve delegates and close the account themselves; only the *CPI* path is gated.
