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
    this.projectId = button.getAttribute('data-project-id')
    const projectName = button.getAttribute('data-project-name')
    const projectNumber = button.getAttribute('data-project-number')
    
    // Replace placeholders in the translated message
    const message = this.messageValue
      .replace('%{name}', projectName)
      .replace('%{number}', projectNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteProject(event) {
    event.preventDefault()
    
    try {
      const response = await fetch(`/de/projects/${this.projectId}`, {
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
