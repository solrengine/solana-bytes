# CLAUDE.md

## Project Overview

Solana Bytes is the byte-level field guide to Solana accounts, with a full 8-bit pixel art aesthetic. Three pillars:

1. **Learn** (`/learn`) — a 52-page reference that decodes every common Solana account, instruction, and concept byte by byte. The flagship; content is file-based Markdown.
2. **Hex Visualizer** — paste any account address to see decoded metadata and raw bytes with hover tooltips.
3. **Byte Challenge** — a game: find a specific field in a hex dump, build streaks, compete on the leaderboard.

The entire site is **bilingual (English default + Spanish under `/es`)**. Built with Rails 8 and SolRengine; originally for the Colosseum Frontier Hackathon, now a live product at [bytes.solrengine.org](https://bytes.solrengine.org).

## Key Commands

- `bin/dev` — start all processes (web, js, css)
- `yarn build` — bundle JS with esbuild
- `yarn build:css` — compile Tailwind CSS
- `bin/rails db:prepare` — set up all databases
- `bin/rails db:migrate` — run pending migrations
- `bin/rails test` — run all tests (153 runs; 2 skips are expected — see Tests)

## Environment Variables

Copy `.env.example` to `.env`:
- `SOLANA_NETWORK` — mainnet-beta (default), devnet, or testnet
- `SOLANA_RPC_MAINNET_URL` / `SOLANA_RPC_DEVNET_URL` / `SOLANA_RPC_TESTNET_URL` — RPC endpoints (falls back to public RPCs)
- `APP_DOMAIN` — domain for SIWS wallet auth (production)
- `SENTRY_DSN` — Sentry error tracking DSN (production only)

## Architecture

### Learn Reference (the flagship)
- **Content** lives in `content/learn/<category>/<slug>.md` — Markdown body + YAML frontmatter (slug, category, name, kind, status, program_id, size, summary, example_address, fields, see_also, sources, last_verified). 52 base pages across 11 categories.
- **AccountTaxonomy** (`app/presenters/account_taxonomy.rb`) — loads/parses the Markdown files (memoized per locale), exposes `flat_entries`, `find_by_slug`, `find_by_category`, `categories`. The `Entry`/`Category` structs back the views. `reset!` clears the memo (tests/dev).
- **LearnController** — `index` (category-grouped directory), `category` (landing page OR 301 redirect for legacy `/learn/<slug>`), `show` (per-entry page with a cached live mainnet sample for `kind: account`).
- **Rendering** — `LearnHelper#render_learn_markdown` renders the body with **Kramdown** (GFM: tables, fenced code) and localizes in-body `/learn` links to the active locale. `category_name`/`category_description` resolve localized category labels.
- **Translations** — a sibling `content/learn/<category>/<slug>.<locale>.md` overlays ONLY `name`/`summary`/body. Structural frontmatter (offsets, sizes, program_id, fields, sources) stays canonical in the base file so byte facts can't drift between languages; missing overlay → English fallback.

### Internationalization (i18n)
- `config.i18n`: `available_locales [:en, :es]`, default `:en`, `fallbacks [:en]`. Strings in `config/locales/{en,es}.yml`.
- **Routing**: all host-app routes are wrapped in `scope "(:locale)"` (constraint `/en|es/`); the auth engine + health check stay outside. Bare path = English; `/es/...` = Spanish.
- **ApplicationController**: `around_action :switch_locale` sets `I18n.locale` from the URL; `default_url_options` keeps it sticky; `loc(path)`, `locale_switch_path`, `other_locale` are `helper_method`s.
- **`loc(path)` is required for in-app links** — because views use literal string paths (engine isolation), `loc()` is how a link stays in the active locale. Use `loc("/learn")`, not a bare `"/learn"`, for any in-app link that should preserve language.

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

### Learn Reference & i18n
- `content/learn/<category>/<slug>.md` — base reference pages (52); `<slug>.<locale>.md` — translation overlays
- `app/presenters/account_taxonomy.rb` — file loader, `Entry`/`Category` structs, `CATEGORIES` constant (11 ordered categories)
- `app/controllers/learn_controller.rb` — index / category / show + legacy-slug redirect
- `app/helpers/learn_helper.rb` — `render_learn_markdown` (Kramdown + link localization), `category_name`/`category_description`
- `app/views/learn/{index,category,show}.html.erb` — directory, category landing, per-entry page
- `config/locales/{en,es}.yml` — UI strings (nav, learn, home, about, challenge, leaderboard, stats, common)
- `docs/reference-roadmap.md` — page-by-page reference status (gitignored, local-only)

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

### Tests (153 runs; 2 expected skips)
- `test/presenters/region_decoder_test.rb` — decoders, base58, edge cases
- `test/presenters/account_taxonomy_test.rb` — file loader, frontmatter invariants, category ordering, `learn_path`, dynamic checks over every live entry
- `test/presenters/account_presenter_test.rb` — hex row construction + offset map
- `test/controllers/learn_controller_test.rb` — nested URLs, category landing, legacy 301s, kramdown tables, i18n (`/es` renders + English fallback + switcher)
- `test/controllers/challenges_controller_test.rb` — token signing, model validations, tier selection
- `test/controllers/pages_controller_test.rb` — landing + About rendering
- `test/controllers/accounts_controller_test.rb` — fetch/validate/retry
- The 2 skips: the draft-banner test (no drafts remain) and the es-fallback test (all pages translated). Both skip on purpose.

### Pixel Art System
- `app/helpers/pixel_icon_helper.rb` — 10 inline SVG pixel sprites (heart, fire, star, trophy, target, lock, medals, magnifier, play)
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

All app routes are nested under an optional `scope "(:locale)"` (so each also exists under `/es/...`). The auth engine + health check are outside the scope.

```
GET  /                          → pages#home (landing)
POST /lookup                    → accounts#lookup (redirect)
GET  /accounts/:address         → accounts#show (hex view)
PATCH /network                  → networks#update (session network switch)
GET  /learn                     → learn#index (reference directory)
GET  /learn/:category/:slug     → learn#show (canonical reference page)
GET  /learn/:slug               → learn#category (category landing OR 301 from legacy slug)
GET  /challenges                → challenges#index (game landing)
GET  /challenge                 → challenges#show (play — accepts ?token=signed_token)
POST /challenge/result          → challenges#save_result (JSON — requires signed challenge_token)
GET  /leaderboard               → leaderboard#index
GET  /stats                     → stats#show
GET  /about                     → pages#about
GET  /types                     → 301 redirect to /learn (legacy)
/auth/*                         → SolRengine Auth Engine (outside locale scope)
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

- **Font**: Press Start 2P (self-hosted via @fontsource/press-start-2p) — all text everywhere
- **Icons**: 10 inline SVG pixel sprites via `pixel_icon` helper — no emoji anywhere
- **UI**: Flat pixel borders, no rounded corners, no gradients on UI surfaces (buttons, cards, dialogs, badges). Canvas-background overlays may use radial gradients for atmospheric depth. CSS classes: `pixel-btn`, `pixel-card`, `pixel-input`, `pixel-dialog`, `pixel-nav`
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
- Hex cell `:bg` colors are opaque (pre-blended with dark base). Legend sidebar decoration may use rgba for subtle contrast.
- Region colors defined in `REGION_COLORS` constant — use hex values, not Tailwind classes
- All views use literal string paths, NOT route helpers (engine isolation) — wrap in-app links in `loc(...)` so they stay in the active locale
- User-facing strings go through i18n: `t("...")` in views, keys in `config/locales/{en,es}.yml`. New English value must match any existing rendered text so controller tests still pass.
- Learn content: add pages as `content/learn/<category>/<slug>.md`; translate via a `<slug>.<locale>.md` overlay carrying ONLY `name`/`summary`/body — never duplicate structural frontmatter (offsets/sizes/program_id) into the overlay
- Byte-level facts (offsets, field names, types) stay verbatim in both languages; field names are on-chain identifiers, not translatable
- Desktop-first — mobile not optimized
- NEVER modify: config/credentials, config/deploy.yml, .kamal/secrets, .env files
