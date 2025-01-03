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
    this.work_preparation_id = button.getAttribute('data-work-preparation-id')
    this.projectId = button.getAttribute('data-project-id')
    const work_preparationName = button.getAttribute('data-work-preparation-name')
    const work_preparationNumber = button.getAttribute('data-work-preparation-number')
    
    const message = this.messageValue
      .replace('%{name}', work_preparationName)
      .replace('%{number}', work_preparationNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteWorkPreparation(event) {
    event.preventDefault()
    
    try {
      const currentLocale = window.location.pathname.split('/')[1] || 'de'
      console.log(`/${currentLocale}/projects/${this.projectId}/work_preparations/${this.work_preparation_id}`)
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/work_preparations/${this.work_preparation_id}`, {
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
