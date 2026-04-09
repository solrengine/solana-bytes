# CLAUDE.md

## Project Overview

Solana Bytes is an interactive Solana account hex visualizer + educational game with a full 8-bit pixel art aesthetic. Paste any account address to see decoded metadata and raw bytes with hover tooltips. Play the Byte Challenge to test your knowledge of Solana data structures — find specific fields in hex dumps, build streaks, compete on the leaderboard.

Built with Rails 8 and SolRengine for the Colosseum Frontier Hackathon.

## Key Commands

- `bin/dev` — start all processes (web, js, css)
- `yarn build` — bundle JS with esbuild
- `yarn build:css` — compile Tailwind CSS
- `bin/rails db:prepare` — set up all databases
- `bin/rails db:migrate` — run pending migrations
- `bin/rails test` — run all tests (29 tests)

## Environment Variables

Copy `.env.example` to `.env`:
- `SOLANA_NETWORK` — mainnet-beta (default), devnet, or testnet
- `SOLANA_RPC_MAINNET_URL` / `SOLANA_RPC_DEVNET_URL` / `SOLANA_RPC_TESTNET_URL` — RPC endpoints (falls back to public RPCs)
- `APP_DOMAIN` — domain for SIWS wallet auth (production)
- `SENTRY_DSN` — Sentry error tracking DSN (production only)

## Architecture

### Hex Visualizer
- **AccountsController** — fetches account via `solrengine-rpc`, validates base58, 3 retry attempts with 8s timeout
- **AccountPresenter** — structures RPC response into summary fields + hex rows, O(1) region lookup via offset map
- **RegionDecoder** (`app/presenters/region_decoder.rb`) — per-program decoders: BPF Upgradeable, BPF Loader (ELF), SPL Token, SPL Mint, Token-2022 extensions. Uses `base58` gem for address encoding.
- **Turbo Frame SPA** — results load inline via `account_result` frame, URL updates with `turbo_action: "advance"`

### Byte Challenge Game
- **ChallengesController** — loads random mainnet account (Mints + Token Accounts), picks random field as target. Uses signed challenge tokens (`MessageVerifier`) to prevent streak spoofing — streak, account, and target field are server-verified.
- **challenge_controller.js** (Stimulus) — streak mode with 3 lives, star rating, 8-bit sound effects, modal popups. Uses Stimulus outlets for cross-controller communication with hex-viewer.
- **ChallengeResult model** — persists streak, attempts, stars per game (requires wallet login). Validates ranges: stars 0-3, streak 0-200, attempts > 0, base58 address format.
- **LeaderboardController** — top streaks + recent games

### Wallet Auth
- **SolRengine Auth Engine** mounted at `/auth` — SIWS wallet authentication
- **User model** with `wallet_address` identity
- Guest play works (no save), logged-in play saves results to DB
- WalletController from `@solrengine/wallet-utils/controllers`

### Important: Engine Route Isolation
The SolRengine Auth Engine uses `isolate_namespace`. All views use **literal string paths** (`"/challenges"`, `"/auth/login"`) instead of route helpers because the engine can't access the host app's named routes. Do NOT change these to `_path` helpers — they will break on the auth login page.

## Key Files

### Hex Visualizer
- `app/controllers/accounts_controller.rb` — fetch, validate, retry, lookup redirect
- `app/presenters/account_presenter.rb` — hex rows, O(1) offset map, color constants, HexRow/HexCell structs
- `app/presenters/region_decoder.rb` — all per-program decoders, base58 encoding, binary read helpers
- `app/views/accounts/show.html.erb` — details page (Turbo Frame)
- `app/views/accounts/_hex_view.html.erb` — hex grid with per-cell data attributes
- `app/views/pages/home.html.erb` — landing with form, examples

### Byte Challenge
- `app/controllers/challenges_controller.rb` — random account + field selection, signed token generation/verification, result saving
- `app/controllers/leaderboard_controller.rb` — top streaks + recent games
- `app/javascript/controllers/challenge_controller.js` — game logic, sounds, modals, saves results (uses Stimulus outlets)
- `app/views/challenges/index.html.erb` — game landing (Practice/Connect & Play CTAs, mini leaderboard)
- `app/views/challenges/show.html.erb` — game board (gray hex grid, click to guess, modal popups)
- `app/views/leaderboard/index.html.erb` — leaderboard tables

### Security & Infrastructure
- `config/initializers/content_security_policy.rb` — CSP with nonce-based script-src
- `config/initializers/rack_attack.rb` — rate limiting (60 req/min general, 20/min RPC, 10/min save)
- `config/initializers/sentry.rb` — error tracking (production only, 10% trace sampling)

### Tests
- `test/presenters/region_decoder_test.rb` — 20 tests for all decoders, base58, edge cases
- `test/controllers/challenges_controller_test.rb` — 9 tests for token signing, model validations

