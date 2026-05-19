---
slug: bpf-upgradeable-program
category: programs
name: BPF Upgradeable Program
kind: account
status: draft
program_id: BPFLoaderUpgradeab1e11111111111111111111111
program_label: BPF Upgradeable Loader
size: 36
summary: A thin pointer from the program's address to its ProgramData account (which holds the actual ELF bytecode). Enables upgrades.
example_address: JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
example_label: Jupiter Aggregator
fields:
  - account_type
  - programdata_address
see_also:
  - elf-bytecode
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/program/src/bpf_loader_upgradeable.rs
    label: BPF Upgradeable Loader state
last_verified: 2026-05-19
---
