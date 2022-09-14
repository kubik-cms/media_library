import { Controller } from "@hotwired/stimulus"
import { template } from 'lodash'

export default class extends Controller {
  idValue: Number
  relatedMediaValue: {
    id: Number;
    kubik_media_upload_id: Number;
    thumb: Array<Object>;
  }
  newFieldsTemplateTarget: HTMLElement
  existingFieldsTemplateTarget: HTMLElement
  existingFieldsDeleteTemplateTarget: HTMLElement
  emptyTemplateTarget: HTMLElement
  imageContainerTarget: HTMLElement
  imageTemplateTarget: HTMLElement


  static values = {
    id: Number,
    relatedMedia: Object
  }

  static targets = [
    'imageContainer',
    'emptyTemplate',
    'imageTemplate',
    'newFieldsDeleteTemplate',
    'newFieldsTemplate',
    'existingFieldsTemplate',
    'existingFieldsDeleteTemplate',
    'associationId',
    'mediaUploadId',
    'mediaUploadDelete'
  ]

  connect(): void {
    this._renderResults()
  }

  _renderResults(): void {
    if(this.relatedMediaValue.thumb && this.relatedMediaValue.thumb.length > 0) {
      this.imageContainerTarget.innerHTML = this.imageTemplate(this.relatedMediaValue)
      if(this.idValue) {
        this.imageContainerTarget.innerHTML += this.existingFieldsTemplate(this.relatedMediaValue)
      } else {
        this.imageContainerTarget.innerHTML += this.newFieldsTemplate(this.relatedMediaValue)
      }
    } else {
      this.imageContainerTarget.innerHTML = this.emptyTemplate(this.relatedMediaValue)
      if(this.idValue) {
        this.imageContainerTarget.innerHTML += this.existingFieldsDeleteTemplate(this.relatedMediaValue)
      }
    }
  }

  get imageTemplate(): Function {
    return template(this.imageTemplateTarget.innerHTML);
  }

  get emptyTemplate(): Function {
    return template(this.emptyTemplateTarget.innerHTML);
  }

  get existingFieldsDeleteTemplate(): Function {
    return template(this.existingFieldsDeleteTemplateTarget.innerHTML);
  }

  get existingFieldsTemplate(): Function {
    return template(this.existingFieldsTemplateTarget.innerHTML);
  }

  get newFieldsTemplate(): Function {
    return template(this.newFieldsTemplateTarget.innerHTML);
  }

  relatedMediaValueChanged(): void {
    this._renderResults()
  }

  receiveModalReturn(returnObject): void {
    this.relatedMediaValue = returnObject.payload
  }

  removeImage(): void {
    this.relatedMediaValue = { id: this.idValue, thumb: null, kubik_media_upload_id: null }
  }
}
