import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer", "status", "fieldName", "nextBtn"]
  static values = {
    targetRegion: String,
    targetName: String,
    targetDecoded: String
  }

  connect() {
    this.solved = false
    this.attempts = 0
    this.startTime = performance.now()
    this.timerInterval = setInterval(() => this.updateTimer(), 100)
  }

  disconnect() {
    if (this.timerInterval) clearInterval(this.timerInterval)
  }

  updateTimer() {
    if (this.solved) return
    const elapsed = (performance.now() - this.startTime) / 1000
    this.timerTarget.textContent = `${elapsed.toFixed(1)}s`
  }

  guess(event) {
    if (this.solved) return

    const cell = event.currentTarget
    const clickedRegion = cell.dataset.region

    this.attempts++

    if (clickedRegion === this.targetRegionValue) {
      // Correct!
      this.solved = true
      clearInterval(this.timerInterval)

      const elapsed = ((performance.now() - this.startTime) / 1000).toFixed(1)
      this.timerTarget.textContent = `${elapsed}s`

      // Reveal the correct region with its real colors
      this.revealRegion(this.targetRegionValue)

      // Show success
      const stars = this.attempts === 1 ? "⭐⭐⭐" : this.attempts <= 3 ? "⭐⭐" : "⭐"
      this.statusTarget.innerHTML = `
        <div class="text-green-400 text-lg mb-1">✅ Correct!</div>
        <div class="text-gray-300">Found <span class="text-purple-400 font-semibold">${this.targetNameValue}</span> in ${elapsed}s (${this.attempts} ${this.attempts === 1 ? 'click' : 'clicks'})</div>
        <div class="text-2xl mt-2">${stars}</div>
      `
      this.statusTarget.className = "mb-4 p-4 rounded-xl text-center bg-green-900/30 border border-green-700/50"
      this.statusTarget.classList.remove("hidden")

      // Show next button
      this.nextBtnTarget.classList.remove("hidden")
    } else {
      // Wrong — flash red briefly
      const originalBg = cell.style.background
      cell.style.background = "rgba(239, 68, 68, 0.3)"
      cell.style.outline = "1px solid rgba(239, 68, 68, 0.5)"
      setTimeout(() => {
        cell.style.background = originalBg
        cell.style.outline = "none"
      }, 300)

      // Show hint after 5 wrong attempts
      if (this.attempts === 5) {
        this.statusTarget.innerHTML = `<div class="text-yellow-400">💡 Hint: Look for the <span class="font-semibold">${this.targetNameValue}</span> field — it's a known structure in this account type.</div>`
        this.statusTarget.className = "mb-4 p-4 rounded-xl text-center bg-yellow-900/20 border border-yellow-700/30"
        this.statusTarget.classList.remove("hidden")
      }
    }
  }

  revealRegion(regionId) {
    // Find all cells in this region and restore their real colors
    const cells = this.element.querySelectorAll(`[data-region="${regionId}"]`)
    cells.forEach(cell => {
      cell.style.color = cell.dataset.baseColor
      cell.style.background = cell.dataset.baseBg
      cell.style.outline = "1px solid rgba(255,255,255,0.3)"
      cell.classList.remove("hover:bg-gray-700/50")
    })
  }
}
