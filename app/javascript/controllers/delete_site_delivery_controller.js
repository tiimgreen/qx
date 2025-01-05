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
    this.site_delivery_id = button.getAttribute('data-site-delivery-id')
    this.projectId = button.getAttribute('data-project-id')
    const site_deliveryName = button.getAttribute('data-site-delivery-name')
    const site_deliveryNumber = button.getAttribute('data-site-delivery-number')
    
    const message = this.messageValue
      .replace('%{name}', site_deliveryName)
      .replace('%{number}', site_deliveryNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteSiteDelivery(event) {
    event.preventDefault()
    
    try {
      const currentLocale = window.location.pathname.split('/')[1] || 'de'
      console.log(`/${currentLocale}/projects/${this.projectId}/site_deliveries/${this.site_delivery_id}`)
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/site_deliveries/${this.site_delivery_id}`, {
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
