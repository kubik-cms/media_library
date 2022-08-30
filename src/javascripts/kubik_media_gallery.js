import { Application } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo"

import ImageSelectorController from "./controllers/image_selector_controller"
import MultipleImageSelectorController from "./controllers/multiple_image_selector_controller"
import ImageDropzoneController from "./controllers/image_dropzone_controller"

window.Stimulus = Application.start()
Stimulus.register("image_selector", ImageSelectorController)
Stimulus.register("multiple_image_selector", MultipleImageSelectorController)
Stimulus.register("image_dropzone", ImageDropzoneController)
