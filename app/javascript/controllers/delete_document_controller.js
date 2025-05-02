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
    this.documentId = button.getAttribute('data-document-id')
    const documentName = button.getAttribute('data-document-name')
    const documentNumber = button.getAttribute('data-document-number')
    
    // Replace placeholders in the translated message
    const message = this.messageValue
      .replace('%{name}', documentName)
      .replace('%{number}', documentNumber || '')
    
    this.messageTarget.textContent = message
  }

  async deleteDocuvitaDocument(event) {
    event.preventDefault()
    
    const locale = document.documentElement.lang || 'en'
    
    try {
      const response = await fetch(`/${locale}/docuvita_documents/${this.documentId}`, {
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