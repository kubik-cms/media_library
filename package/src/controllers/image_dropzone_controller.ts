import Dropzone from "dropzone";
import { Controller } from "@hotwired/stimulus"

Dropzone.autoDiscover = false

declare global {
  interface Window {
    Turbo?: { renderStreamMessage: (message: string) => void }
  }
}

type DropzoneFile = Dropzone.DropzoneFile

export default class extends Controller {
  formTarget: HTMLElement
  textTarget: HTMLElement
  submitTarget: HTMLElement
  placeholderTarget: HTMLElement
  errorsTarget: HTMLElement
  errorListTarget: HTMLElement
  previewsTarget: HTMLElement
  textValue: string
  modalValue: Boolean
  turboValue: Boolean
  acceptedFilesValue: string
  maxFilesizeMbValue: number

  dropzone: Dropzone | null = null

  static targets = [
    "input",
    "text",
    "submit",
    "placeholder",
    "form",
    "errors",
    "errorList",
    "previews"
  ]
  static values = {
    text: String,
    turbo: Boolean,
    modal: Boolean,
    acceptedFiles: String,
    maxFilesizeMb: { type: Number, default: 10 }
  }

  connect(): void {
    const clickable =
      this.formTarget.querySelector<HTMLElement>("[data-dz-message]") ?? this.formTarget

    const dropzoneOptions: Dropzone.DropzoneOptions = {
      paramName: 'kubik_media_upload[image]',
      thumbnailHeight: 180,
      thumbnailWidth: 180,
      thumbnailMethod: 'crop',
      headers: this.headers ?? undefined,
      maxFilesize: this.maxFilesizeMbValue,
      previewsContainer: this.previewsContainerElement,
      clickable,
      success: (file, response) => {
        file.previewElement?.remove();
        window.Turbo?.renderStreamMessage(response)
      }
    }

    if (this.acceptedFilesValue && this.acceptedFilesValue.length > 0) {
      dropzoneOptions.acceptedFiles = this.acceptedFilesValue
    }

    this.dropzone = new Dropzone(this.formTarget, dropzoneOptions)
    this.dropzone.on("error", (file: DropzoneFile, message: string | Error, xhr?: XMLHttpRequest) => {
      this.recordUploadError(file, message, xhr)
    })
    this.element.classList.add('dropzone_ready')
  }

  disconnect(): void {
    this.dropzone?.destroy()
    this.dropzone = null
  }

  textValueChanged(): void {
    this.textTarget.innerHTML = this.textValue
  }

  dismissError(event: Event): void {
    const button = event.currentTarget as HTMLElement
    const item = button.closest("[data-upload-error-id]") as HTMLElement | null
    const errorId = item?.dataset.uploadErrorId
    if (errorId) this.removeFailedUpload(errorId)
    item?.remove()
    this.syncErrorsPanelVisibility()
  }

  dismissAllErrors(): void {
    this.errorListTarget
      .querySelectorAll<HTMLElement>("[data-upload-error-id]")
      .forEach((item) => {
        const errorId = item.dataset.uploadErrorId
        if (errorId) this.removeFailedUpload(errorId)
      })
    this.errorListTarget.replaceChildren()
    this.syncErrorsPanelVisibility()
  }

  get headers(): Record<string, string> | null {
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

  private recordUploadError(
    file: DropzoneFile,
    message: string | Error | { error?: string },
    xhr?: XMLHttpRequest
  ): void {
    const errorId = this.errorIdFor(file)
    const detail = this.formatErrorMessage(message, xhr)
    const existing = this.errorListTarget.querySelector(
      `[data-upload-error-id="${errorId}"]`
    )
    if (existing) {
      const detailNode = existing.querySelector("[data-upload-error-detail]")
      if (detailNode) detailNode.textContent = detail
      return
    }

    const item = document.createElement("li")
    item.className = "kubik-media-gallery--upload-errors__item"
    item.dataset.uploadErrorId = errorId

    const name = document.createElement("span")
    name.className = "kubik-media-gallery--upload-errors__filename"
    name.textContent = file.name

    const detailEl = document.createElement("span")
    detailEl.className = "kubik-media-gallery--upload-errors__detail"
    detailEl.dataset.uploadErrorDetail = "true"
    detailEl.textContent = detail

    const dismiss = document.createElement("button")
    dismiss.type = "button"
    dismiss.className = "kubik-media-gallery--upload-errors__dismiss"
    dismiss.setAttribute("aria-label", `Dismiss error for ${file.name}`)
    dismiss.textContent = "Dismiss"
    dismiss.dataset.action = "click->image_dropzone#dismissError"

    item.append(name, detailEl, dismiss)
    this.errorListTarget.append(item)
    this.syncErrorsPanelVisibility()
  }

  private errorIdFor(file: DropzoneFile): string {
    const upload = file.upload as { uuid?: string } | undefined
    if (upload?.uuid) return upload.uuid
    return `${file.name}-${file.size}-${file.lastModified}`
  }

  private formatErrorMessage(
    message: string | Error | { error?: string },
    xhr?: XMLHttpRequest
  ): string {
    if (message instanceof Error) return message.message

    if (typeof message === "object" && message !== null && "error" in message) {
      const nested = (message as { error?: string }).error
      if (nested) return nested
    }

    if (typeof message === "string") {
      const trimmed = message.trim()
      if (trimmed.startsWith("<")) {
        const doc = new DOMParser().parseFromString(trimmed, "text/html")
        const fromDom =
          doc.querySelector(".flash_error, .inline_errors li, .errors li, #errorExplanation li")
            ?.textContent?.trim()
        if (fromDom) return fromDom
        if (xhr?.status === 413) return this.payloadTooLargeMessage()
        if (xhr && xhr.status >= 400) {
          return `Upload failed (HTTP ${xhr.status}). Please check the file and try again.`
        }
        return "Upload failed. Please try again."
      }
      return trimmed
    }

    if (xhr?.status === 413) return this.payloadTooLargeMessage()

    if (xhr && xhr.status >= 400) {
      return `Upload failed (HTTP ${xhr.status}). Please check the file and try again.`
    }

    return "Upload failed. Please try again."
  }

  private syncErrorsPanelVisibility(): void {
    const hasErrors = this.errorListTarget.children.length > 0
    this.errorsTarget.hidden = !hasErrors
  }

  private removeFailedUpload(errorId: string): void {
    const file = this.fileForErrorId(errorId)
    if (!file || !this.dropzone) return

    this.dropzone.removeFile(file)
  }

  private fileForErrorId(errorId: string): DropzoneFile | undefined {
    return this.dropzone?.files.find((candidate) => this.errorIdFor(candidate) === errorId)
  }

  private payloadTooLargeMessage(): string {
    const limit = this.maxFilesizeMbValue
    return `The upload was blocked before it reached the app (HTTP 413). Maximum file size is ${limit} MB. If the file is smaller, raise the reverse proxy body limit (e.g. nginx client_max_body_size).`
  }

  private get previewsContainerElement(): HTMLElement {
    const existing = this.element.querySelector<HTMLElement>(
      '[data-image_dropzone-target="previews"], [data-image-dropzone-target="previews"]'
    )
    if (existing) return existing

    const created = document.createElement("div")
    created.className = "kubik-media-gallery--upload-previews"
    created.setAttribute("data-image_dropzone-target", "previews")
    this.element.insertBefore(created, this.formTarget)
    return created
  }
}
