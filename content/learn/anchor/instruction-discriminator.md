---
slug: instruction-discriminator
category: anchor
name: Anchor Instruction Discriminator
kind: concept
status: live
program_id: null
program_label: Anchor framework
size: 8
summary: The 8-byte prefix on every Anchor instruction's data, derived from the instruction name. It's how an Anchor program routes incoming instructions to the right handler.
fields:
  - discriminator
see_also:
  - account-discriminator
  - anchor-init-and-space
  - system-instructions
sources:
  - url: https://www.anchor-lang.com/docs/the-program-module
    label: Anchor docs — the program module
last_verified: 2026-05-20
---

## What it is

Every instruction sent to an Anchor program starts its data with an 8-byte **discriminator** derived from the instruction's name. The program reads these 8 bytes to decide which handler to dispatch to, then Borsh-decodes the remaining bytes as that handler's arguments.

## Why it exists

A program exposes many instructions (`initialize`, `deposit`, `withdraw`, …). Native programs use a small integer tag; Anchor uses an 8-byte name-derived hash so dispatch is collision-resistant and you never hand-assign instruction numbers. The framework generates both the on-chain match and the client-side encoder from the same source.

## Byte layout

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 8 | `discriminator` | `[u8; 8]` | First 8 bytes of `sha256("global:<instruction_name>")`. |
| 8 | … | arguments | Borsh | The Borsh-serialized instruction args follow. |

The discriminator is:

```text
discriminator = sha256("global:" + snake_case_instruction_name)[0..8]
```

So an instruction `fn deposit(...)` has data beginning with the first 8 bytes of `sha256("global:deposit")`. The namespace is `global:` — distinct from `account:` used for [account discriminators](/learn/anchor/account-discriminator).

## Where you see it

The first 8 bytes of the `data` field in any instruction targeting an Anchor program. When you decode a [transaction](/learn/transactions/legacy-transaction) and an instruction's data starts with 8 opaque bytes before recognizable arguments, that's the dispatch tag.

## Common gotchas

- **Name, snake_cased, is the input.** `fn initializeVault` becomes `global:initialize_vault`. Renaming an instruction changes its discriminator and breaks every client that hardcoded the old bytes.
- **8 bytes, then Borsh args.** After the discriminator, arguments are plain Borsh — a `u64` is 8 little-endian bytes, an `Option<T>` is a 1-byte tag, etc. (see [Borsh vs bincode](/learn/encoding/borsh-vs-bincode)).
- **Events and state use different namespaces.** Anchor events use `event:`; the legacy `#[state]` used another. The common instruction case is `global:`.
- **Not the same as native 1-byte/4-byte tags.** An Anchor program's instructions are 8-byte-tagged; a System or SPL Token instruction in the same transaction uses its own (4-byte or 1-byte) scheme. Dispatch encoding is per-program.
