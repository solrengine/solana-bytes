import { Controller } from "@hotwired/stimulus"

// Shows a pixel loading overlay during challenge page navigation
// (RPC fetch can take 1-3 seconds)
export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    this.boundBeforeVisit = this.beforeVisit.bind(this)
    document.addEventListener("turbo:before-visit", this.boundBeforeVisit)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.boundBeforeVisit)
  }

  beforeVisit(event) {
    const url = event.detail?.url || ""
    if (url.includes("/challenge")) {
      this.overlayTarget.classList.remove("hidden")
    }
  }
}
