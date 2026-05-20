---
slug: program-data
category: programs
name: ProgramData Account
kind: concept
status: live
program_id: BPFLoaderUpgradeab1e11111111111111111111111
program_label: BPF Upgradeable Loader
size: null
summary: The account that actually holds an upgradeable program's ELF bytecode, plus the slot it was last deployed at and the upgrade authority. Referenced by the tiny Program account at the program's public address.
fields:
  - state_discriminator
  - slot
  - upgrade_authority
  - elf
see_also:
  - bpf-upgradeable-program
  - elf-bytecode
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/bpf_loader_upgradeable.rs
    label: UpgradeableLoaderState::ProgramData (agave)
last_verified: 2026-05-20
---

## What it is

The ProgramData account is where an upgradeable program's actual code lives. The [Program account](/learn/programs/bpf-upgradeable-program) at the public address is a 36-byte pointer; it points here, to a much larger account holding a ~45-byte state header followed by the program's [ELF](/learn/programs/elf-bytecode) bytecode.

## Why it exists

Splitting "the address you call" (Program account) from "the code and who can change it" (ProgramData) is what enables upgrades without changing the program's public address. ProgramData carries the upgrade authority and the deployment slot, and gets rewritten on each upgrade.

## Byte layout

The account holds the `ProgramData` variant of `UpgradeableLoaderState` (bincode), then the raw ELF:

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 4  | `state_discriminator` | `u32` LE | `3` = ProgramData. |
| 4  | 8  | `slot` | `u64` LE | The slot at which the program was last deployed or upgraded. |
| 12 | 1  | `upgrade_authority` tag | `u8` (Borsh Option) | `0` None (immutable — frozen forever), `1` Some. |
| 13 | 32 | `upgrade_authority` | `Pubkey` | Present when the tag is `1`. May authorize upgrades. |
| 45 | …  | `elf` | bytes | The [ELF](/learn/programs/elf-bytecode) shared object. Magic `7F 45 4C 46` begins here. |

The header is **45 bytes** (4 + 8 + 1 + 32) when an upgrade authority is set; the ELF follows immediately.

## Where you see it

Behind every upgradeable program. Take a program's address, read its [Program account](/learn/programs/bpf-upgradeable-program) `programdata_address`, fetch that account — this is what you get. It's usually the largest account associated with a program.

## Common gotchas

- **The ELF starts at offset 45, not 0.** Tools that scan for the `7F454C46` magic must skip the state header. Reading byte 0 as ELF magic fails — byte 0 is the discriminator `03`.
- **`upgrade_authority = None` means immutable.** Setting the authority to None (a one-way action) makes the program permanently un-upgradeable — a common trust signal that "this code can never change."
- **`slot` is the last-upgrade slot, not creation.** It updates on every redeploy. Useful for "when did this program last change?"
- **The account is sized for the largest ELF ever deployed.** Upgrading to a smaller program doesn't shrink the account; the extra space stays allocated (and rent-paid).
