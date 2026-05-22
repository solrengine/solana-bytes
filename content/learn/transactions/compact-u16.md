---
slug: compact-u16
category: transactions
name: compact-u16 (shortvec)
kind: concept
status: live
program_id: null
program_label: Transaction encoding
size: null
summary: The 1-to-3-byte variable-length integer that prefixes every array in a Solana transaction. Seven value bits per byte plus a continuation flag — the source of most off-by-one transaction-parsing bugs.
fields:
  - value_bits
  - continuation_flag
see_also:
  - legacy-transaction
  - address-lookup-table
sources:
  - url: https://docs.solana.com/developing/programming-model/transactions#compact-u16-format
    label: Solana docs — compact-u16 format
  - url: https://github.com/anza-xyz/agave/blob/master/short-vec/src/lib.rs
    label: short-vec implementation (agave short-vec)
last_verified: 2026-05-20
---

## What it is

`compact-u16` (also called *shortvec*) is a variable-length encoding for the length prefix of every array inside a Solana transaction — the signature count, account-key count, instruction count, and the per-instruction account and data lengths. It encodes a value from 0 to 65,535 in **1 to 3 bytes**.

## Why it exists

Transactions are size-constrained (1,232 bytes on the wire), so spending a fixed 2 or 4 bytes on every array length is wasteful when most arrays are short. compact-u16 spends a single byte for lengths under 128 — which covers the overwhelming majority of real transactions — and only grows when it has to.

## Byte layout

Each byte carries 7 bits of value in its low bits; the high bit (`0x80`) is a continuation flag meaning "another byte follows."

| Bytes used | Value range | Encoding |
|-----------:|-------------|----------|
| 1 | 0 – 127        | `0vvvvvvv` — high bit clear, value in low 7 bits. |
| 2 | 128 – 16,383   | `1vvvvvvv 0vvvvvvv` — first byte's high bit set; next 7 bits in the second byte. |
| 3 | 16,384 – 65,535 | `1vvvvvvv 1vvvvvvv 000000vv` — third byte uses only its low 2 bits. |

Decoding accumulates 7 bits at a time, shifting left by 7 for each subsequent byte, stopping at the first byte whose high bit is clear.

```text
value = 0
shift = 0
loop:
  byte = next_byte()
  value |= (byte & 0x7F) << shift
  if (byte & 0x80) == 0: break
  shift += 7
```

## Where you see it

Before *every* array in a [legacy transaction](/learn/transactions/legacy-transaction) and v0 transaction: the signatures vector, the account-keys vector, the instructions vector, each instruction's account-index vector and data vector, and (in v0) the address-table-lookup vectors. If you're hand-parsing a transaction and your offsets drift, a misread compact-u16 is the usual culprit.

## Common gotchas

- **It is not LEB128, and not little-endian u16.** compact-u16 is its own format. Decoding it as a plain 2-byte little-endian integer works *by accident* for values 0–127 (one byte) and then silently breaks. Use a real shortvec decoder.
- **The third byte only has 2 usable value bits.** Because the max value is u16 (65,535), the third byte tops out at `0b00000011` in its low bits. Encoders must reject anything larger.
- **Length, then elements.** The prefix is the element *count*, not a byte length. To skip an array you must decode the count and then walk each element (whose size you know from context) — you can't just jump N bytes.
- **Non-canonical encodings are invalid.** Encoding `5` as two bytes (`0x85 0x00`) instead of one (`0x05`) is malformed; strict decoders reject it. Don't pad.
