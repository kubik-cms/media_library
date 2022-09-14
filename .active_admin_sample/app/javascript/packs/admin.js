import { Application } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo"

import { ImageSelectorController,
         MultipleImageSelectorController,
         ImageDropzoneController } from "@kubik-cms/media_library"
import KubikModalController from "@kubik-cms/kubik_interface_elements"

const KubikInterfaceStimulus = Application.start()

if(typeof KubikInterfaceStimulus != 'undefined') {
  KubikInterfaceStimulus.register("image_selector", ImageSelectorController)
  KubikInterfaceStimulus.register("multiple_image_selector", MultipleImageSelectorController)
  KubikInterfaceStimulus.register("image_dropzone", ImageDropzoneController)
  KubikInterfaceStimulus.register("kubik-modal", KubikModalController)
}

