---
slug: associated-token-account
category: addressing
name: Associated Token Account (ATA) Derivation
kind: concept
status: live
program_id: ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL
program_label: Associated Token Account Program
size: null
summary: The deterministic PDA that holds a given wallet's balance of a given token. Derived from [wallet, token_program, mint] under the ATA program, so any tool can compute it without an on-chain lookup.
fields:
  - wallet
  - token_program
  - mint
see_also:
  - token-account
  - pda-derivation
  - canonical-bumps
sources:
  - url: https://spl.solana.com/associated-token-account
    label: SPL Associated Token Account program
last_verified: 2026-05-20
---

## What it is

An Associated Token Account (ATA) is the canonical [Token Account](/learn/spl-token/token-account) for a given (wallet, mint) pair. Its address is a [PDA](/learn/addressing/pda-derivation) derived deterministically, so anyone can compute "where does wallet X hold token Y?" without querying the chain.

## Why it exists

A wallet could hold a token in any number of token accounts at arbitrary addresses — a discovery nightmare. The ATA standard says: for each (wallet, mint), there's *one* well-known address. Senders can compute the recipient's ATA, create it if missing, and deposit — no coordination required.

## Byte layout

The ATA is `find_program_address` of these seeds under the ATA program (`ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL`):

| Order | Seed | Bytes | Notes |
|------:|------|------:|-------|
| 1 | `wallet` | 32 | The owner's wallet pubkey. |
| 2 | `token_program_id` | 32 | `TokenkegQ…` for SPL Token, or the Token-2022 program id. |
| 3 | `mint` | 32 | The token's mint. |

```text
ata = find_program_address(
  [wallet, token_program_id, mint],
  ATA_PROGRAM_ID
)
```

The derived address is a normal 165-byte Token Account; only its *address* is special (deterministic), not its layout.

## Where you see it

Every wallet balance, every "send token" flow, every DEX route. When a transfer fails with "account does not exist," it usually means the recipient's ATA hasn't been created — the sender must include a create-ATA instruction first.

## Common gotchas

- **The token program id is a seed.** An SPL Token ATA and a Token-2022 ATA for the same wallet+mint derive to *different* addresses, because the token program id is part of the seeds. Use the correct program id for the mint.
- **It's a PDA, so it has no private key.** The wallet *owns* the ATA (via the Token Account's `owner` field), but the address itself is program-derived — you authorize transfers by signing as the wallet, not as the ATA.
- **Create-if-missing is idempotent with the right instruction.** `createAssociatedTokenAccountIdempotent` won't fail if the ATA already exists — prefer it to avoid races where two senders both try to create it.
- **Seeds use the wallet, not the wallet's other ATAs.** The derivation is always from the *wallet* pubkey, never chained off another token account.
