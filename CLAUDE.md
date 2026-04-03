# CLAUDE.md

## Project Overview

Solana Bytes is an educational Rails 8 app that visualizes Solana account data as interactive, color-coded hex dumps. Paste any account address to see decoded metadata and raw bytes with hover tooltips. Built with SolRengine. Read-only — no wallet auth, no database models.

## Key Commands

- `bin/dev` — start all processes (web, js, css)
- `yarn build` — bundle JS with esbuild
- `yarn build:css` — compile Tailwind CSS
- `bin/rails db:prepare` — set up databases (cache, queue, cable only)

## Environment Variables

Copy `.env.example` to `.env`:
- `SOLANA_NETWORK` — mainnet-beta (default), devnet, or testnet
- `SOLANA_RPC_MAINNET_URL` / `SOLANA_RPC_DEVNET_URL` / `SOLANA_RPC_TESTNET_URL` — RPC endpoints (falls back to public RPCs)

## Architecture

- **AccountsController** — fetches account via `solrengine-rpc`, validates base58, handles errors
- **AccountPresenter** — structures RPC response into summary fields + hex rows with regions
- **RegionDecoder** — per-program decoders: BPF Upgradeable, BPF Loader (ELF), SPL Token, SPL Mint, Token-2022 extensions
- **Turbo Frame SPA** — results load inline via `account_result` frame, URL updates with `turbo_action: "advance"`
- **Network selector** — session-based, auto-submits via Stimulus

## Key Files

- `app/controllers/accounts_controller.rb` — fetch, validate, lookup redirect
- `app/presenters/account_presenter.rb` — hex rows, regions, color map, all decoders
- `app/views/accounts/show.html.erb` — details page (Turbo Frame wrapped)
- `app/views/accounts/_hex_view.html.erb` — hex grid with per-cell data attributes
- `app/views/pages/home.html.erb` — landing with form, examples, hex rain canvas
- `app/javascript/controllers/hex_viewer_controller.js` — region hover/tap, tooltip (moved to body)
- `app/javascript/controllers/hex_rain_controller.js` — Matrix canvas animation
- `app/javascript/controllers/loading_controller.js` — SPA transitions, spinner, hero restore
- `app/javascript/controllers/address_form_controller.js` — client-side base58 validation

## Conventions

- Follow Rails 8 conventions: Hotwire, Turbo + Stimulus
- Never use inline `<script>` tags — always Stimulus controllers
- Dark theme: `bg-gradient-to-br from-gray-950 via-gray-900 to-purple-950`
- Hex cell colors use opaque backgrounds (pre-blended with dark base) — not transparent rgba
- Monospace typography throughout details page
- Max 10KB data displayed per account (truncated with notice)
- Region colors defined in `REGION_COLORS` constant — use hex values, not Tailwind classes
