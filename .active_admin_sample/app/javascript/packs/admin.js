import { Application } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo"

import MediaLibrary, { registerKubikMediaLibraryStimulusControllers } from "@kubik-cms/media_library"
import { modalInit, registerKubikInterfaceStimulusControllers } from "@kubik-cms/interface_elements"

const KubikInterfaceStimulus = Application.start()

if(typeof KubikInterfaceStimulus != 'undefined') {
  registerKubikMediaLibraryStimulusControllers(KubikInterfaceStimulus)
  registerKubikInterfaceStimulusControllers(KubikInterfaceStimulus)
}
modalInit()
