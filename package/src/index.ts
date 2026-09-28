import ImageSelectorController from './controllers/image_selector_controller'
import MultipleImageSelectorController from './controllers/multiple_image_selector_controller'
import ImageDropzoneController from './controllers/image_dropzone_controller'
import PdfPreviewController from './controllers/pdf_preview_controller'
import CopyMediaLinkController from './controllers/copy_media_link_controller'
import {
  KUBIK_MEDIA_LIBRARY_STIMULUS_MANIFEST,
  registerKubikMediaLibraryStimulusControllers
} from './register_stimulus_controllers'

export default {
  ImageSelectorController,
  MultipleImageSelectorController,
  ImageDropzoneController,
  PdfPreviewController,
  CopyMediaLinkController,
  KUBIK_MEDIA_LIBRARY_STIMULUS_MANIFEST,
  registerKubikMediaLibraryStimulusControllers
}

export {
  ImageSelectorController,
  MultipleImageSelectorController,
  ImageDropzoneController,
  PdfPreviewController,
  CopyMediaLinkController,
  KUBIK_MEDIA_LIBRARY_STIMULUS_MANIFEST,
  registerKubikMediaLibraryStimulusControllers
}
