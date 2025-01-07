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
    this.transportId = button.getAttribute('data-transport-id')
    this.projectId = button.getAttribute('data-project-id')
    const transportName = button.getAttribute('data-transport-name')
    const transportNumber = button.getAttribute('data-transport-number')
    
    const message = this.messageValue
      .replace('%{name}', transportName)
      .replace('%{number}', transportNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteTransport(event) {
    event.preventDefault()
    
    try {
      const currentLocale = window.location.pathname.split('/')[1] || 'de'
      console.log(`/${currentLocale}/projects/${this.projectId}/transports/${this.transportId}`)
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/transports/${this.transportId}`, {
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
