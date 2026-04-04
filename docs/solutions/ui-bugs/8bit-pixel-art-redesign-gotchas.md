---
title: "8-Bit Pixel Art Redesign — Lessons and Gotchas"
category: ui-bugs
date: 2026-04-04
tags: [pixel-art, press-start-2p, font-sizing, svg-icons, canvas, z-index, turbo, web-audio]
---

## Problem

Full visual redesign of a Rails 8 app from modern dark theme to 8-bit pixel art. Multiple issues encountered across font rendering, icon sizing, z-index stacking, Turbo caching, and canvas animation.

## Key Issues & Solutions

### 1. Font size cascade with sed

**Problem**: Using `sed` to scale up font sizes caused cascading replacements (8→12→16→20→24) when multiple rules ran sequentially on the same file.

**Root cause**: sed applies rules in order — a value changed by rule 1 gets matched by rule 2.

**Solution**: Either use single-pass replacements with unique values, or do targeted edits per file with exact size mappings. We ended up fixing manually with the Edit tool.

**Prevention**: Never use cascading sed for font size changes. Map each size explicitly or use a script that replaces all in one pass with unique markers.

### 2. Wallet icons rendering at arbitrary sizes

**Problem**: SolRengine Auth Engine renders wallet icons dynamically via JS (`wallet_controller.js`). The Solflare icon rendered huge because wallet-standard API provides icons at varying sizes.

**Root cause**: The gem's JS sets `class="w-8 h-8 rounded-lg"` on wallet icons, but with the pixel font base size change, Tailwind's `w-8` resolved differently.

**Solution**: CSS overrides with `!important` forcing exact pixel dimensions:
```css
[data-wallet-target="walletList"] button img {
  width: 24px !important;
  height: 24px !important;
  max-width: 24px !important;
  border-radius: 0 !important;
  image-rendering: pixelated;
}
```

**Prevention**: When overriding gem-rendered dynamic content, always use `!important` with explicit px values, not relative Tailwind classes.

### 3. Game page hidden behind mosaic background

**Problem**: After adding pixel mosaic background to the game layout, the entire challenge page was invisible.

**Root cause**: The mosaic canvas is `fixed inset-0` with `z-index:0`. The game layout's `<main>` had no `position: relative` or `z-index`, so it sat behind the canvas overlay.

**Solution**: Add `class="relative"` and `style="z-index:10"` to `<main>` in the game layout.

**Prevention**: Whenever adding a `fixed` background layer, ensure all content containers above it have explicit stacking context (`position: relative` + `z-index`).

### 4. Game over modal flash on new challenge

**Problem**: When starting a new challenge after game over, the old game over modal briefly appeared.

**Root cause**: Turbo Drive caches the page with the modal visible. On navigation to `/challenge`, Turbo shows the cached version momentarily.

**Solution**: Add `<meta name="turbo-cache-control" content="no-cache">` to the challenge show page via `content_for(:head)`.

**Prevention**: Any page with dynamic modal/overlay state that shouldn't persist should disable Turbo caching.

### 5. Canvas font loading race condition

**Problem**: The hex rain/mosaic canvas could render with the wrong font if Press Start 2P hadn't loaded from Google Fonts yet.

**Root cause**: Canvas `ctx.font` silently falls back to default if the requested font isn't loaded.

**Solution**: Gate animation start on `document.fonts.load()`:
```js
document.fonts.load("12px 'Press Start 2P'").then(() => {
  this.animate()
}).catch(() => {
  this.animate() // fallback
})
```

**Prevention**: Always wait for `document.fonts.ready` or `document.fonts.load()` before using custom fonts on canvas.

### 6. Engine route isolation with literal paths

**Problem**: Route helpers (`challenges_path`) broke on the auth login page because the SolRengine engine uses `isolate_namespace`.

**Root cause**: Engine-rendered pages can't access host app's named routes.

**Solution**: Use literal string paths everywhere (`"/challenges"`, `"/auth/login"`). Never use `_path` helpers in layouts or shared views.

**Prevention**: This is documented in CLAUDE.md. Any new view code must use literal paths.

### 7. Duplicate leaderboard entries

**Problem**: One game session created multiple leaderboard entries (one per correct answer + one on game over).

**Root cause**: `saveResult()` was called in both `handleCorrect()` and `gameOverSequence()`.

**Solution**: Remove `saveResult()` from `handleCorrect()` — only save on game over.

**Prevention**: Game result persistence should happen at a single terminal event (game over), not on intermediate state changes.

## Pixel Art Design System Summary

- **Font**: Press Start 2P (Google Fonts), base 12px, hierarchy: 20/14/12/10/11/8px
- **Icons**: 14 inline SVG pixel sprites via `pixel_icon` helper — no emoji
- **CSS classes**: `pixel-btn`, `pixel-card`, `pixel-input`, `pixel-dialog`, `pixel-nav`, `pixel-tooltip`
- **Background**: Pixel mosaic canvas (colorful squares, ~7fps shimmer)
- **Sounds**: Web Audio API square waves (correct, wrong, game over, start)
- **Buttons**: 3D box-shadow (inset highlights), instant state changes
- **Text shadows**: `text-shadow: Npx Npx 0 #4c1d95` on titles
