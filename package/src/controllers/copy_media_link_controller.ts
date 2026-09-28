import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  declare readonly inputTarget: HTMLInputElement
  declare readonly feedbackTarget: HTMLElement
  declare readonly hasInputTarget: boolean
  declare readonly hasFeedbackTarget: boolean
  declare readonly urlValue: string

  static values = {
    url: String
  }

  static targets = ["input", "feedback"]

  select(): void {
    if (this.hasInputTarget) {
      this.inputTarget.select()
    }
  }

  async copy(event: Event): Promise<void> {
    event.preventDefault()

    const url = this.urlValue || (this.hasInputTarget ? this.inputTarget.value : "")
    if (!url) return

    try {
      await navigator.clipboard.writeText(url)
    } catch {
      if (this.hasInputTarget) {
        this.inputTarget.select()
        document.execCommand("copy")
      }
    }

    if (this.hasFeedbackTarget) {
      this.feedbackTarget.hidden = false
      window.setTimeout(() => {
        this.feedbackTarget.hidden = true
      }, 2000)
    }
  }
}
