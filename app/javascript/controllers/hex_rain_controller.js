import { Controller } from "@hotwired/stimulus"

// Pixel mosaic background — colorful grid of squares with subtle animation
const CELL_SIZE = 24
const GAP = 2

// Color palette — purples, blues, cyans with some warm accents
const COLORS = [
  "#7c3aed", "#8b5cf6", "#a78bfa", "#6d28d9", // purples
  "#4f46e5", "#6366f1", "#818cf8",             // indigos
  "#2563eb", "#3b82f6",                         // blues
  "#0891b2", "#06b6d4", "#22d3ee",             // cyans
  "#059669", "#10b981",                         // greens
  "#d946ef", "#c026d3",                         // magentas
  "#f59e0b", "#f97316",                         // warm accents (rare)
  "#ef4444",                                     // red accent (rare)
]

// Weights: purples/indigos more frequent, warm colors rare
const WEIGHTED_COLORS = [
  ...COLORS.slice(0, 7),  // purples + indigos (×3)
  ...COLORS.slice(0, 7),
  ...COLORS.slice(0, 7),
  ...COLORS.slice(7, 9),  // blues (×2)
  ...COLORS.slice(7, 9),
  ...COLORS.slice(9, 12), // cyans (×1)
  ...COLORS.slice(12, 14),// greens (×1)
  ...COLORS.slice(14, 16),// magentas (×1)
  ...COLORS.slice(16),    // warm (×1)
]

export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    this.ctx = this.canvasTarget.getContext("2d")
    this.grid = []
    this.resize()
    this.boundResize = this.resize.bind(this)
    this.boundAnimate = this.animate.bind(this)
    window.addEventListener("resize", this.boundResize)
    this.animate()
  }

  disconnect() {
    window.removeEventListener("resize", this.boundResize)
    if (this.timeoutId) clearTimeout(this.timeoutId)
    if (this.rafId) cancelAnimationFrame(this.rafId)
  }

  resize() {
    const canvas = this.canvasTarget
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight

    const step = CELL_SIZE + GAP
    this.cols = Math.ceil(canvas.width / step) + 1
    this.rows = Math.ceil(canvas.height / step) + 1

    // Build grid with random colors and opacity
    this.grid = []
    for (let r = 0; r < this.rows; r++) {
      const row = []
      for (let c = 0; c < this.cols; c++) {
        row.push({
          color: this.randomColor(),
          alpha: 0.08 + Math.random() * 0.18,
        })
      }
      this.grid.push(row)
    }

    this.drawGrid()
  }

  randomColor() {
    return WEIGHTED_COLORS[Math.floor(Math.random() * WEIGHTED_COLORS.length)]
  }

  drawGrid() {
    const ctx = this.ctx
    const canvas = this.canvasTarget
    const step = CELL_SIZE + GAP

    // Clear to dark background
    ctx.fillStyle = "#030712"
    ctx.fillRect(0, 0, canvas.width, canvas.height)

    for (let r = 0; r < this.rows; r++) {
      for (let c = 0; c < this.cols; c++) {
        const cell = this.grid[r][c]
        ctx.globalAlpha = cell.alpha
        ctx.fillStyle = cell.color
        ctx.fillRect(c * step, r * step, CELL_SIZE, CELL_SIZE)
      }
    }
    ctx.globalAlpha = 1.0
  }

  animate() {
    // Randomly shimmer a few cells each frame
    const changes = Math.floor(this.cols * this.rows * 0.003) + 1
    const step = CELL_SIZE + GAP
    const ctx = this.ctx

    for (let i = 0; i < changes; i++) {
      const r = Math.floor(Math.random() * this.rows)
      const c = Math.floor(Math.random() * this.cols)
      const cell = this.grid[r][c]

      // Randomly change color or pulse alpha
      if (Math.random() < 0.3) {
        cell.color = this.randomColor()
      }
      cell.alpha = 0.06 + Math.random() * 0.22

      // Redraw just this cell
      ctx.fillStyle = "#030712"
      ctx.fillRect(c * step, r * step, CELL_SIZE, CELL_SIZE)
      ctx.globalAlpha = cell.alpha
      ctx.fillStyle = cell.color
      ctx.fillRect(c * step, r * step, CELL_SIZE, CELL_SIZE)
      ctx.globalAlpha = 1.0
    }

    // Slow frame rate — no need for 60fps on a background
    this.timeoutId = setTimeout(() => {
      this.rafId = requestAnimationFrame(this.boundAnimate)
    }, 150)
  }
}
