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
    this.deliveryId = button.getAttribute('data-incoming-delivery-id')
    this.projectId = button.getAttribute('data-project-id')
    const deliveryName = button.getAttribute('data-incoming-delivery-name')
    const deliveryNumber = button.getAttribute('data-incoming-delivery-number')
    
    const message = this.messageValue
      .replace('%{name}', deliveryName)
      .replace('%{number}', deliveryNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteIncomingDelivery(event) {
    event.preventDefault()
    
    try {
      const response = await fetch(`/de/projects/${this.projectId}/incoming_deliveries/${this.deliveryId}`, {
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
