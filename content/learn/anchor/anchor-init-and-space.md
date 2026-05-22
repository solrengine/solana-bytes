---
slug: anchor-init-and-space
category: anchor
name: Anchor init & Account Space
kind: concept
status: live
program_id: null
program_label: Anchor framework
size: null
summary: How Anchor's #[account(init)] sizes a new account — 8 discriminator bytes plus the Borsh-serialized field sizes — and why getting the byte count right is what makes the account rent-exempt.
fields:
  - discriminator_8
  - field_sizes
  - rent_exemption
see_also:
  - account-discriminator
  - rent-and-account-size
  - system-instructions
sources:
  - url: https://www.anchor-lang.com/docs/space
    label: Anchor docs — space reference
last_verified: 2026-05-20
---

## What it is

When an Anchor account is created with `#[account(init, payer = …, space = N)]`, `N` is the exact byte size to allocate. That size must equal 8 (the [discriminator](/learn/anchor/account-discriminator)) plus the Borsh-serialized size of every field. Get it right and the account is rent-exempt and correctly sized; get it wrong and you either waste rent or can't fit the data.

## Why it exists

Solana accounts have a fixed size set at creation, and you pre-pay rent for that size to be rent-exempt. Anchor doesn't know your struct's serialized size automatically in older versions, so you declare it. The byte math is the bridge between your Rust types and the on-chain allocation.

## Byte layout

The space budget is a sum of byte sizes:

| Component | Bytes | Notes |
|-----------|------:|-------|
| discriminator | 8 | Always — every Anchor account starts with it. |
| `bool` | 1 | |
| `u8` / `i8` | 1 | |
| `u16` / `i16` | 2 | |
| `u32` / `i32` | 4 | |
| `u64` / `i64` | 8 | |
| `Pubkey` | 32 | |
| `Option<T>` | 1 + sizeof(T) | 1-byte Borsh tag + the inner value when present. |
| `Vec<T>` | 4 + len × sizeof(T) | 4-byte length prefix; you must budget for the max length. |
| `String` | 4 + max_byte_len | 4-byte length prefix + UTF-8 bytes; budget the max. |

So a struct `{ owner: Pubkey, amount: u64, label: String(≤16) }` needs `8 + 32 + 8 + (4 + 16) = 68` bytes.

## Where you see it

Every `init` constraint in an Anchor program, and the rent calculation behind every account-creation transaction. The allocated size shows up as the account's `space`/data length on-chain.

## Common gotchas

- **Always add 8.** The discriminator is part of the account; forgetting it under-allocates by exactly 8 bytes and your last field gets truncated. The single most common Anchor space bug.
- **`Vec` and `String` need a max budget.** They're variable-length but the account is fixed-size — you must reserve space for the largest value you'll ever store, plus the 4-byte length prefix.
- **`Option<T>` is 1 + T, not T.** The Borsh tag byte is always present even when the value is None. Don't size it as just `sizeof(T)`.
- **Over-allocating wastes rent; under-allocating bricks writes.** Size is locked at creation (absent realloc). Compute it exactly. Recent Anchor offers `InitSpace` derive to compute it for you — prefer it over hand-counting.
