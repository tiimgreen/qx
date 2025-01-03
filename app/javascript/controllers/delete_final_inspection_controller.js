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
    this.final_inspection_id = button.getAttribute('data-final-inspection-id')
    this.projectId = button.getAttribute('data-project-id')
    const final_inspectionName = button.getAttribute('data-final-inspection-name')
    const final_inspectionNumber = button.getAttribute('data-final-inspection-number')
    
    const message = this.messageValue
      .replace('%{name}', final_inspectionName)
      .replace('%{number}', final_inspectionNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteFinalInspection(event) {
    event.preventDefault()
    
    try {
      const currentLocale = window.location.pathname.split('/')[1] || 'de'
      console.log(`/${currentLocale}/projects/${this.projectId}/final_inspections/${this.final_inspection_id}`)
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/final_inspections/${this.final_inspection_id}`, {
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
