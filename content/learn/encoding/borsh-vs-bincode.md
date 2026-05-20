---
slug: borsh-vs-bincode
category: encoding
name: Borsh vs bincode
kind: concept
status: live
program_id: null
program_label: Encoding
size: null
summary: The two dominant binary serializations on Solana. Borsh (Anchor, SPL, most app programs) and bincode (native System/Stake/Vote programs) differ in enum tag width and a few conventions — enough to break a decoder that assumes the wrong one.
fields:
  - enum_tag
  - integers
  - collections
see_also:
  - coption-vs-option
  - system-instructions
  - account-discriminator
sources:
  - url: https://github.com/near/borsh
    label: Borsh specification
  - url: https://github.com/bincode-org/bincode
    label: bincode
last_verified: 2026-05-20
---

## What it is

Most binary data on Solana is serialized with one of two schemes: **Borsh** (used by Anchor, SPL Token, Metaplex, and the majority of app programs) or **bincode** (used by the native System, Stake, and Vote programs). They agree on a lot — little-endian integers, length-prefixed collections — but differ in ways that matter when you decode by hand.

## Why it exists

bincode came first and the native programs use it. Borsh ("Binary Object Representation Serializer for Hashing") was designed for blockchains: deterministic, canonical, and simple, so the same data always serializes to the same bytes (critical for hashing and signatures). New programs standardized on Borsh; the old native ones kept bincode.

## Byte layout

Where they agree and differ:

| Aspect | Borsh | bincode (as used by native programs) |
|--------|-------|--------------------------------------|
| Integers | little-endian, fixed width | little-endian, fixed width |
| `enum` tag | **1 byte** (`u8` variant index) | **4 bytes** (`u32` variant index) |
| `Option<T>` | 1-byte tag + value if Some | 1-byte tag + value if Some |
| `Vec<T>` / `String` | 4-byte LE length + elements | 8-byte LE length (bincode default) |
| structs | fields in declaration order, no padding | fields in order, no padding |
| bool | 1 byte (0/1) | 1 byte (0/1) |

The headline difference for instruction decoding is the **enum tag width**: a Borsh enum (e.g., an Anchor instruction, though Anchor actually uses an 8-byte hash discriminator) tags variants in 1 byte, while a native [System instruction](/learn/native/system-instructions) tags them in 4 bytes (`02 00 00 00` = Transfer).

## Where you see it

- Borsh: SPL Token state, [Metaplex metadata](/learn/metaplex/token-metadata), Anchor accounts and args.
- bincode: System/Stake/Vote instruction data and some native account state.

## Common gotchas

- **Enum tag width is the trap.** Decode a native instruction expecting a 1-byte tag and you'll misread the discriminator and every field after it. System/Stake/Vote use 4-byte tags; SPL Token uses a 1-byte tag (it's Borsh-ish but with `Pack`).
- **bincode's collection length is 8 bytes by default.** Borsh uses 4. If you're parsing native data with a Vec, don't assume a 4-byte length.
- **SPL Token isn't pure Borsh.** It uses a custom fixed-layout `Pack` trait with [COption](/learn/encoding/coption-vs-option) (4-byte tags) — neither textbook Borsh nor bincode. Treat each program's layout as documented, not assumed.
- **Anchor adds an 8-byte hash discriminator on top of Borsh.** An Anchor instruction isn't `[1-byte enum tag][args]` — it's `[8-byte sha256 tag][Borsh args]` (see [instruction discriminator](/learn/anchor/instruction-discriminator)).
