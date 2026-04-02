# CLAUDE.md

## Project Overview

Solana Bytes is an educational Rails 8 app that visualizes Solana account data as interactive, color-coded hex dumps. Paste any account address and see the raw bytes with hover tooltips explaining what each section means. Built with SolRengine.

## Key Commands

- `bin/dev` — start all processes (web, js, css)
- `yarn build` — bundle JS with esbuild
- `yarn build:css` — compile Tailwind CSS
- `bin/rails db:prepare` — set up primary database
- `bin/rails db:schema:load:queue` — set up Solid Queue database
- `bin/rails db:schema:load:cache` — set up Solid Cache database
- `bin/rails db:schema:load:cable` — set up Solid Cable database

## Environment Variables

Copy `.env.example` to `.env` and fill in:
- `SOLANA_NETWORK` — mainnet-beta (default), devnet, or testnet
- `SOLANA_RPC_MAINNET_URL` — mainnet HTTP RPC endpoint
- `SOLANA_RPC_DEVNET_URL` — devnet HTTP RPC endpoint
- `SOLANA_RPC_TESTNET_URL` — testnet HTTP RPC endpoint

## Architecture

- **No database models** — purely reads account data from Solana RPC
- **AccountsController** — fetches account via `solrengine-rpc`, validates base58 address
- **AccountPresenter** — structures RPC response into summary fields + hex rows
- **Hex View** — server-rendered hex dump with Stimulus for hover tooltips
- **Network selector** — session-based, switches RPC endpoint

## Key Files

- `app/controllers/accounts_controller.rb` — main controller, fetches + validates
- `app/presenters/account_presenter.rb` — hex row generation, known program labels
- `app/views/accounts/show.html.erb` — summary panel + hex view
- `app/views/accounts/_hex_view.html.erb` — hex grid with data attributes for Stimulus
- `app/javascript/controllers/hex_viewer_controller.js` — hover/tap tooltips

## Conventions

- Follow Rails 8 conventions: Hotwire, Turbo + Stimulus
- Dark theme: `bg-gradient-to-br from-gray-950 via-gray-900 to-purple-950`
- Cards: `bg-gray-800/50 backdrop-blur border border-gray-700/50 rounded-2xl`
- No wallet auth needed — read-only app
- Max 10KB data displayed per account (truncated with notice)
