import type { Application } from '@hotwired/stimulus'

import ImageSelectorController from './controllers/image_selector_controller'
import MultipleImageSelectorController from './controllers/multiple_image_selector_controller'
import ImageDropzoneController from './controllers/image_dropzone_controller'
import PdfPreviewController from './controllers/pdf_preview_controller'
import CopyMediaLinkController from './controllers/copy_media_link_controller'

export const KUBIK_MEDIA_LIBRARY_STIMULUS_MANIFEST = [
  'image_selector',
  'multiple_image_selector',
  'image_dropzone',
  'pdf-preview',
  'copy-media-link'
] as const

export function registerKubikMediaLibraryStimulusControllers(application: Application): void {
  application.register('image_selector', ImageSelectorController)
  application.register('multiple_image_selector', MultipleImageSelectorController)
  application.register('image_dropzone', ImageDropzoneController)
  application.register('pdf-preview', PdfPreviewController)
  application.register('copy-media-link', CopyMediaLinkController)
}
