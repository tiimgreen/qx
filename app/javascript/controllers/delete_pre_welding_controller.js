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
    this.pre_welding_id = button.getAttribute('data-pre-welding-id')
    this.projectId = button.getAttribute('data-project-id')
    const pre_weldingName = button.getAttribute('data-pre-welding-name')
    const pre_weldingNumber = button.getAttribute('data-pre-welding-number')
    
    const message = this.messageValue
      .replace('%{name}', pre_weldingName)
      .replace('%{number}', pre_weldingNumber)
    
    this.messageTarget.textContent = message
  }

  async deletePreWelding(event) {
    event.preventDefault()
    
    try {
      const currentLocale = window.location.pathname.split('/')[1] || 'de'
      console.log(`/${currentLocale}/projects/${this.projectId}/pre_weldings/${this.pre_welding_id}`)
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/pre_weldings/${this.pre_welding_id}`, {
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
