import { Controller } from "@hotwired/stimulus"

const BASE58_RE = /^[1-9A-HJ-NP-Za-km-z]{32,44}$/

export default class extends Controller {
  static targets = ["input", "submit", "error"]

  connect() {
    this.validate()
  }

  validate() {
    const value = this.inputTarget.value.trim()
    const valid = BASE58_RE.test(value)
    const empty = value.length === 0

    this.submitTarget.disabled = !valid
    this.submitTarget.style.cursor = valid ? "pointer" : "not-allowed"
    this.submitTarget.style.opacity = valid ? "1" : "0.4"

    if (!empty && !valid) {
      this.errorTarget.textContent = "Invalid Solana address"
      this.errorTarget.style.display = "block"
    } else {
      this.errorTarget.style.display = "none"
    }
  }

  submit(event) {
    const value = this.inputTarget.value.trim()
    if (!BASE58_RE.test(value)) {
      event.preventDefault()
    }
  }
}
