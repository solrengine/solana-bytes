---
slug: coption-vs-option
category: encoding
name: COption vs Option vs OptionalNonZeroPubkey
kind: concept
status: live
program_id: null
program_label: Encoding
size: null
summary: Solana has three different ways to encode an optional value, and they're not interchangeable. SPL's COption is 4 bytes of tag, Borsh's Option is 1, and Token-2022's OptionalNonZeroPubkey is 0 — the single most common source of off-by-N decoder bugs.
fields:
  - coption_tag
  - borsh_option_tag
  - optional_non_zero
see_also:
  - mint
  - transfer-fee-config
  - borsh-vs-bincode
sources:
  - url: https://github.com/solana-program/token/blob/main/program/src/state.rs
    label: SPL Token COption usage
  - url: https://github.com/near/borsh
    label: Borsh specification
last_verified: 2026-05-20
---

## What it is

"This field is optional" is encoded three different ways on Solana depending on which serialization the program uses. Confusing them is the most common reason a hand-written decoder drifts off by a few bytes and reads garbage.

## Why it exists

Different layers adopted different conventions: SPL Token uses its own `Pack` format with a fixed-width tag for alignment, Borsh (Anchor, most app programs) uses a compact 1-byte tag, and Token-2022 extensions optimize pubkey-options to zero overhead. They all coexist, sometimes in the same account.

## Byte layout

| Encoding | Where | None | Some(value) | Total for `Option<Pubkey>` |
|----------|-------|------|-------------|---------------------------:|
| `COption<T>` (SPL `Pack`) | SPL Token base layout | 4-byte tag `00 00 00 00` + zeroed value space | 4-byte tag `01 00 00 00` + value | **36 bytes** (4 + 32) |
| `Option<T>` (Borsh) | Anchor, Metaplex, app programs | 1-byte tag `00` | 1-byte tag `01` + value | **33 bytes** (1 + 32) |
| `OptionalNonZeroPubkey` | Token-2022 extensions | 32 all-zero bytes | the 32-byte pubkey | **32 bytes** (no tag) |

The key differences:

- **COption reserves space for the value even when None.** SPL Token's `Mint.freeze_authority` is always 36 bytes on disk whether set or not — the layout is fixed-size.
- **Borsh Option omits the value when None.** A None is a single `00` byte; the value bytes aren't present at all. This makes Borsh structs variable-length.
- **OptionalNonZeroPubkey has no tag at all.** All-zero pubkey *is* the None sentinel. Zero overhead, but you can't represent "Some(all-zero pubkey)" — fine for pubkeys, which are never all-zero in practice.

## Where you see it

- COption: [Mint](/learn/spl-token/mint) and [Token Account](/learn/spl-token/token-account) authorities.
- Borsh Option: [Metaplex metadata](/learn/metaplex/token-metadata) fields, Anchor account fields.
- OptionalNonZeroPubkey: nearly every [Token-2022 extension](/learn/token-2022/transfer-fee-config) authority.

## Common gotchas

- **A Token-2022 mint can contain all three.** The base layout uses COption (4-byte tags), an embedded Borsh field could use Option (1-byte), and the extensions use OptionalNonZeroPubkey (0 tag). Decoding one section with the wrong convention slides everything after it.
- **COption is little-endian 4 bytes, value 0 or 1.** Don't read it as a single byte — bytes 1–3 being zero is what makes a naive 1-byte read accidentally work for None and then break for Some.
- **Borsh None changes the struct's size.** You can't compute a Borsh struct's byte size from its type alone if it has Options — the size depends on the values.
- **All-zero pubkey means None for OptionalNonZeroPubkey.** Never treat the system program (also all-1s in base58, but all-zero in bytes is the default Pubkey) — the all-zero 32 bytes is the None marker, not a real address.
