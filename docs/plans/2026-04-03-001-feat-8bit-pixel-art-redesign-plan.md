---
title: "feat: 8-Bit Pixel Art Visual Redesign"
type: feat
status: active
date: 2026-04-03
origin: docs/brainstorms/2026-04-03-pixel-art-redesign-brainstorm.md
---

# 8-Bit Pixel Art Visual Redesign

## Overview

Transform Solana Bytes from a clean modern dark theme into a full 8-bit retro arcade aesthetic. Every page gets pixel fonts (Press Start 2P), pixel SVG sprite icons replacing all emoji, and pixel-styled UI elements (flat borders, no rounded corners, RPG dialog boxes). Desktop-first for the Colosseum Frontier Hackathon.

(see brainstorm: docs/brainstorms/2026-04-03-pixel-art-redesign-brainstorm.md)

## Proposed Solution

### Approach: CSS Pixel Font + Inline SVG Sprites

All visual changes stay in code — no image pipeline, no PNG assets. Press Start 2P loaded via Google Fonts, pixel icons as inline SVG helpers, UI restyled with CSS.

**Rejected alternatives** (from brainstorm):
- Pixel accents only — user wants full transformation
- PNG sprite sheet — extra assets to manage
- Canvas UI rendering — too complex for hackathon

## Implementation Phases

### Phase 1: Font Foundation

**Goal:** Replace all fonts with Press Start 2P, adjust sizing across the app.

**Files to modify:**
- `app/views/layouts/application.html.erb` — add Google Fonts `<link>` for Press Start 2P
- `app/views/layouts/game.html.erb` — same font link
- `app/assets/stylesheets/application.tailwind.css` — set Press Start 2P as default font family, override Tailwind's `font-mono` to also use Press Start 2P

**Key considerations:**
- Press Start 2P renders ~2x larger than system fonts at same px size. Body text should be ~8-9px, headings ~12-16px, hex grid cells ~10px
- All `font-mono` Tailwind classes and inline `font-family: 'JetBrains Mono'` styles need updating
- Hex grid (`_hex_view.html.erb` and `challenges/show.html.erb`): increase `line-height` and cell padding to accommodate chunkier font. Current: `font-size:14px; line-height:2.0` — likely needs `font-size:10px; line-height:2.4` or similar
- The hex rain canvas (`hex_rain_controller.js` line 57) uses bare `monospace` — update to Press Start 2P

