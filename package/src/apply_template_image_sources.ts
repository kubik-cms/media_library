export function applyTemplateImageSources(root: ParentNode): void {
  root.querySelectorAll<HTMLImageElement>('img[data-thumb-src]').forEach((img) => {
    const url = img.dataset.thumbSrc
    if (!url) return

    img.src = url
    img.removeAttribute('data-thumb-src')
  })
}
