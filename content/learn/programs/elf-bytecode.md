---
slug: elf-bytecode
category: programs
name: ELF Bytecode
kind: account
status: live
program_id: BPFLoader2111111111111111111111111111111111
program_label: BPF Loader
size: null
summary: The compiled program itself — a standard ELF shared object whose 64-byte header identifies it as a little-endian eBPF binary, followed by the program's code and data segments.
example_address: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
example_label: Token Program ELF
fields:
  - e_ident
  - e_type
  - e_machine
  - e_entry
  - e_phoff
  - e_shoff
see_also:
  - bpf-upgradeable-program
  - program-data
sources:
  - url: https://refspecs.linuxfoundation.org/elf/elf.pdf
    label: ELF specification (LSB)
last_verified: 2026-05-20
---

## What it is

A Solana program's actual code is a standard **ELF** (Executable and Linkable Format) shared object — the same container Linux uses — compiled to the eBPF instruction set (SBF, Solana's variant). Whether stored in a [ProgramData](/learn/programs/program-data) account (upgradeable) or directly at the program address (legacy loader), the bytes begin with the 64-byte ELF header.

## Why it exists

Rather than invent a bespoke binary format, Solana reuses ELF — mature tooling (linkers, `readelf`, objdump) works out of the box. Validators load the ELF, verify it, and JIT or interpret its eBPF instructions inside the SVM.

## Byte layout

The 64-byte ELF header (64-bit, little-endian) starts every program binary:

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| 0  | 4 | `EI_MAG` | bytes | Magic: `7F 45 4C 46` (`\x7F` `E` `L` `F`). |
| 4  | 1 | `EI_CLASS` | `u8` | `2` = ELFCLASS64 (64-bit). |
| 5  | 1 | `EI_DATA` | `u8` | `1` = little-endian. |
| 6  | 1 | `EI_VERSION` | `u8` | `1`. |
| 7  | 9 | `EI_OSABI` + pad | bytes | OS/ABI then padding to offset 16. |
| 16 | 2 | `e_type` | `u16` | `3` = ET_DYN (shared object). |
| 18 | 2 | `e_machine` | `u16` | `247` = eBPF. |
| 20 | 4 | `e_version` | `u32` | `1`. |
| 24 | 8 | `e_entry` | `u64` | Entry point virtual address. |
| 32 | 8 | `e_phoff` | `u64` | Program header table offset. |
| 40 | 8 | `e_shoff` | `u64` | Section header table offset. |
| 48 | 4 | `e_flags` | `u32` | |
| 52 | 2 | `e_ehsize` | `u16` | ELF header size (64). |
| 54 | 10 | `e_ph/sh entsize+num+shstrndx` | `u16`×5 | Program/section header sizes, counts, string-table index. |

After the header come the program headers, code/data sections, and relocations — the compiled program.

## Where you see it

The contents of a [ProgramData](/learn/programs/program-data) account (skip its ~45-byte header to reach the ELF), or the data of a program deployed with the legacy non-upgradeable loader. The magic `7F 45 4C 46` is the giveaway in a hex dump.

## Common gotchas

- **`e_machine = 247` is the BPF marker.** That's how you confirm a hex blob is a Solana program ELF and not some other ELF binary.
- **In upgradeable programs, the ELF is offset.** A [ProgramData](/learn/programs/program-data) account prefixes the ELF with its own ~45-byte state header. The `7F454C46` magic appears *after* that header, not at byte 0.
- **It's eBPF/SBF, not x86.** Disassembling requires an eBPF-aware tool; standard x86 objdump won't make sense of the instructions.
- **Verified at load, not at every call.** The runtime verifies the ELF (no illegal instructions, valid jumps) when the program is deployed/upgraded, then caches it — calls don't re-verify.
