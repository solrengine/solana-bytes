---
slug: bpf-upgradeable-program
category: programs
name: BPF Upgradeable Program
kind: account
status: live
program_id: BPFLoaderUpgradeab1e11111111111111111111111
program_label: BPF Upgradeable Loader
size: 36
summary: A thin 36-byte pointer from a program's public address to its ProgramData account, which holds the actual ELF bytecode. The indirection is what lets a program be upgraded while keeping its address.
example_address: JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
example_label: Jupiter Aggregator
fields:
  - state_discriminator
  - programdata_address
see_also:
  - program-data
  - elf-bytecode
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/bpf_loader_upgradeable.rs
    label: UpgradeableLoaderState (agave bpf_loader_upgradeable)
last_verified: 2026-05-20
---

## What it is

When you invoke a program at an address like Jupiter's `JUP6Lkb…`, that account is tiny — just 36 bytes. It doesn't contain the bytecode; it's a `Program` state pointing at a separate [ProgramData](/learn/programs/program-data) account that holds the actual ELF. This indirection is what makes upgrades possible.

## Why it exists

If a program's bytecode lived directly at its public address, upgrading would change the address and break every integration. The BPF Upgradeable Loader splits it: a stable, tiny `Program` account at the public address, and a separate `ProgramData` account that can be rewritten on upgrade. The address you call never changes; the code behind it can.

## Byte layout

The account holds the `Program` variant of `UpgradeableLoaderState`, bincode-encoded:

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0 | 4 | `state_discriminator` | `u32` LE | `2` = Program (the enum variant: `0` Uninitialized, `1` Buffer, `2` Program, `3` ProgramData). |
| 4 | 32 | `programdata_address` | `Pubkey` | Address of the [ProgramData](/learn/programs/program-data) account holding the ELF + upgrade authority. |

Total: **36 bytes**.

## Where you see it

Every upgradeable program's main address: Jupiter, Drift, Kamino, Anchor programs deployed normally. When you look up a program account and it's exactly 36 bytes owned by the BPF Upgradeable Loader, this is it — follow `programdata_address` to find the code.

## Common gotchas

- **The program account doesn't hold code.** Decoding it gives you a pointer, not bytecode. The 4 GB of ELF you might expect lives in the [ProgramData](/learn/programs/program-data) account it references.
- **4-byte bincode discriminator.** Like other native-loader state, the variant tag is a 4-byte `u32`, not a 1-byte tag.
- **Non-upgradeable programs look different.** Programs deployed with the older non-upgradeable BPF Loader (`BPFLoader2…`) store the [ELF](/learn/programs/elf-bytecode) directly at the program address — no ProgramData indirection. The owner program id tells you which loader.
- **Closing/upgrading is gated by the ProgramData authority**, not anything in this 36-byte account. The upgrade authority lives in ProgramData.
