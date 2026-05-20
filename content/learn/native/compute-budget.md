---
slug: compute-budget
category: native
name: Compute Budget Instructions
kind: instruction
status: live
program_id: ComputeBudget111111111111111111111111111111
program_label: Compute Budget Program
size: null
summary: Instruction data for the Compute Budget Program — set the compute-unit limit and the per-CU priority fee. A 1-byte discriminator plus a small integer; the levers behind priority fees.
fields:
  - discriminator
  - SetComputeUnitLimit
  - SetComputeUnitPrice
  - RequestHeapFrame
see_also:
  - system-instructions
  - legacy-transaction
sources:
  - url: https://github.com/anza-xyz/agave/blob/master/sdk/compute-budget-interface/src/lib.rs
    label: ComputeBudgetInstruction (agave)
last_verified: 2026-05-20
---

## What it is

The Compute Budget Program doesn't move data — it configures the *resources* a transaction is allowed to consume and the priority fee it's willing to pay. Two instructions matter most: set the compute-unit limit and set the compute-unit price.

## Why it exists

Every transaction gets a default compute budget (200k CU × number of instructions, capped). Complex transactions need more, and during congestion you bid for inclusion by paying a priority fee per compute unit. These instructions are how a client declares "I need this much compute" and "I'll pay this much per unit."

## Byte layout

Compute Budget instruction data uses a **1-byte discriminator** followed by a small fixed-width integer:

| Discriminator (u8) | Variant | Payload | Total |
|----:|---------|---------|------:|
| `1` | `RequestHeapFrame`              | `bytes: u32` | 5 bytes |
| `2` | `SetComputeUnitLimit`           | `units: u32` | 5 bytes |
| `3` | `SetComputeUnitPrice`           | `micro_lamports: u64` | 9 bytes |
| `4` | `SetLoadedAccountsDataSizeLimit`| `bytes: u32` | 5 bytes |

`SetComputeUnitPrice`'s value is in **micro-lamports per compute unit** — the priority fee. Total priority fee = `compute_unit_limit × price / 1_000_000` lamports.

## Where you see it

Almost every modern transaction prepends one or two Compute Budget instructions. Wallets and aggregators add them automatically to set a realistic CU limit and a competitive priority fee during congestion.

## Common gotchas

- **1-byte discriminator, unlike System/Stake/Vote.** Compute Budget breaks from the 4-byte bincode convention — it's a 1-byte tag. Don't assume all native programs share an encoding.
- **Price is micro-lamports per CU, not lamports.** `SetComputeUnitPrice(1000)` is 1000 micro-lamports/CU = 0.001 lamports/CU. Multiply by the CU limit to get the total priority fee.
- **Setting a limit too low aborts the transaction.** If execution exceeds `SetComputeUnitLimit`, the transaction fails with "exceeded CUs" — but you still pay the base fee. Estimate via simulation first.
- **Only the first of each type counts.** Two `SetComputeUnitLimit` instructions in one transaction is an error; the runtime expects at most one of each.
