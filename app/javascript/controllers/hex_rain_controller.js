import { Controller } from "@hotwired/stimulus"

const HEX_CHARS = "0123456789abcdef"
const FONT_SIZE = 14
const COLUMN_GAP = FONT_SIZE + 2

export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    this.ctx = this.canvasTarget.getContext("2d")
    this.columns = []
    this.resize()
    this.boundResize = this.resize.bind(this)
    window.addEventListener("resize", this.boundResize)
    this.animate()
  }

  disconnect() {
    window.removeEventListener("resize", this.boundResize)
    if (this.frameId) cancelAnimationFrame(this.frameId)
  }

  resize() {
    const canvas = this.canvasTarget
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight

    const columnCount = Math.floor(canvas.width / COLUMN_GAP)

    // Preserve existing columns, add new ones if needed
    while (this.columns.length < columnCount) {
      this.columns.push({
        x: this.columns.length * COLUMN_GAP,
        y: Math.random() * -canvas.height * 2,
        speed: 1 + Math.random() * 3,
        chars: this.randomChars(30 + Math.floor(Math.random() * 20))
      })
    }
    this.columns.length = columnCount
  }

  randomChars(count) {
    return Array.from({ length: count }, () =>
      HEX_CHARS[Math.floor(Math.random() * HEX_CHARS.length)]
    )
  }

  animate() {
    const canvas = this.canvasTarget
    const ctx = this.ctx

    // Fade trail — semi-transparent black overlay
    ctx.fillStyle = "rgba(3, 7, 18, 0.15)"
    ctx.fillRect(0, 0, canvas.width, canvas.height)

    ctx.font = `${FONT_SIZE}px monospace`

    for (const col of this.columns) {
      const tailLength = col.chars.length

      for (let i = 0; i < tailLength; i++) {
        const charY = col.y - i * FONT_SIZE

        // Skip off-screen characters
        if (charY < -FONT_SIZE || charY > canvas.height + FONT_SIZE) continue

        if (i === 0) {
          // Leading character — bright white with glow
          ctx.shadowBlur = 15
          ctx.shadowColor = "#a78bfa"
          ctx.fillStyle = "#ffffff"
        } else if (i < 3) {
          // Near-head — bright purple
          ctx.shadowBlur = 8
          ctx.shadowColor = "#7c3aed"
          ctx.fillStyle = "#c4b5fd"
        } else {
          // Trail — fading green/purple
          const fade = Math.max(0, 1 - i / tailLength)
          const alpha = fade * 0.6
          ctx.shadowBlur = 0
          ctx.shadowColor = "transparent"
          ctx.fillStyle = `rgba(139, 92, 246, ${alpha})`
        }

        ctx.fillText(col.chars[i], col.x, charY)
      }

      // Move column down
      col.y += col.speed

      // Randomly mutate a character in the trail
      if (Math.random() < 0.03) {
        const idx = Math.floor(Math.random() * col.chars.length)
        col.chars[idx] = HEX_CHARS[Math.floor(Math.random() * HEX_CHARS.length)]
      }

      // Reset column when fully off screen
      if (col.y - col.chars.length * FONT_SIZE > canvas.height) {
        col.y = Math.random() * -500
        col.speed = 1 + Math.random() * 3
        col.chars = this.randomChars(30 + Math.floor(Math.random() * 20))
      }
    }

    ctx.shadowBlur = 0
    this.frameId = requestAnimationFrame(this.animate.bind(this))
  }
}
