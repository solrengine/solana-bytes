import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer", "status", "fieldName", "nextBtn"]
  static values = {
    targetRegion: String,
    targetName: String,
    targetDecoded: String,
    streak: { type: Number, default: 0 },
    maxWrong: { type: Number, default: 3 },
    saveUrl: String,
    nextUrl: String,
    accountAddress: String,
    loggedIn: { type: Boolean, default: false }
  }

  connect() {
    this.solved = false
    this.wrongAttempts = 0
    this.totalAttempts = 0
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

    this.totalAttempts++

    if (clickedRegion === this.targetRegionValue) {
      this.handleCorrect()
    } else {
      this.handleWrong(cell)
    }
  }

  handleCorrect() {
    this.solved = true
    clearInterval(this.timerInterval)

    const elapsed = ((performance.now() - this.startTime) / 1000).toFixed(1)
    const newStreak = this.streakValue + 1
    const stars = this.wrongAttempts === 0 ? 3 : this.wrongAttempts === 1 ? 2 : 1

    this.timerTarget.textContent = `${elapsed}s`
    this.revealRegion(this.targetRegionValue)

    const starEmojis = "⭐".repeat(stars)
    this.statusTarget.innerHTML = `
      <div class="text-green-400 text-lg mb-1">✅ Correct!</div>
      <div class="text-gray-300">
        <span class="text-purple-400 font-semibold">${this.targetNameValue}</span>
        found in ${elapsed}s
      </div>
      <div class="text-2xl mt-2">${starEmojis}</div>
      <div class="text-yellow-400 font-bold text-lg mt-1">🔥 Streak: ${newStreak}</div>
    `
    this.statusTarget.className = "mb-4 p-4 rounded-xl text-center bg-green-900/30 border border-green-700/50"
    this.statusTarget.classList.remove("hidden")

    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.innerHTML = `
        <a href="${this.nextUrlValue}?streak=${newStreak}" class="inline-flex items-center gap-2 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 text-white font-semibold py-3 px-6 rounded-xl transition-all duration-200">
          Next Challenge →
        </a>
      `
      this.nextBtnTarget.classList.remove("hidden")
    }
  }

  handleWrong(cell) {
    this.wrongAttempts++

    const originalBg = cell.style.background
    cell.style.background = "rgba(239, 68, 68, 0.3)"
    cell.style.outline = "1px solid rgba(239, 68, 68, 0.5)"
    setTimeout(() => {
      cell.style.background = originalBg
      cell.style.outline = "none"
    }, 300)

    if (this.wrongAttempts >= this.maxWrongValue) {
      this.gameOverSequence()
      return
    }

    const remaining = this.maxWrongValue - this.wrongAttempts
    this.statusTarget.innerHTML = `<div class="text-yellow-400">❌ Wrong! ${remaining} ${remaining === 1 ? 'attempt' : 'attempts'} remaining</div>`
    this.statusTarget.className = "mb-4 p-4 rounded-xl text-center bg-yellow-900/20 border border-yellow-700/30"
    this.statusTarget.classList.remove("hidden")
  }

  gameOverSequence() {
    this.solved = true
    clearInterval(this.timerInterval)

    const elapsed = ((performance.now() - this.startTime) / 1000).toFixed(1)

    this.revealRegion(this.targetRegionValue)

    this.statusTarget.innerHTML = `
      <div class="text-red-400 text-2xl mb-2">💀 Game Over!</div>
      <div class="text-gray-300 mb-2">
        The answer was <span class="text-purple-400 font-semibold">${this.targetNameValue}</span>
      </div>
      <div class="text-yellow-400 font-bold text-xl">Final Streak: ${this.streakValue}</div>
      ${this.streakValue > 0 ? '<div class="text-gray-400 text-sm mt-2">🔥 Nice run!</div>' : ''}
    `
    this.statusTarget.className = "mb-4 p-6 rounded-xl text-center bg-red-900/20 border border-red-700/30"
    this.statusTarget.classList.remove("hidden")

    if (this.loggedInValue && this.streakValue > 0) {
      this.saveResult(elapsed, 0, this.streakValue)
    }

    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.innerHTML = `
        <a href="${this.nextUrlValue}" class="inline-flex items-center gap-2 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 text-white font-semibold py-3 px-6 rounded-xl transition-all duration-200">
          Play Again
        </a>
      `
      this.nextBtnTarget.classList.remove("hidden")
    }
  }

  async saveResult(timeSeconds, stars, streak) {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      await fetch(this.saveUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          account_address: this.accountAddressValue,
          target_field: this.targetNameValue,
          time_seconds: parseFloat(timeSeconds),
          attempts: this.totalAttempts,
          stars: stars,
          streak: streak
        })
      })
    } catch (e) {
      console.error("Failed to save result:", e)
    }
  }

  revealRegion(regionId) {
    const cells = this.element.querySelectorAll(`[data-region="${regionId}"]`)
    cells.forEach(cell => {
      cell.style.color = cell.dataset.baseColor
      cell.style.background = cell.dataset.baseBg
      cell.style.outline = "1px solid rgba(255,255,255,0.3)"
    })
  }
}
