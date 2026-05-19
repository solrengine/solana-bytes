---
slug: elf-bytecode
category: programs
name: ELF Bytecode
kind: account
status: draft
program_id: BPFLoader2111111111111111111111111111111111
program_label: BPF Loader
size: null
summary: The raw ELF shared object — header (magic, class, endian, entry, section offsets) followed by the compiled BPF program.
example_address: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
example_label: Token Program ELF
fields:
  - elf_magic
  - elf_class
  - elf_endian
  - elf_osabi
  - e_type
  - e_machine
  - e_entry
  - e_phoff
  - e_shoff
see_also:
  - bpf-upgradeable-program
sources:
  - url: https://refspecs.linuxfoundation.org/elf/elf.pdf
    label: ELF specification (LSB)
last_verified: 2026-05-19
---