**Tasks:**
- [ ] Add Google Fonts `<link>` to both layouts (`application.html.erb`, `game.html.erb`)
- [ ] Configure Tailwind CSS to use Press Start 2P as default `font-family` for all text
- [ ] Override `font-mono` to use Press Start 2P (it's already monospaced)
- [ ] Remove all inline `font-family: 'JetBrains Mono'` references in `_hex_view.html.erb` and `challenges/show.html.erb`
- [ ] Adjust font sizes globally — body ~8px, headings ~12-16px
- [ ] Adjust hex grid cell sizing for readability with pixel font
- [ ] Update hex rain canvas font to Press Start 2P
- [ ] Test on all pages: home, account show, challenge index, challenge game, leaderboard, login

### Phase 2: Pixel SVG Sprite Icons

**Goal:** Replace all emoji with inline SVG pixel art sprites.

**Create a helper for reusable sprites:**
- `app/helpers/pixel_icon_helper.rb` — defines `pixel_icon(name, size: 16)` method returning inline SVG

**Sprites needed (14 icons):**
| Icon | Replaces | Used in |
|------|----------|---------|
| `heart` | ❤️ | `challenges/show.html.erb`, `challenge_controller.js` |
| `heart_empty` | 🖤 | `challenge_controller.js` |
| `skull` | 💀 | `challenge_controller.js` |
| `fire` | 🔥 | `challenges/index.html.erb`, `challenges/show.html.erb`, `challenge_controller.js`, `leaderboard/index.html.erb` |
| `star` | ⭐ | `challenges/index.html.erb`, `challenge_controller.js`, `leaderboard/index.html.erb` |
| `trophy` | 🏆 | `layouts/application.html.erb`, `layouts/game.html.erb`, `leaderboard/index.html.erb`, `challenges/index.html.erb` |
| `target` | 🎯 | `layouts/application.html.erb`, `layouts/game.html.erb`, `challenges/index.html.erb`, `challenges/show.html.erb` |
| `lock` | 🔐 | `solrengine/auth/sessions/new.html.erb` |
| `medal_gold` | 🥇 | `challenges/index.html.erb`, `leaderboard/index.html.erb` |
| `medal_silver` | 🥈 | `challenges/index.html.erb`, `leaderboard/index.html.erb` |
| `medal_bronze` | 🥉 | `challenges/index.html.erb`, `leaderboard/index.html.erb` |
| `checkmark` | ✅ | `challenge_controller.js` |
| `cross` | ❌ | `challenge_controller.js` |
| `magnifier` | 🔍 | `challenges/index.html.erb` |

**JS sprite challenge:** `challenge_controller.js` renders emoji in template literals (innerHTML). Options:
1. Define SVG strings as constants at top of controller
2. Use `data-*` attributes on the view to pass SVG markup
3. Create a small JS module exporting SVG strings

Recommend option 1 — SVG string constants in the controller. Simple, no extra files.

**Tasks:**
- [ ] Create `app/helpers/pixel_icon_helper.rb` with `pixel_icon(name, size:)` method
- [ ] Design and implement all 14 SVG pixel sprites (8x8 or 16x16 pixel grid)
- [ ] Replace all emoji in view templates with `<%= pixel_icon(:name) %>` calls
- [ ] Add SVG string constants to `challenge_controller.js` for icons used in JS
- [ ] Replace emoji in JS template literals with SVG constants
- [ ] Remove the 3 existing inline Heroicon SVGs (play button in `challenges/index.html.erb`, link icon in auth login)
- [ ] Verify all icons render at correct size and alignment across pages

### Phase 3: UI Element Restyling

**Goal:** Restyle buttons, cards, inputs, modals, and nav with pixel/8-bit aesthetic.

**Design language:**
- **No rounded corners** — remove all `rounded-xl`, `rounded-2xl`, `rounded-lg`. Use `rounded-none` or `rounded-sm` (2px max)
- **No gradients** — remove all `bg-gradient-to-r from-purple-600 to-blue-600`. Use flat solid colors
- **Pixel borders** — `border-2` or `border-3` solid borders. Consider `box-shadow` for inset/outset 3D pixel border effect:
  ```css
  /* 8-bit raised button */
  box-shadow: inset -2px -2px 0 #000, inset 2px 2px 0 #555;
  /* 8-bit pressed button */
  box-shadow: inset 2px 2px 0 #000, inset -2px -2px 0 #555;
  ```
- **Flat button colors** — primary: solid purple `bg-purple-600`, hover: lighter `bg-purple-500`. No transitions/duration-200 (instant state changes for retro feel)
- **Cards** — solid `border-2 border-gray-600` on dark bg. No `backdrop-blur`, no `/50` opacity borders
- **Modals** — RPG dialog box style: thick border, possibly double-line, dark solid background
- **Inputs** — flat `border-2 border-gray-600`, no focus ring animation, just color change on focus

**Files to modify:**
- `app/views/layouts/application.html.erb` — nav styling, body gradient (keep dark bg but simplify)
- `app/views/layouts/game.html.erb` — same nav changes
- `app/views/pages/home.html.erb` — hero section, form, example chips
- `app/views/accounts/show.html.erb` — details cards
- `app/views/accounts/_hex_view.html.erb` — hex grid table, legend, tooltip
- `app/views/accounts/error.html.erb` — error state
- `app/views/challenges/index.html.erb` — CTAs, stats, leaderboard card, how-to-play
- `app/views/challenges/show.html.erb` — game UI, prompt box, modal, toast
- `app/views/leaderboard/index.html.erb` — tables, cards
- `app/views/solrengine/auth/sessions/new.html.erb` — login card, button
- `app/assets/stylesheets/application.tailwind.css` — global overrides, wallet button styles

**Tasks:**
- [ ] Define pixel UI CSS classes in `application.tailwind.css` (pixel-btn, pixel-card, pixel-input, pixel-border)
- [ ] Restyle all buttons across all views — flat colors, pixel borders, no rounded corners
- [ ] Restyle all cards — solid borders, no backdrop-blur, no opacity borders
- [ ] Restyle inputs (address form, network select) — flat pixel borders
- [ ] Restyle modals (challenge correct/game over) — RPG dialog box borders
- [ ] Restyle wrong-click toast — pixel border
- [ ] Restyle nav — pixel border bottom, remove backdrop-blur
- [ ] Restyle flash/alert messages — pixel borders
- [ ] Restyle tooltip — pixel border, remove box-shadow blur
- [ ] Update the leaderboard tables — pixel-styled rows
- [ ] Update the wallet login card and button styles
- [ ] Remove all `transition-all duration-200`, `transition-colors` for instant retro state changes (keep only essential animations)

### Phase 4: Hex Rain Canvas + Branding

**Goal:** Pixelate the hex rain animation and create new branding assets.

**Hex rain (`hex_rain_controller.js`):**
- Update canvas font to Press Start 2P
- Add `image-rendering: pixelated` to the canvas element
- Consider rendering on a smaller canvas and scaling up for authentic pixel look
- Adjust character size and column spacing for the chunkier font

**Favicon:**
- Create a pixel art `0x` favicon as SVG (`public/icon.svg`)
- Generate PNG version (`public/icon.png`) — can use canvas-to-PNG or just create a simple 32x32 pixel art

**Logo in nav:**
- The `0x Solana Bytes` text in the nav naturally gets the pixel treatment via the font change (Phase 1)
- Consider adding a small pixel sprite next to it

**Tasks:**
- [ ] Update `hex_rain_controller.js` — pixel font, possibly chunked rendering
- [ ] Add `image-rendering: pixelated` to hex rain canvas element in both layouts
- [ ] Create pixel art favicon SVG (`public/icon.svg`)
- [ ] Create pixel art favicon PNG (`public/icon.png`)
- [ ] Test hex rain visual with new pixel font

## Color Palette

Keep the existing dark purple/gray base. The REGION_COLORS in `account_presenter.rb` stay unchanged (functional hex cell colors). UI chrome colors simplify to:

| Element | Current | Pixel |
|---------|---------|-------|
| Primary button | gradient purple→blue | solid `#7c3aed` (purple-600) |
| Button hover | lighter gradient | solid `#8b5cf6` (purple-500) |
| Card border | `border-gray-700/50` | solid `border-gray-600` |
| Card bg | `bg-gray-800/50` | solid `bg-gray-900` |
| Nav border | `border-gray-800/50` | solid `border-gray-700` |
| Focus ring | purple glow | solid `border-purple-500` |
| Success | green-900/30 bg | solid dark green border |
| Error | red-900/50 bg | solid dark red border |

## Acceptance Criteria

- [ ] Press Start 2P renders on all text across every page
- [ ] All 14 emoji replaced with pixel SVG sprites (no emoji visible anywhere)
- [ ] No `rounded-xl` or `rounded-2xl` remains in views — everything is square/minimal
- [ ] No gradient buttons — all flat solid colors
- [ ] Hex grid is readable with pixel font (cells sized appropriately)
- [ ] Hex rain canvas uses pixel font and has pixelated rendering
- [ ] Pixel favicon displays in browser tab
- [ ] Challenge game modals have RPG dialog box styling
- [ ] Wallet login page matches pixel theme
- [ ] Leaderboard tables have pixel styling
- [ ] No broken layouts on desktop (mobile not required)

## Dependencies & Risks

- **Google Fonts availability** — Press Start 2P is loaded via CDN. If offline, text falls back to system monospace. Low risk.
- **SVG sprite effort** — 14 pixel icons need designing. Each is small (8x8 grid = simple path data) but this is the most time-consuming phase. Mitigate by starting with the most visible icons (heart, fire, star, skull) and doing the rest incrementally.
- **Hex grid readability** — biggest visual risk. Press Start 2P in a dense 16-column hex table may need multiple sizing iterations. Test early (Phase 1).
- **JS emoji replacement** — `challenge_controller.js` builds HTML strings with emoji. Replacing with SVG strings makes the template literals longer but functionally identical.

## Sources & References

### Origin
- **Brainstorm document:** [docs/brainstorms/2026-04-03-pixel-art-redesign-brainstorm.md](docs/brainstorms/2026-04-03-pixel-art-redesign-brainstorm.md) — Key decisions: full 8-bit theme, Press Start 2P font, SVG sprites for all icons, desktop-first

### External References
- Press Start 2P font: https://fonts.google.com/specimen/Press+Start+2P
- Pixel art SVG techniques: SVGs built on 8x8 or 16x16 grids with `shape-rendering: crispEdges`
