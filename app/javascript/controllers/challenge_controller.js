import { Controller } from "@hotwired/stimulus"

// Pixel SVG sprite constants for JS-rendered icons
const ICONS = {
  heart: '<span class="pixel-icon text-red-500" style="width:18px;height:18px"><svg viewBox="0 0 16 16" fill="currentColor" shape-rendering="crispEdges"><rect x="2" y="2" width="2" height="2"/><rect x="4" y="0" width="2" height="2"/><rect x="6" y="0" width="2" height="2"/><rect x="8" y="2" width="2" height="2"/><rect x="10" y="0" width="2" height="2"/><rect x="12" y="0" width="2" height="2"/><rect x="14" y="2" width="2" height="2"/><rect x="0" y="4" width="2" height="2"/><rect x="2" y="4" width="2" height="2"/><rect x="4" y="2" width="2" height="2"/><rect x="6" y="2" width="2" height="2"/><rect x="8" y="4" width="2" height="2"/><rect x="10" y="2" width="2" height="2"/><rect x="12" y="2" width="2" height="2"/><rect x="14" y="4" width="2" height="2"/><rect x="0" y="6" width="2" height="2"/><rect x="2" y="6" width="2" height="2"/><rect x="4" y="4" width="2" height="2"/><rect x="6" y="4" width="2" height="2"/><rect x="8" y="6" width="2" height="2"/><rect x="10" y="4" width="2" height="2"/><rect x="12" y="4" width="2" height="2"/><rect x="14" y="6" width="2" height="2"/><rect x="2" y="8" width="2" height="2"/><rect x="4" y="6" width="2" height="2"/><rect x="6" y="6" width="2" height="2"/><rect x="8" y="8" width="2" height="2"/><rect x="10" y="6" width="2" height="2"/><rect x="12" y="6" width="2" height="2"/><rect x="4" y="8" width="2" height="2"/><rect x="6" y="8" width="2" height="2"/><rect x="8" y="10" width="2" height="2"/><rect x="10" y="8" width="2" height="2"/><rect x="6" y="10" width="2" height="2"/><rect x="8" y="12" width="2" height="2"/></svg></span>',
  heartEmpty: '<span class="pixel-icon text-gray-600" style="width:18px;height:18px"><svg viewBox="0 0 16 16" fill="currentColor" shape-rendering="crispEdges" opacity="0.3"><rect x="2" y="2" width="2" height="2"/><rect x="4" y="0" width="2" height="2"/><rect x="6" y="0" width="2" height="2"/><rect x="8" y="2" width="2" height="2"/><rect x="10" y="0" width="2" height="2"/><rect x="12" y="0" width="2" height="2"/><rect x="14" y="2" width="2" height="2"/><rect x="0" y="4" width="2" height="2"/><rect x="2" y="4" width="2" height="2"/><rect x="4" y="2" width="2" height="2"/><rect x="6" y="2" width="2" height="2"/><rect x="8" y="4" width="2" height="2"/><rect x="10" y="2" width="2" height="2"/><rect x="12" y="2" width="2" height="2"/><rect x="14" y="4" width="2" height="2"/><rect x="0" y="6" width="2" height="2"/><rect x="2" y="6" width="2" height="2"/><rect x="4" y="4" width="2" height="2"/><rect x="6" y="4" width="2" height="2"/><rect x="8" y="6" width="2" height="2"/><rect x="10" y="4" width="2" height="2"/><rect x="12" y="4" width="2" height="2"/><rect x="14" y="6" width="2" height="2"/><rect x="2" y="8" width="2" height="2"/><rect x="4" y="6" width="2" height="2"/><rect x="6" y="6" width="2" height="2"/><rect x="8" y="8" width="2" height="2"/><rect x="10" y="6" width="2" height="2"/><rect x="12" y="6" width="2" height="2"/><rect x="4" y="8" width="2" height="2"/><rect x="6" y="8" width="2" height="2"/><rect x="8" y="10" width="2" height="2"/><rect x="10" y="8" width="2" height="2"/><rect x="6" y="10" width="2" height="2"/><rect x="8" y="12" width="2" height="2"/></svg></span>',
  checkmark: '<span class="pixel-icon" style="width:40px;height:40px"><svg viewBox="0 0 16 16" fill="#4ade80" shape-rendering="crispEdges"><rect x="12" y="2" width="2" height="2"/><rect x="10" y="4" width="2" height="2"/><rect x="8" y="6" width="2" height="2"/><rect x="6" y="8" width="2" height="2"/><rect x="4" y="10" width="2" height="2"/><rect x="2" y="8" width="2" height="2"/></svg></span>',
  cross: '<span class="pixel-icon" style="width:28px;height:28px"><svg viewBox="0 0 16 16" fill="#ef4444" shape-rendering="crispEdges"><rect x="2" y="2" width="2" height="2"/><rect x="12" y="2" width="2" height="2"/><rect x="4" y="4" width="2" height="2"/><rect x="10" y="4" width="2" height="2"/><rect x="6" y="6" width="4" height="4"/><rect x="4" y="10" width="2" height="2"/><rect x="10" y="10" width="2" height="2"/><rect x="2" y="12" width="2" height="2"/><rect x="12" y="12" width="2" height="2"/></svg></span>',
  skull: '<span class="pixel-icon" style="width:40px;height:40px"><svg viewBox="0 0 16 16" fill="currentColor" shape-rendering="crispEdges"><rect x="4" y="0" width="8" height="2"/><rect x="2" y="2" width="2" height="2"/><rect x="12" y="2" width="2" height="2"/><rect x="0" y="4" width="2" height="4"/><rect x="14" y="4" width="2" height="4"/><rect x="2" y="4" width="2" height="4"/><rect x="12" y="4" width="2" height="4"/><rect x="4" y="4" width="2" height="2"/><rect x="6" y="4" width="2" height="2"/><rect x="8" y="4" width="2" height="2"/><rect x="10" y="4" width="2" height="2"/><rect x="4" y="6" width="2" height="2" fill="#0a0a14"/><rect x="10" y="6" width="2" height="2" fill="#0a0a14"/><rect x="6" y="8" width="4" height="2"/><rect x="2" y="8" width="2" height="2"/><rect x="12" y="8" width="2" height="2"/><rect x="4" y="10" width="8" height="2"/><rect x="4" y="12" width="2" height="2"/><rect x="6" y="12" width="2" height="2" fill="#0a0a14"/><rect x="8" y="12" width="2" height="2"/><rect x="10" y="12" width="2" height="2" fill="#0a0a14"/><rect x="4" y="14" width="8" height="2"/></svg></span>',
  fire: '<span class="pixel-icon" style="width:18px;height:18px"><svg viewBox="0 0 16 16" shape-rendering="crispEdges"><rect x="6" y="0" width="2" height="2" fill="#fde047"/><rect x="8" y="0" width="2" height="2" fill="#f97316"/><rect x="4" y="2" width="2" height="2" fill="#fde047"/><rect x="6" y="2" width="2" height="2" fill="#fde047"/><rect x="8" y="2" width="2" height="2" fill="#f97316"/><rect x="10" y="2" width="2" height="2" fill="#ef4444"/><rect x="4" y="4" width="2" height="2" fill="#fde047"/><rect x="6" y="4" width="2" height="2" fill="#fde047"/><rect x="8" y="4" width="2" height="2" fill="#f97316"/><rect x="10" y="4" width="2" height="2" fill="#ef4444"/><rect x="12" y="4" width="2" height="2" fill="#ef4444"/><rect x="2" y="6" width="2" height="2" fill="#f97316"/><rect x="4" y="6" width="2" height="2" fill="#fde047"/><rect x="6" y="6" width="2" height="2" fill="#fde047"/><rect x="8" y="6" width="2" height="2" fill="#f97316"/><rect x="10" y="6" width="2" height="2" fill="#ef4444"/><rect x="12" y="6" width="2" height="2" fill="#ef4444"/><rect x="2" y="8" width="2" height="2" fill="#f97316"/><rect x="4" y="8" width="2" height="2" fill="#f97316"/><rect x="6" y="8" width="2" height="2" fill="#fde047"/><rect x="8" y="8" width="2" height="2" fill="#f97316"/><rect x="10" y="8" width="2" height="2" fill="#f97316"/><rect x="12" y="8" width="2" height="2" fill="#ef4444"/><rect x="2" y="10" width="2" height="2" fill="#ef4444"/><rect x="4" y="10" width="2" height="2" fill="#f97316"/><rect x="6" y="10" width="2" height="2" fill="#f97316"/><rect x="8" y="10" width="2" height="2" fill="#f97316"/><rect x="10" y="10" width="2" height="2" fill="#ef4444"/><rect x="4" y="12" width="2" height="2" fill="#ef4444"/><rect x="6" y="12" width="2" height="2" fill="#ef4444"/><rect x="8" y="12" width="2" height="2" fill="#ef4444"/><rect x="10" y="12" width="2" height="2" fill="#ef4444"/><rect x="6" y="14" width="4" height="2" fill="#991b1b"/></svg></span>',
  star: '<span class="pixel-icon text-yellow-400" style="width:18px;height:18px"><svg viewBox="0 0 16 16" fill="currentColor" shape-rendering="crispEdges"><rect x="6" y="0" width="4" height="2"/><rect x="6" y="2" width="4" height="2"/><rect x="0" y="4" width="16" height="2"/><rect x="2" y="6" width="12" height="2"/><rect x="2" y="8" width="12" height="2"/><rect x="2" y="10" width="4" height="2"/><rect x="10" y="10" width="4" height="2"/><rect x="0" y="12" width="4" height="2"/><rect x="12" y="12" width="4" height="2"/></svg></span>'
}

