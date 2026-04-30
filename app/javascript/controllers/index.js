import { Application } from "@hotwired/stimulus"

const application = Application.start()

import HexViewerController from "./hex_viewer_controller"
application.register("hex-viewer", HexViewerController)

import HexRainController from "./hex_rain_controller"
application.register("hex-rain", HexRainController)

import LoadingController from "./loading_controller"
application.register("loading", LoadingController)

import AddressFormController from "./address_form_controller"
application.register("address-form", AddressFormController)

import AutoSubmitController from "./auto_submit_controller"
application.register("auto-submit", AutoSubmitController)

import ChallengeController from "./challenge_controller"
application.register("challenge", ChallengeController)

import { WalletController } from "@solrengine/wallet-utils/controllers"
application.register("wallet", WalletController)

// Show loading overlay when navigating to challenge pages
document.addEventListener("turbo:before-visit", (event) => {
  if (event.detail?.url?.includes("/challenge")) {
    const overlay = document.getElementById("game-loading")
    if (overlay) overlay.classList.remove("hidden")
  }
})

// Hide the overlay before Turbo caches the page and after every navigation,
// so browser back/forward doesn't restore a cached snapshot with the overlay visible.
const hideGameLoading = () => {
  const overlay = document.getElementById("game-loading")
  if (overlay) overlay.classList.add("hidden")
}
document.addEventListener("turbo:before-cache", hideGameLoading)
document.addEventListener("turbo:load", hideGameLoading)

export { application }
