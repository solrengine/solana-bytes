---
slug: tlv-layout-primer
category: token-2022
name: TLV Layout Primer
kind: concept
status: live
program_id: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
program_label: Token-2022 Program
size: null
summary: How Token-2022 stores extensions on-chain — a 4-byte Type-Length-Value header followed by per-extension payload, walked left-to-right until a type-0 sentinel.
example_address: 2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo
example_label: PYUSD Mint (Token-2022)
fields:
  - extension_type
  - length
  - payload
see_also:
  - token-2022-base
  - transfer-fee-config
  - mint
sources:
  - url: https://github.com/solana-program/token-2022/blob/main/program/src/extension/mod.rs
    label: Token-2022 extension module (program/src/extension/mod.rs)
last_verified: 2026-05-19
---

## What it is

Token-2022 extends SPL Token without breaking its layout by appending **TLV** (Type-Length-Value) blocks after the base account. Every Token-2022 feature — transfer fees, interest, confidential transfers, metadata, transfer hooks, scaled UI amounts — is a TLV extension following the same 4-byte header convention.

A TLV entry is exactly 4 bytes of header plus a variable payload:

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 2 | `extension_type` | `u16` LE | Which extension this is (`1` TransferFeeConfig, `2` TransferFeeAmount, `3` MintCloseAuthority, `4` ConfidentialTransferMint, …). `0` means Uninitialized and signals the end of the list. |
| 2 | 2 | `length` | `u16` LE | Byte length of the payload that follows — **not** including the 4-byte header. |
| 4 | N | `payload` | varies | Extension-specific encoded data. |

## Why it exists

SPL Token's Mint is exactly 82 bytes and TokenAccount is exactly 165. You can't add fields without breaking every existing token on Solana. Token-2022 is a parallel program that keeps the base layouts byte-identical to SPL Token and tacks features on as TLV blocks past offset 165, so a decoder that doesn't know about a particular extension can still read the base balance and authority correctly.

## Byte layout of a Token-2022 account

Token-2022 accounts always look like this, whether they're a 166-byte bare Mint or a multi-kilobyte one with five extensions stacked:

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 82 or 165 | base | SPL Token base | Byte-identical to SPL Token Mint (82) or TokenAccount (165). |
| 82 | 83 | padding (Mints only) | zero bytes | Mints are padded out to 165 so the discriminator and TLV always sit at the same offsets regardless of base kind. |
| 165 | 1 | `account_type` | `u8` enum | `1` = Mint, `2` = TokenAccount. The only on-chain signal that distinguishes the two — you cannot tell from length alone. |
| 166 | varies | TLV entries | TLV[] | One entry per active extension, packed back-to-back. List ends with an entry whose `extension_type == 0`. |

This means a Token-2022 Mint with one extension has `82 (base) + 83 (padding) + 1 (discriminator) + 4 (TLV header) + N (payload)` bytes total. A bare Mint with no extensions is exactly 166 bytes; anything larger has extensions attached.

## Walking the TLV list

The reference walker is a tight loop — every Token-2022 explorer, indexer, and decoder does this:

```text
position = 166
while position + 4 <= data.length:
  extension_type = read_u16_le(data, position)
  if extension_type == 0:
    break                          # Uninitialized — end of list
  length = read_u16_le(data, position + 2)
  payload = data[position + 4 .. position + 4 + length]
  yield (extension_type, payload)
  position += 4 + length
```

That's the entire walker. The `+ 4 <= data.length` guard avoids reading the header off the end of a truncated buffer; production decoders also bounds-check `position + 4 + length` before slicing the payload.

## Where you see it

Anything owned by `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` with data length over 166 bytes has at least one extension. RPC `getMint` and `getTokenAccountBalance` parsed responses unpack this for you; raw `getAccountInfo` returns the bytes and you walk them yourself.

## Common gotchas

- **`extension_type == 0` is the sentinel, not the first slot.** A fresh extension area looks like one type-0 entry — that *is* the end-of-list marker. Don't try to walk past it.
- **`length` is the payload length, not the entry length.** Total entry size is `4 + length`. Forgetting the 4-byte header is the most common decoder bug here.
- **Mint vs TokenAccount disambiguation lives at offset 165.** Both base layouts share size 165 (after Mint padding) — only the `account_type` byte tells you which interpretation to apply to bytes 0–164.
- **Some extensions are kind-specific.** TransferFeeConfig is a Mint-side extension; TransferFeeAmount is the TokenAccount-side counterpart. The TLV format doesn't enforce kind compatibility — the program does. A naive decoder that reads any TLV against any base will produce nonsense for cross-kind entries.
- **Extensions don't use SPL's `COption` encoding internally.** Most use `OptionalNonZeroPubkey` (32 bytes, all-zeros = None, no tag) or plain Borsh `Option<T>`. See [TransferFeeConfig](/learn/token-2022/transfer-fee-config) for the gotcha in context.
