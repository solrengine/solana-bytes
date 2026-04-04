# Pixel Art Redesign Brainstorm

**Date:** 2026-04-03
**Status:** Ready for planning

## What We're Building

A full 8-bit retro arcade visual overhaul of Solana Bytes. Every page transforms from the current clean/modern dark theme into a chunky, NES-era pixel art aesthetic. This covers:

- **Pixel font** for all text (headings, body, UI elements)
- **Pixel SVG sprites** replacing all emoji icons (hearts, skull, fire, stars, trophy, target, lock, medals)
- **Pixel-styled UI elements** — borders, cards, buttons, inputs all get the 8-bit treatment
- **Hex rain canvas** updated to match the pixel aesthetic
- **Favicon and branding** refreshed with pixel art style

## Why This Approach

- **Distinctiveness**: At a hackathon, visual identity matters. An 8-bit Solana hex visualizer stands out immediately — nobody else will look like this.
- **Thematic fit**: "Bytes" + retro computing is a natural pairing. Hex dumps already feel low-level; pixel art reinforces that vibe.
- **CSS Font + SVG Sprites**: All in code, no image pipeline to manage. Inline SVGs scale perfectly, pixel fonts are free via Google Fonts. Fast to ship for hackathon deadline.

## Key Decisions

1. **Scope: Full pixel art theme** — every page, not just game pages. The whole app should feel like a retro game.
2. **Aesthetic: 8-bit retro arcade** — chunky pixels, NES/Game Boy era feel. Not refined 16-bit, not modern-pixel-with-gradients.
3. **Icons: Replace all emoji with pixel SVG sprites** — hearts, skull, fire, stars, trophy, target, lock, medals all become inline SVG pixel art.
4. **Implementation: CSS pixel font + inline SVG sprites** — no PNG assets, no canvas UI rendering. Everything stays in code.

## Scope Breakdown

### Font
- Add Press Start 2P or Silkscreen (Google Fonts) as the primary font
- Apply everywhere: headings, body text, buttons, inputs, monospace code
- May need size adjustments — pixel fonts read larger than system fonts at the same px size
- The hex grid might need a dedicated pixel monospace font for alignment

### Pixel Sprites (replacing emoji)
Icons needed:
- `heart` (life) and `heart-empty` (lost life) — replacing ❤️ and 🖤
- `skull` — replacing 💀 (game over)
- `fire` — replacing 🔥 (streak)
- `star` — replacing ⭐ (rating)
- `trophy` — replacing 🏆 (leaderboard)
- `target` — replacing 🎯 (challenge)
- `lock` — replacing 🔐 (connect wallet)
- `medal-gold`, `medal-silver`, `medal-bronze` — replacing 🥇🥈🥉
- `checkmark` — replacing ✅ (correct)
- `cross` — replacing ❌ (wrong)
- `magnifier` — replacing 🔍 (how to play)
- `play` button icon (replacing SVG)

All as inline SVGs with `image-rendering: pixelated` or built on a pixel grid.

### UI Elements
- **Buttons**: Flat pixel borders (2-3px solid), no gradients, no rounded corners (or minimal `rounded-sm`)
- **Cards**: Pixel-style borders, possibly double-line or inset/outset pixel borders
- **Inputs**: Flat pixel borders, blocky focus states
- **Modals**: Pixel border frame, possibly a "dialog box" look like an RPG text box
- **Nav**: Simplified, pixel-bordered
- **Loading/spinners**: Pixel animation or simple frame-based

### Color Palette
- Keep the dark purple/gray base but simplify to fewer, more saturated colors
- Consider a limited NES-inspired palette for UI chrome
- Hex region colors (REGION_COLORS) can stay as-is — they already work well and are functional

### Hex Rain Canvas
- Update to use blockier/chunkier characters
- Possibly pixelate the rendering with `image-rendering: pixelated` on the canvas

### Favicon/Branding
- New pixel art favicon
- "0x Solana Bytes" logo in pixel style

## Resolved Questions

1. **Hex grid readability**: Use Press Start 2P in the hex grid too, but increase cell size/spacing to keep it readable. Full consistency over compromise.
2. **Specific pixel font**: Press Start 2P — the iconic chunky 8-bit font. Most recognizable retro feel.

## Resolved Questions (cont.)

3. **Mobile responsiveness**: Desktop-first for the hackathon. Skip mobile optimization — Press Start 2P works great at desktop sizes.

## Rejected Alternatives

- **Pixel accents only**: User wants the full transformation, not a half-measure.
- **Game pages only**: The whole app should be cohesive.
- **PNG sprite sheet**: Extra assets to manage; SVG keeps everything in code.
- **Canvas UI rendering**: Way too complex for a hackathon, accessibility issues.
