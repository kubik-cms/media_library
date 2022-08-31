import { Application } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo"

import ImageSelectorController from "./controllers/image_selector_controller"
import MultipleImageSelectorController from "./controllers/multiple_image_selector_controller"
import ImageDropzoneController from "./controllers/image_dropzone_controller"

if(typeof KubikInterfaceStimulus != 'undefined') {
  KubikInterfaceStimulus.register("image_selector", ImageSelectorController)
  KubikInterfaceStimulus.register("multiple_image_selector", MultipleImageSelectorController)
  KubikInterfaceStimulus.register("image_dropzone", ImageDropzoneController)
}
