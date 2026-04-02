import { Application } from "@hotwired/stimulus"

const application = Application.start()

import HexViewerController from "./hex_viewer_controller"
application.register("hex-viewer", HexViewerController)

export { application }
