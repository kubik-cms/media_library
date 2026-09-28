import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  declare readonly frameTarget: HTMLIFrameElement
  declare readonly revealTarget: HTMLButtonElement
  declare readonly panelTarget: HTMLElement
  declare readonly urlValue: string

  static values = {
    url: String
  }

  static targets = ["frame", "reveal", "panel"]

  reveal(): void {
    if (!this.frameTarget.src) {
      this.frameTarget.src = this.urlValue
    }

    this.panelTarget.hidden = false
    this.revealTarget.hidden = true
  }
}
