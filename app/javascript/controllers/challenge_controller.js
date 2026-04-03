import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer", "fieldName", "lives", "modal", "modalContent", "toast", "toastContent"]
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
    this.showModal("correct", `
      <div class="text-5xl mb-4">✅</div>
      <div class="text-green-400 text-2xl font-bold mb-2">Correct!</div>
      <div class="text-gray-300 mb-1">
        <span class="text-purple-400 font-semibold font-mono">${this.targetNameValue}</span>
      </div>
      <div class="text-gray-400 text-sm mb-4">found in ${elapsed}s</div>
      <div class="text-3xl mb-2">${starEmojis}</div>
      <div class="text-yellow-400 font-bold text-xl mb-6">🔥 Streak: ${newStreak}</div>
      <a href="${this.nextUrlValue}?streak=${newStreak}"
         class="inline-flex items-center gap-2 bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-500 hover:to-emerald-500 text-white font-semibold py-3 px-8 rounded-xl transition-all duration-200 text-lg">
        Next Challenge →
      </a>
    `)
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

    // Update lives display
    const remaining = this.maxWrongValue - this.wrongAttempts
    this.livesTarget.textContent = "❤️".repeat(remaining) + "🖤".repeat(this.wrongAttempts)

    if (this.wrongAttempts >= this.maxWrongValue) {
      this.gameOverSequence()
      return
    }

    // Show wrong toast
    this.toastContentTarget.innerHTML = `
      <div class="text-3xl mb-2">❌</div>
      <div class="text-red-400 font-bold text-lg">Wrong!</div>
      <div class="text-gray-400 text-sm mt-1">${remaining} ${remaining === 1 ? 'life' : 'lives'} remaining</div>
    `
    this.toastTarget.classList.remove("hidden")
    if (this.toastTimeout) clearTimeout(this.toastTimeout)
    this.toastTimeout = setTimeout(() => {
      this.toastTarget.classList.add("hidden")
    }, 1000)
  }

  gameOverSequence() {
    this.solved = true
    clearInterval(this.timerInterval)

    const elapsed = ((performance.now() - this.startTime) / 1000).toFixed(1)

    this.revealRegion(this.targetRegionValue)
    this.livesTarget.textContent = "🖤🖤🖤"

    if (this.loggedInValue && this.streakValue > 0) {
      this.saveResult(elapsed, 0, this.streakValue)
    }

    this.showModal("gameover", `
      <div class="text-5xl mb-4">💀</div>
      <div class="text-red-400 text-2xl font-bold mb-2">Game Over!</div>
      <div class="text-gray-300 mb-1">
        The answer was <span class="text-purple-400 font-semibold font-mono">${this.targetNameValue}</span>
      </div>
      ${this.streakValue > 0
        ? `<div class="text-yellow-400 font-bold text-xl mt-4 mb-6">🔥 Final Streak: ${this.streakValue}</div>`
        : '<div class="mt-4 mb-6"></div>'
      }
      <a href="/challenges"
         class="inline-flex items-center gap-2 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 text-white font-semibold py-3 px-8 rounded-xl transition-all duration-200 text-lg">
        ← Back to Challenges
      </a>
    `)
  }

  showModal(type, content) {
    const borderColor = type === "correct"
      ? "border-green-700/50"
      : "border-red-700/50"
    const bgColor = type === "correct"
      ? "bg-gray-900 border border-green-700/50"
      : "bg-gray-900 border border-red-700/50"

    this.modalContentTarget.className = `relative max-w-sm w-full mx-4 rounded-2xl p-8 text-center ${bgColor}`
    this.modalContentTarget.innerHTML = content
    this.modalTarget.classList.remove("hidden")
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
