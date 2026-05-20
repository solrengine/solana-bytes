---
slug: buffer
category: programs
name: Buffer Account
kind: concept
status: live
program_id: BPFLoaderUpgradeab1e11111111111111111111111
program_label: BPF Upgradeable Loader
size: null
summary: A temporary staging account that holds an program's ELF during deployment or before an upgrade. Once written and verified, its contents are copied into the ProgramData account and the buffer is closed.
fields:
  - state_discriminator
  - authority
  - elf
see_also:
  - program-data
  - bpf-upgradeable-program
  - elf-bytecode
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/bpf_loader_upgradeable.rs
    label: UpgradeableLoaderState::Buffer (agave)
last_verified: 2026-05-20
---

## What it is

A Buffer account is scratch space for deploying or upgrading a program. ELF bytes are written into a buffer across many transactions (a program is far larger than one transaction can carry), and only once the full ELF is staged and verified does a single Deploy or Upgrade instruction copy it into the [ProgramData](/learn/programs/program-data) account.

## Why it exists

A Solana program's ELF is often hundreds of kilobytes — it can't fit in one transaction's 1,232-byte limit. Buffers let you upload the code in chunks (`Write` instructions) into a staging account, then atomically promote it. It also enables governance flows: stage an upgrade in a buffer, then have a multisig or DAO authorize the final swap.

## Byte layout

The account holds the `Buffer` variant of `UpgradeableLoaderState` (bincode), then the partial-or-complete ELF:

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 4  | `state_discriminator` | `u32` LE | `1` = Buffer. |
| 4  | 1  | `authority` tag | `u8` (Borsh Option) | `0` None, `1` Some. |
| 5  | 32 | `authority` | `Pubkey` | Present when tag is `1`. May write to and deploy from the buffer. |
| 37 | …  | `elf` | bytes | The (possibly partial) [ELF](/learn/programs/elf-bytecode) being staged. |

The header is **37 bytes** (4 + 1 + 32) when an authority is set; the staged ELF follows.

## Where you see it

During `solana program deploy` and `solana program write-buffer`. Buffers are transient — they exist between the first `Write` and the final `Deploy`/`Upgrade`, then are closed to reclaim rent. You'll occasionally find abandoned buffers from failed deploys still holding rent.

## Common gotchas

- **ELF starts at offset 37 here, 45 in ProgramData.** The two state variants have different header sizes (Buffer has no `slot` field). Don't reuse the ProgramData offset to parse a Buffer.
- **Abandoned buffers strand rent.** A deploy that fails midway leaves a funded buffer. `solana program close --buffers` reclaims them; check for orphaned buffers if SOL goes missing during deploys.
- **The buffer authority controls the deploy.** Only the buffer's `authority` can finalize a deploy/upgrade from it — relevant for multisig-gated upgrade flows where the buffer is staged by one party and promoted by another.
- **Discriminator `1`, not `3`.** Buffer is variant 1; ProgramData is 3. The 4-byte tag at offset 0 tells you which you're looking at.
