# Solana Bytes

An interactive Solana account hex visualizer built with Ruby on Rails 8. Paste any account address and see its raw data as a color-coded hex dump with hover tooltips that explain what each byte range means.

Part of the [SolRengine](https://github.com/solrengine) project.

## Stack

- Ruby on Rails 8 (Hotwire, Turbo, Stimulus, Solid Queue/Cache/Cable)
- [SolRengine](https://github.com/solrengine/solrengine) — Rails framework for Solana dapps
- SQLite (cache + queue + cable)
- Tailwind CSS 4 + esbuild

## Features

- **Hex Visualization** — Account data rendered as an interactive hex dump with offset, hex, and ASCII columns
- **Region Decoding** — Color-coded byte ranges with decoded values for known account types
- **Hover Tooltips** — Hover any byte to see its field name, decoded value, offset, and binary representation
- **Block Highlighting** — Hovering a byte highlights the entire field it belongs to (e.g., all 32 bytes of a public key)
- **Network Selector** — Switch between mainnet, devnet, and testnet
- **SPA Navigation** — Turbo Frame-based navigation with loading spinner, no full page reloads
- **Matrix Rain** — Animated hex rain background on the landing page
- **Client-side Validation** — Base58 address validation before submitting
- **Touch Support** — Tap-to-toggle on mobile devices

## Supported Account Types

| Account Type | Owner | Fields Decoded |
|---|---|---|
| **SPL Token Mint** | Token Program | Mint authority, supply, decimals, freeze authority |
| **SPL Token Account** | Token Program | Mint, owner, amount, delegate, state, close authority |
| **Token-2022** | Token-2022 Program | Base fields + TLV extensions (metadata, transfer hook, etc.) |
| **BPF Upgradeable** | BPF Loader | Account type, programdata address |
| **ELF Programs** | BPF Loader v2 | ELF header (class, endianness, machine, entry point, sections) |
| **Unknown** | Any | Raw hex with per-byte tooltips |

### Token-2022 Extensions

MintCloseAuthority, PermanentDelegate, TransferFeeConfig, TransferHook, MetadataPointer, TokenMetadata (name, symbol, URI), DefaultAccountState, ConfidentialTransferMint, and more.

## Setup

```sh
bin/setup
cp .env.example .env
```

## Development

```sh
bin/dev
```

Starts 3 processes: web server, JS bundler, and CSS compiler.

Open `http://localhost:3000` and paste a Solana account address.

### Try These Accounts

| Address | What You'll See |
|---|---|
| `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` | USDC mint — authority, supply, 6 decimals |
| `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA` | Token Program — full ELF header with BPF machine type |
| `2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo` | PYUSD — Token-2022 with metadata, transfer hook, permanent delegate |

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `SOLANA_NETWORK` | `mainnet-beta` | Default network (`mainnet-beta`, `devnet`, `testnet`) |
| `SOLANA_RPC_MAINNET_URL` | public RPC | Mainnet HTTP RPC endpoint |
| `SOLANA_RPC_DEVNET_URL` | public RPC | Devnet HTTP RPC endpoint |
| `SOLANA_RPC_TESTNET_URL` | public RPC | Testnet HTTP RPC endpoint |

Copy `.env.example` to `.env` and fill in your RPC endpoints.

## Architecture

```
app/
├── controllers/
│   ├── accounts_controller.rb          # Fetch account via RPC, validate address
│   ├── networks_controller.rb          # Session-based network switching
│   └── pages_controller.rb             # Landing page
├── presenters/
│   └── account_presenter.rb            # Hex rows, regions, known program labels
│       ├── RegionDecoder                # Per-program byte range decoders
│       ├── HexRow / HexCell             # Structured hex output
│       └── Region                       # Named byte range with color + decoded value
└── javascript/controllers/
    ├── hex_viewer_controller.js         # Region hover/tap, tooltip positioning
    ├── hex_rain_controller.js           # Matrix-style canvas animation
    ├── loading_controller.js            # Turbo Frame SPA transitions + spinner
    ├── address_form_controller.js       # Client-side base58 validation
    └── auto_submit_controller.js        # Network dropdown auto-submit
```

## How It Works

1. User pastes a Solana address on the landing page
2. Client validates the address format (base58, 32-44 chars)
3. Form submits via Turbo Frame — URL updates, spinner shows
4. Server fetches account via `solrengine-rpc` (`getAccountInfo` with base64 encoding)
5. `AccountPresenter` decodes the response: metadata (balance, owner, executable) + raw data bytes
6. `RegionDecoder` identifies byte ranges based on the account owner program
7. Server renders a color-coded hex grid with data attributes for each cell
8. Stimulus `hex-viewer` controller handles hover/tap to highlight entire regions and show tooltips
