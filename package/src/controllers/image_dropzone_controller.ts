import { Dropzone } from "dropzone";
import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
  formTarget: HTMLElement
  textTarget: HTMLElement
  submitTarget: HTMLElement
  placeholderTarget: HTMLElement
  textValue: string
  modalValue: Boolean
  turboValue: Boolean

  static targets = [ "input", "text", "submit", "placeholder", "form" ]
  static values = {
    text: String,
    turbo: Boolean,
    modal: Boolean
  }

  connect(): void {
    const dropzone = new Dropzone(this.formTarget, {
      paramName: 'kubik_media_upload[image]',
      thumbnailHeight: 180,
      thumbnailWidth: 180,
      thumbnailMethod: 'crop',
      headers: this.headers,
      success: (file, response) => {
        file.previewElement.remove();
        Turbo.renderStreamMessage(response)
      }
    })
    this.element.classList.add('dropzone_ready')
  }

  textValueChanged(): void {
    this.textTarget.innerHTML = this.textValue
  }

  get headers(): Object {
    return this.turboValue === true ? {"Accept": "text/vnd.turbo-stream.html" } : null
  }

  file_changed(e: Event): void {
    const target = e.target as HTMLInputElement
    const filename = target.files[0].name
    this.textValue = filename
    if(filename.length > 0) {
      this.submitTarget.style.display = 'block'
      this.placeholderTarget.classList.remove('no-file')
    } else {
      this.placeholderTarget.classList.add('no-file')
    }
  }
}

