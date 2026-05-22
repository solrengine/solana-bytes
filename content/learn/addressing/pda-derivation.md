---
slug: pda-derivation
category: addressing
name: PDA Derivation
kind: concept
status: live
program_id: null
program_label: Addressing
size: null
summary: How a Program Derived Address is computed — SHA-256 over seeds, a bump byte, the program id, and a marker string, with the result forced off the ed25519 curve so no private key can exist for it.
fields:
  - seeds
  - bump
  - program_id
  - pda_marker
see_also:
  - canonical-bumps
  - associated-token-account
  - account-discriminator
sources:
  - url: https://solana.com/docs/core/pda
    label: Solana docs — Program Derived Addresses
last_verified: 2026-05-20
---

## What it is

A Program Derived Address (PDA) is an account address a program controls without holding a private key. It's deterministically derived from a set of **seeds** plus the program id, and deliberately chosen to fall *off* the ed25519 curve — so no keypair could ever sign for it. Instead, the owning program signs on its behalf via `invoke_signed`.

## Why it exists

Programs need accounts they fully control: a per-user vault, a config singleton, a market's state. If those used normal keypairs, someone would have to hold the private key. PDAs let a program own and sign for accounts using only on-chain logic — the foundation of nearly every Solana program's account model.

## Byte layout

`create_program_address` hashes a preimage and checks the result is off-curve:

| Order | Component | Bytes | Notes |
|------:|-----------|-------|-------|
| 1 | `seeds` | variable | Each seed concatenated, in order (e.g. `b"vault"`, a `Pubkey`, a `u64`). |
| 2 | `bump` | 1 | A single byte appended as the last seed (added by `find_program_address`). |
| 3 | `program_id` | 32 | The owning program's address. |
| 4 | `"ProgramDerivedAddress"` | 21 | A fixed ASCII marker domain-separating PDAs from real keys. |

```text
hash = sha256(seed_0 || seed_1 || … || [bump] || program_id || "ProgramDerivedAddress")
if hash is a valid ed25519 point: reject (try a smaller bump)
else: hash is the PDA
```

About half of candidate hashes land on the curve and are rejected; `find_program_address` decrements the bump until it finds an off-curve result (see [canonical bumps](/learn/addressing/canonical-bumps)).

## Where you see it

Every program-owned account: vaults, escrows, config singletons, order books, and [Associated Token Accounts](/learn/addressing/associated-token-account). Any time you see an address derived from `findProgramAddressSync(seeds, programId)`, that's a PDA.

## Common gotchas

- **Each seed is capped at 32 bytes, max 16 seeds.** Long seeds (like a full string) must be hashed down or split. The runtime enforces these limits.
- **Seed order is part of the identity.** `[user, mint]` and `[mint, user]` derive different PDAs. Document and fix your seed order.
- **PDAs have no private key by construction.** You can't "sign" with a PDA externally — only the owning program can authorize actions via `invoke_signed`, passing the seeds + bump.
- **The bump is part of what's hashed.** Two different bumps give two different addresses from the same seeds. This is why canonical-bump discipline matters for security.
