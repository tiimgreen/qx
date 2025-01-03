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
    this.prefabricationId = button.getAttribute('data-prefabrication-id')
    this.projectId = button.getAttribute('data-project-id')
    const prefabricationName = button.getAttribute('data-prefabrication-name')
    const prefabricationNumber = button.getAttribute('data-prefabrication-number')
    
    const message = this.messageValue
      .replace('%{name}', prefabricationName)
      .replace('%{number}', prefabricationNumber)
    
    this.messageTarget.textContent = message
  }

  async deletePrefabrication(event) {
    event.preventDefault()
    
    try {
      const currentLocale = window.location.pathname.split('/')[1] || 'de'
      console.log(`/${currentLocale}/projects/${this.projectId}/prefabrications/${this.prefabricationId}`)
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/prefabrications/${this.prefabricationId}`, {
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
