import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = ["message"]
  static values = { message: String }

  connect() {
    this.modal = new bootstrap.Modal(this.element)
    this.element.addEventListener('show.bs.modal', this.handleModalShow.bind(this))
  }

  handleModalShow(event) {
    const button = event.relatedTarget
    this.deliveryItemId = button.getAttribute('data-delivery-item-id')
    this.projectId = button.getAttribute('data-project-id')
    this.incomingDeliveryId = button.getAttribute('data-incoming-delivery-id')
    const itemName = button.getAttribute('data-delivery-item-name')
    const itemNumber = button.getAttribute('data-delivery-item-number')
    
    const message = this.messageValue
      .replace('%{name}', itemName)
      .replace('%{number}', itemNumber)
    
    this.messageTarget.textContent = message
  }

  async delete(event) {
    event.preventDefault()
    event.stopPropagation()
    
    try {
      const response = await fetch(`/de/projects/${this.projectId}/incoming_deliveries/${this.incomingDeliveryId}/delivery_items/${this.deliveryItemId}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        window.location.reload()
      } else {
        console.error('Delete failed:', response.statusText)
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
