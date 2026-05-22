---
slug: canonical-bumps
category: addressing
name: Canonical Bumps
kind: concept
status: live
program_id: null
program_label: Addressing
size: 1
summary: The bump is the single byte that nudges a PDA off the ed25519 curve. The canonical bump is the first one found counting down from 255 — and using anything else is a security bug.
fields:
  - bump
see_also:
  - pda-derivation
  - associated-token-account
sources:
  - url: https://solana.com/docs/core/pda#canonical-bump
    label: Solana docs — canonical bump
last_verified: 2026-05-20
---

## What it is

When deriving a [PDA](/learn/addressing/pda-derivation), roughly half of candidate hashes land *on* the ed25519 curve (and so are invalid PDAs). The **bump** is a one-byte seed appended to nudge the hash until it lands off the curve. The **canonical bump** is the first valid one found when counting down from 255.

## Why it exists

For any seed set there are usually several bump values that produce a valid off-curve address. If a program accepted *any* of them, an attacker could supply a non-canonical bump to derive a *different* valid PDA for the same logical seeds — bypassing a uniqueness assumption. Standardizing on the canonical (highest) bump makes each seed set map to exactly one address.

## Byte layout

| Offset | Length | Field | Type | Notes |
|-------:|-------:|-------|------|-------|
| (last seed) | 1 | `bump` | `u8` | Appended after the user seeds, before the program id, in the PDA hash preimage. |

`find_program_address` runs:

```text
for bump in 255, 254, 253, … 0:
  candidate = create_program_address(seeds + [bump], program_id)
  if candidate is off-curve: return (candidate, bump)   # canonical = first hit
```

The returned bump is the canonical one. Programs store it (often in the account itself) so they don't repeat the search on every call.

## Where you see it

Every PDA-using program. Anchor's `#[account(seeds = …, bump)]` finds and enforces the canonical bump for you; raw programs call `find_program_address` and then pass the bump to `invoke_signed`.

## Common gotchas

- **Always validate the canonical bump.** If your program accepts a caller-supplied bump without checking it's canonical, an attacker can derive an alternate valid PDA. Anchor's `bump` constraint (no value) re-derives and enforces canonical; `bump = some_stored_bump` trusts a value you must have validated on init.
- **`find_program_address` is expensive; `create_program_address` is cheap.** Searching for the bump costs compute. Programs find it once (at init), store the bump, and thereafter use `create_program_address` with the stored bump.
- **Highest-first, not lowest.** Canonical = the first off-curve hit counting *down* from 255, so canonical bumps are usually 255, 254, etc. A bump of, say, 251 means 255–252 all landed on-curve.
