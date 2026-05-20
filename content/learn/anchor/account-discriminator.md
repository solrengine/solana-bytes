---
slug: account-discriminator
category: anchor
name: Anchor Account Discriminator
kind: concept
status: live
program_id: null
program_label: Anchor framework
size: 8
summary: The 8-byte prefix Anchor stamps on every account it owns, derived from the account's struct name. It's how an Anchor program tells its own account types apart.
fields:
  - discriminator
see_also:
  - instruction-discriminator
  - anchor-init-and-space
  - coption-vs-option
sources:
  - url: https://www.anchor-lang.com/docs/account-types
    label: Anchor docs — account types
last_verified: 2026-05-20
---

## What it is

Every account created by an Anchor program begins with an 8-byte **discriminator** — a fingerprint derived from the account's Rust struct name. When the program loads an account, it checks these 8 bytes first to confirm "yes, this is a `UserStats`, not a `Vault`," before deserializing the rest.

## Why it exists

A single program often owns many account types, all owned by the same program id. Without a type tag, the program couldn't safely tell a `Vault` from a `Config` — a caller could pass the wrong account and the program would blindly deserialize garbage. The discriminator makes type confusion a clean error instead of a silent corruption.

## Byte layout

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 8 | `discriminator` | `[u8; 8]` | First 8 bytes of `sha256("account:<StructName>")`. |
| 8 | … | account fields | Borsh | The Borsh-serialized struct follows. |

The discriminator is computed at build time as:

```text
discriminator = sha256("account:" + StructName)[0..8]
```

So a struct named `UserStats` is prefixed with the first 8 bytes of `sha256("account:UserStats")`. The namespace string is literally `account:` — distinct from the `global:` namespace used for [instruction discriminators](/learn/anchor/instruction-discriminator).

## Where you see it

The first 8 bytes of any account owned by an Anchor program. When you hex-dump an Anchor account and the first 8 bytes look like random noise before the recognizable fields begin, that's the discriminator.

## Common gotchas

- **It's 8 bytes of the hash, not the whole hash.** Only the first 8 bytes of the SHA-256 are used. Collisions are astronomically unlikely across one program's account set.
- **The struct *name* is the input, not the field layout.** Renaming a struct changes its discriminator and breaks every existing account of that type — a migration hazard. Renaming a *field* doesn't.
- **Account space must include the 8 bytes.** When allocating, you reserve `8 + sizeof(fields)`. Forgetting the 8 is the most common Anchor space bug — see [init and space](/learn/anchor/anchor-init-and-space).
- **Recent Anchor versions allow custom discriminators**, but the `sha256("account:Name")[0..8]` default is what you'll see on the vast majority of accounts.
