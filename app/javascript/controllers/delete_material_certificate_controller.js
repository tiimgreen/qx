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
    this.certificateId = button.getAttribute('data-certificate-id')
    const certificateNumber = button.getAttribute('data-certificate-number')
    
    // Replace placeholder in the translated message
    const message = this.messageValue.replace('%{number}', certificateNumber).replace('%{name}', '')
    this.messageTarget.textContent = message
  }

  async deleteMaterialCertificate(event) {
    event.preventDefault()
    
    try {
      const response = await fetch(`/material_certificates/${this.certificateId}`, {
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
