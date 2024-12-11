import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = ["message", "button"]
  static values = { message: String }

  connect() {
    if (this.element) {
      this.modal = new bootstrap.Modal(this.element)
    }
  }

  handleModalShow(event) {
    const button = event.relatedTarget
    if (!button) {
      console.error('No button found in event')
      return
    }
    
    this.deliveryItemId = button.getAttribute('data-delivery-item-id')
    this.projectId = button.getAttribute('data-project-id')
    this.incomingDeliveryId = button.getAttribute('data-incoming-delivery-id')
    const itemName = button.getAttribute('data-delivery-item-name')
    const itemNumber = button.getAttribute('data-delivery-item-number')
    
    
    if (this.hasMessageTarget) {
      const message = this.messageValue
        .replace('%{name}', itemName)
        .replace('%{number}', itemNumber)
      
      this.messageTarget.textContent = message
    } else {
      console.error('No message target found')
    }
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