### Pixel Art System
- `app/helpers/pixel_icon_helper.rb` — 14 inline SVG pixel sprites (heart, skull, fire, star, trophy, target, lock, medals, checkmark, cross, magnifier, play)
- `app/assets/stylesheets/application.tailwind.css` — pixel UI classes (pixel-btn, pixel-card, pixel-input, pixel-dialog, pixel-nav, pixel-tooltip)
- `app/javascript/controllers/hex_rain_controller.js` — pixel mosaic grid background (colorful squares with shimmer)

### Stimulus Controllers
- `hex_viewer_controller.js` — region hover/tap, tooltip positioning
- `hex_rain_controller.js` — pixel mosaic background animation
- `loading_controller.js` — SPA transitions for hex visualizer
- `address_form_controller.js` — client-side base58 validation
- `challenge_controller.js` — game logic, 8-bit sounds (Web Audio API), modal popups
- `auto_submit_controller.js` — network dropdown

### Layouts
- `app/views/layouts/application.html.erb` — main layout (nav, mosaic bg, footer)
- `app/views/layouts/game.html.erb` — challenge game layout (no footer, no network selector)

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
GET  /challenge           → challenges#show (play — accepts ?token=signed_token)
POST /challenge/result    → challenges#save_result (JSON — requires signed challenge_token)
GET  /leaderboard         → leaderboard#index
/auth/*                   → SolRengine Auth Engine (login, nonce, verify, logout)
```

## Game Mechanics

- Random mainnet account loaded (SPL Mints 82 bytes + Token Accounts 165 bytes)
- Account type label shown (e.g., "USDC Mint", "Jupiter USDC")
- All hex cells rendered in gray (no color hints)
- Hovering shows "?????" as field name + decoded value (educational but doesn't give away the answer)
- Player clicks cells to guess which bytes belong to the target field
- 3 wrong clicks = game over, streak ends
- Correct answer: reveals field in real color, streak +1, loads next challenge
- Stars: 0 wrong = 3 stars, 1 wrong = 2 stars, 2 wrong = 1 star
- 8-bit sound effects: start jingle, correct arpeggio, wrong buzz, game over melody
- Modal popups for correct (green) and game over (red), toast for wrong clicks
- Results saved to DB on game over if logged in via wallet

## Challenge Accounts (Mainnet)

### SPL Mints (82 bytes, 7-8 fields — easier)
- USDC Mint (EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v)
- USDT Mint (Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB)
- Wrapped SOL Mint (So11111111111111111111111111111111111111112)
- stSOL Mint (7dHbWXmci3dT8UFYWYZweBLXgycu7Y3iL6trKn1Y7ARj)

### Token Accounts (165 bytes, 11 fields — harder)
- Phantom wSOL (CfWX7o2TswwbxusJ4hCaPobu2jLCb1hfXuXJQjVq3jQF)
- Jupiter USDC (ALZv1FW3Bc5uRtci2UHnYS34DEWCmfkN5btEYDKms9yU)
- Binance USDC (9bZucpaB5cSFHD5DSTsvZftUqqP1KgC8SGQkVDu42BBe)
- Binance USDT (8hGBwecvELGSWQkfA64biQtzQKLoa8GoMKvWevCWwJbo)

## Visual Design — 8-Bit Pixel Art Theme

- **Font**: Press Start 2P (Google Fonts) — all text everywhere
- **Icons**: 14 inline SVG pixel sprites via `pixel_icon` helper — no emoji anywhere
- **UI**: Flat pixel borders, no rounded corners, no gradients. CSS classes: `pixel-btn`, `pixel-card`, `pixel-input`, `pixel-dialog`, `pixel-nav`
- **Buttons**: 3D pixel box-shadow (inset highlights/shadows), instant state changes (no CSS transitions)
- **Background**: Pixel mosaic grid (colorful squares, purple-weighted palette, subtle shimmer animation)
- **Favicon**: Pixel art "SB" SVG
- **Wallet icons**: Constrained to 24x24px with `image-rendering: pixelated` via CSS overrides

### Font Size Hierarchy
- Page titles: 20px
- Section headings: 14px
- Body/buttons/nav: 12px (base)
- Small text (addresses, metadata): 10px
- Hex grid cells: 11px
- Footer: 8px

## Conventions

- Follow Rails 8 conventions: Hotwire, Turbo + Stimulus
- Never use inline `<script>` tags — always Stimulus controllers
- 8-bit pixel art theme — Press Start 2P font, pixel icons, flat borders, no rounded corners
- Use `pixel_icon(:name, size:)` helper for icons — never emoji
- Hex cell colors use opaque backgrounds (pre-blended with dark base) — not transparent rgba
- Region colors defined in `REGION_COLORS` constant — use hex values, not Tailwind classes
- All views use literal string paths, NOT route helpers (engine isolation)
- Desktop-first — mobile not optimized
- NEVER modify: config/credentials, config/deploy.yml, .kamal/secrets, .env files