export default class extends Controller {
  static targets = ["fieldName", "lives", "modal", "modalContent", "toast", "toastContent"]
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

    const newStreak = this.streakValue + 1
    const stars = this.wrongAttempts === 0 ? 3 : this.wrongAttempts === 1 ? 2 : 1

    this.revealRegion(this.targetRegionValue)

    const starIcons = ICONS.star.repeat(stars)
    this.showModal("correct", `
      <div class="mb-4">${ICONS.checkmark}</div>
      <div class="text-green-400 mb-2" style="font-size:16px">Correct!</div>
      <div class="text-gray-300 mb-4" style="font-size:12px">
        <span class="text-purple-400">${this.targetNameValue}</span>
      </div>
      <div class="mb-2">${starIcons}</div>
      <div class="text-yellow-400 mb-6" style="font-size:14px">${ICONS.fire} Streak: ${newStreak}</div>
      <a href="${this.nextUrlValue}?streak=${newStreak}" class="pixel-btn pixel-btn-green" style="font-size:12px">
        Next Challenge >>
      </a>
    `)
  }

  handleWrong(cell) {
    this.wrongAttempts++

    const originalBg = cell.style.background
    cell.style.background = "rgba(239, 68, 68, 0.3)"
    cell.style.outline = "2px solid rgba(239, 68, 68, 0.5)"
    setTimeout(() => {
      cell.style.background = originalBg
      cell.style.outline = "none"
    }, 300)

    // Update lives display
    const remaining = this.maxWrongValue - this.wrongAttempts
    this.livesTarget.innerHTML = ICONS.heart.repeat(remaining) + ICONS.heartEmpty.repeat(this.wrongAttempts)

    if (this.wrongAttempts >= this.maxWrongValue) {
      this.gameOverSequence()
      return
    }

    // Show wrong toast
    this.toastContentTarget.innerHTML = `
      <div class="mb-2">${ICONS.cross}</div>
      <div class="text-red-400" style="font-size:14px">Wrong!</div>
      <div class="text-gray-400 mt-1" style="font-size:10px">${remaining} ${remaining === 1 ? 'life' : 'lives'} left</div>
    `
    this.toastTarget.classList.remove("hidden")
    if (this.toastTimeout) clearTimeout(this.toastTimeout)
    this.toastTimeout = setTimeout(() => {
      this.toastTarget.classList.add("hidden")
    }, 1000)
  }

  gameOverSequence() {
    this.solved = true

    this.revealRegion(this.targetRegionValue)
    this.livesTarget.innerHTML = ICONS.heartEmpty.repeat(3)

    if (this.loggedInValue && this.streakValue > 0) {
      this.saveResult(0, this.streakValue)
    }

    this.showModal("gameover", `
      <div class="mb-4">${ICONS.skull}</div>
      <div class="text-red-400 mb-2" style="font-size:16px">Game Over!</div>
      <div class="text-gray-300 mb-1" style="font-size:12px">
        The answer was <span class="text-purple-400">${this.targetNameValue}</span>
      </div>
      ${this.streakValue > 0
        ? `<div class="text-yellow-400 mt-4 mb-6" style="font-size:14px">${ICONS.fire} Final Streak: ${this.streakValue}</div>`
        : '<div class="mt-4 mb-6"></div>'
      }
      <a href="/challenges" class="pixel-btn" style="font-size:12px">
        << Back to Challenges
      </a>
    `)
  }

  showModal(type, content) {
    const borderColor = type === "correct" ? "#4ade80" : "#ef4444"
    this.modalContentTarget.style.borderColor = borderColor
    this.modalContentTarget.innerHTML = content
    this.modalTarget.classList.remove("hidden")
  }

  async saveResult(stars, streak) {
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
          time_seconds: 0,
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
      cell.style.outline = "2px solid rgba(255,255,255,0.3)"
    })
  }
}
