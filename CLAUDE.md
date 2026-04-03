# CLAUDE.md

## Project Overview

Solana Bytes is an interactive Solana account hex visualizer + educational game. Paste any account address to see decoded metadata and raw bytes with hover tooltips. Play the Byte Challenge to test your knowledge of Solana data structures — find specific fields in hex dumps, build streaks, compete on the leaderboard.

Built with Rails 8 and SolRengine for the Colosseum Frontier Hackathon.

## Key Commands

- `bin/dev` — start all processes (web, js, css)
- `yarn build` — bundle JS with esbuild
- `yarn build:css` — compile Tailwind CSS
- `bin/rails db:prepare` — set up all databases
- `bin/rails db:migrate` — run pending migrations

## Environment Variables

Copy `.env.example` to `.env`:
- `SOLANA_NETWORK` — mainnet-beta (default), devnet, or testnet
- `SOLANA_RPC_MAINNET_URL` / `SOLANA_RPC_DEVNET_URL` / `SOLANA_RPC_TESTNET_URL` — RPC endpoints (falls back to public RPCs)
- `APP_DOMAIN` — domain for SIWS wallet auth (production)

## Architecture

### Hex Visualizer
- **AccountsController** — fetches account via `solrengine-rpc`, validates base58, 3 retry attempts
- **AccountPresenter** — structures RPC response into summary fields + hex rows with regions (596 lines, all decoders)
- **RegionDecoder** — per-program decoders: BPF Upgradeable, BPF Loader (ELF), SPL Token, SPL Mint, Token-2022 extensions
- **Turbo Frame SPA** — results load inline via `account_result` frame, URL updates with `turbo_action: "advance"`

### Byte Challenge Game
- **ChallengesController** — loads random mainnet account, picks random field as target
- **challenge_controller.js** (Stimulus) — streak mode with 3 lives, timer, star rating, game over
- **ChallengeResult model** — persists streak, time, attempts, stars per game (requires wallet login)
- **LeaderboardController** — top streaks + recent games

### Wallet Auth
- **SolRengine Auth Engine** mounted at `/auth` — SIWS wallet authentication
- **User model** with `wallet_address` identity
- Guest play works (no save), logged-in play saves results to DB
- WalletController from `@solrengine/wallet-utils/controllers`

### Important: Engine Route Isolation
The SolRengine Auth Engine uses `isolate_namespace`. The layout (`application.html.erb`) uses **literal string paths** (`"/challenges"`, `"/auth/login"`) instead of route helpers because the engine can't access the host app's named routes. Do NOT change these to `_path` helpers — they will break on the auth login page.

## Key Files

### Hex Visualizer
- `app/controllers/accounts_controller.rb` — fetch, validate, retry, lookup redirect
- `app/presenters/account_presenter.rb` — hex rows, regions, color map, all decoders
- `app/views/accounts/show.html.erb` — details page (Turbo Frame)
- `app/views/accounts/_hex_view.html.erb` — hex grid with per-cell data attributes
- `app/views/pages/home.html.erb` — landing with form, examples, hex rain canvas

### Byte Challenge
- `app/controllers/challenges_controller.rb` — random account + field selection, result saving
- `app/controllers/leaderboard_controller.rb` — top streaks + recent games
- `app/javascript/controllers/challenge_controller.js` — streak mode, game over, result saving
- `app/views/challenges/index.html.erb` — game landing page
- `app/views/challenges/show.html.erb` — game board (gray hex grid, click to guess)
- `app/views/leaderboard/index.html.erb` — leaderboard tables

### Stimulus Controllers
- `hex_viewer_controller.js` — region hover/tap, tooltip positioning
- `hex_rain_controller.js` — Matrix canvas animation
- `loading_controller.js` — SPA transitions, spinner
- `address_form_controller.js` — client-side base58 validation
- `challenge_controller.js` — streak game logic, timer, saves results via fetch
- `auto_submit_controller.js` — network dropdown

## Models

- `User` — wallet_address (SolRengine auth), has_many challenge_results
- `ChallengeResult` — user_id, account_address, target_field, time_seconds, attempts, stars, streak

## Routes

```
GET  /                    → pages#home (hex visualizer landing)
POST /lookup              → accounts#lookup (redirect)
GET  /accounts/:address   → accounts#show (hex view)
PATCH /network            → networks#update (session network switch)
GET  /challenges          → challenges#index (game landing)
GET  /challenge           → challenges#show (play — accepts ?streak=N)
POST /challenge/result    → challenges#save_result (JSON — save game result)
GET  /leaderboard         → leaderboard#index
/auth/*                   → SolRengine Auth Engine (login, nonce, verify, logout)
```

## Game Mechanics

- Random mainnet account loaded, random meaningful field selected as target
- All hex cells rendered in gray (no color hints)
- Player clicks cells to guess which bytes belong to the target field
- 3 wrong clicks = game over, streak ends
- Correct answer: reveals field in real color, streak +1, loads next challenge
- Stars: 0 wrong = ⭐⭐⭐, 1 wrong = ⭐⭐, 2 wrong = ⭐
- Results saved to DB if logged in via wallet

## Challenge Accounts (Mainnet)

- USDC Mint (EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v)
- USDT Mint (Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB)
- Wrapped SOL Mint (So11111111111111111111111111111111111111112)
- PYUSD Token-2022 (2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo)
- stSOL Mint (7dHbWXmci3dT8UFYWYZweBLXgycu7Y3iL6trKn1Y7ARj)

## Conventions

- Follow Rails 8 conventions: Hotwire, Turbo + Stimulus
- Never use inline `<script>` tags — always Stimulus controllers
- Dark theme: `bg-gradient-to-br from-gray-950 via-gray-900 to-purple-950`
- Hex cell colors use opaque backgrounds (pre-blended with dark base) — not transparent rgba
- Monospace typography throughout details page
- Max 10KB data displayed per account (truncated with notice)
- Region colors defined in `REGION_COLORS` constant — use hex values, not Tailwind classes
- Layout uses literal string paths, NOT route helpers (engine isolation)
- NEVER modify: config/credentials, config/deploy.yml, .kamal/secrets, .env files
