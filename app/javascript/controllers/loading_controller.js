import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner", "hero", "frame"]

  connect() {
    this.element.addEventListener("turbo:before-fetch-request", this.onBeforeFetch.bind(this))
    this.element.addEventListener("turbo:frame-load", this.onFrameLoad.bind(this))
  }

  onBeforeFetch(event) {
    // Determine if this is a "back to home" navigation
    const url = event.detail?.url?.toString() || ""
    this.isNavigatingHome = url.endsWith("/") || url === window.location.origin

    // Hide current content, show spinner
    if (this.hasHeroTarget) {
      this.heroTarget.style.display = "none"
    }
    this.frameTarget.style.display = "none"
    this.spinnerTarget.style.display = "flex"
  }

  onFrameLoad() {
    this.spinnerTarget.style.display = "none"
    const frameHasContent = this.frameTarget.children.length > 0

    if (frameHasContent) {
      this.frameTarget.style.display = ""
      if (this.hasHeroTarget) {
        this.heroTarget.style.display = "none"
      }
    } else {
      // Navigated back to home — restore hero
      this.frameTarget.style.display = ""
      if (this.hasHeroTarget) {
        this.heroTarget.style.display = ""
        this.heroTarget.style.opacity = "1"

        if (this.isNavigatingHome) {
          const input = this.heroTarget.querySelector("input[name=address]")
          if (input) {
            input.value = ""
            input.dispatchEvent(new Event("input"))
            input.focus()
          }
        }
      }
    }
  }
}
