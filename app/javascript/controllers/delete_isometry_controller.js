import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static targets = ["message"]
  static values = { message: String }

  connect() {
    this.modal = new Modal(this.element)
    this.element.addEventListener('show.bs.modal', this.handleModalShow.bind(this))
  }

  handleModalShow(event) {
    const button = event.relatedTarget
    this.isometryId = button.getAttribute('data-isometry-id')
    const isometryName = button.getAttribute('data-isometry-name')
    const isometryNumber = button.getAttribute('data-isometry-number')
    this.projectId = button.getAttribute('data-project-id')
    
    const message = this.messageValue
      .replace('%{name}', isometryName)
      .replace('%{number}', isometryNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteIsometry(event) {
    event.preventDefault()
    
    try {
      const currentLocale = document.documentElement.lang || 'en'
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/isometries/${this.isometryId}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        redirect: 'follow'
      })

      if (response.redirected) {
        window.location.href = response.url
      } else {
        window.location.reload()
      }
    } catch (error) {
      console.error('Delete error:', error)
    }
  }

  disconnect() {
    if (this.modal) {
      this.modal.dispose()
    }
  }
}
