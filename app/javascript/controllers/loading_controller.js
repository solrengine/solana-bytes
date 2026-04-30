import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner", "hero", "frame"]

  connect() {
    this.boundBeforeFetch = this.onBeforeFetch.bind(this)
    this.boundFrameLoad = this.onFrameLoad.bind(this)
    this.element.addEventListener("turbo:before-fetch-request", this.boundBeforeFetch)
    this.element.addEventListener("turbo:frame-load", this.boundFrameLoad)
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-fetch-request", this.boundBeforeFetch)
    this.element.removeEventListener("turbo:frame-load", this.boundFrameLoad)
  }

  onBeforeFetch(event) {
    const url = event.detail?.url?.toString() || ""
    this.isNavigatingHome = url.endsWith("/") || url === window.location.origin

    if (this.hasHeroTarget) {
      this.heroTarget.style.display = "none"
    }
    this.frameTarget.style.display = "none"
    this.spinnerTarget.style.display = "flex"
    // Hero is hiding — reveal the navbar on landing so the result view has nav.
    document.body.classList.remove("landing-hero-active")
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
          // Hero is back on landing — hide the navbar again for the clean hero look.
          document.body.classList.add("landing-hero-active")
        }
      }
    }
  }
}
