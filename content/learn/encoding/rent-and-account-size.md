---
slug: rent-and-account-size
category: encoding
name: Rent & Account Size
kind: concept
status: live
program_id: null
program_label: Encoding
size: null
summary: Why every Solana account has a fixed byte size set at creation and a minimum SOL balance to stay alive. Rent exemption is a deposit proportional to size — refundable when the account closes.
fields:
  - data_length
  - rent_exempt_balance
see_also:
  - anchor-init-and-space
  - mint-close-authority
  - system-instructions
sources:
  - url: https://solana.com/docs/core/accounts#rent
    label: Solana docs — rent
last_verified: 2026-05-20
---

## What it is

Every Solana account reserves a fixed number of bytes (`data_length`) chosen when it's created, and must hold a minimum SOL balance proportional to that size to be **rent-exempt**. Below the threshold, an account would be subject to rent collection and eventually purged; at or above it, the account lives indefinitely.

## Why it exists

Account data lives in validators' memory and must be paid for. Rent exemption front-loads that cost: you deposit ~2 years of rent up front, and the account never gets collected. The deposit is refundable — close the account and the lamports go back to whoever you designate.

## Byte layout

Rent isn't a field inside the account; it's a relationship between two header values:

| Header value | Type | Notes |
|--------------|------|-------|
| `data_length` (a.k.a. `space`) | `u64` | Fixed byte size of the account's data, set at creation. |
| `lamports` | `u64` | Current balance. Must be ≥ the rent-exempt minimum for this `data_length`. |

The rent-exempt minimum is roughly:

```text
rent_exempt_lamports ≈ (128 + data_length) bytes
                        × lamports_per_byte_year
                        × 2 years
```

The `128` is fixed per-account metadata overhead. As a rule of thumb it works out to about **0.00089 SOL for a 0-byte account** plus roughly **0.00000696 SOL per additional byte**, so an 82-byte [Mint](/learn/spl-token/mint) needs ~0.0014 SOL and a 165-byte [Token Account](/learn/spl-token/token-account) ~0.002 SOL.

## Where you see it

Every account-creation transaction funds the new account to its rent-exempt minimum. `getMinimumBalanceForRentExemption(size)` returns the exact figure for a given byte length.

## Common gotchas

- **Size is fixed at creation.** You can't grow an account later without `realloc` (which itself is capped per transaction and needs extra rent). Plan [account space](/learn/anchor/anchor-init-and-space) up front.
- **Rent is a deposit, not a fee.** It's not consumed — it's locked. Closing the account refunds the full lamport balance to the recipient you specify.
- **Under-funding leaves the account collectible.** An account below the rent-exempt minimum can be garbage-collected. Practically every account is created rent-exempt for this reason.
- **The 128-byte overhead is real.** A "0-byte" account still costs rent for 128 bytes of metadata. Tiny accounts aren't free.
- **SPL Token mints couldn't reclaim rent until Token-2022.** A closed-out SPL Mint stranded its rent forever; [MintCloseAuthority](/learn/token-2022/mint-close-authority) fixed that for Token-2022.
