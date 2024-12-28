import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  
  connect() {
    this.initialFormData = new FormData(this.formTarget)
    this.setupNavigation()
  }

  disconnect() {
    this.removeNavigation()
  }

  setupNavigation() {
    this.clickHandler = this.handleClick.bind(this)
    document.addEventListener('click', this.clickHandler, true)
  }

  removeNavigation() {
    document.removeEventListener('click', this.clickHandler, true)
  }

  handleClick(event) {
    const link = event.target.closest('a')
    if (!link) return

    // Ignore if it's a download link or has data-turbo="false"
    if (link.hasAttribute('download') || link.dataset.turbo === "false") return

    const currentFormData = new FormData(this.formTarget)
    if (this.hasUnsavedChanges(currentFormData)) {
      if (!confirm('You have unsaved changes. Are you sure you want to leave?')) {
        event.preventDefault()
        event.stopImmediatePropagation()
      }
    }
  }

  hasUnsavedChanges(currentFormData) {
    const current = new URLSearchParams(currentFormData).toString()
    const initial = new URLSearchParams(this.initialFormData).toString()
    return current !== initial
  }
}
