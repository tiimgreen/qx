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
    this.on_site_id = button.getAttribute('data-on-site-id')
    this.projectId = button.getAttribute('data-project-id')
    const on_siteName = button.getAttribute('data-on-site-name')
    const on_siteNumber = button.getAttribute('data-on-site-number')
    
    const message = this.messageValue
      .replace('%{name}', on_siteName)
      .replace('%{number}', on_siteNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteOnSite(event) {
    event.preventDefault()
    
    try {
      const currentLocale = window.location.pathname.split('/')[1] || 'de'
      console.log(`/${currentLocale}/projects/${this.projectId}/on_sites/${this.on_site_id}`)
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/on_sites/${this.on_site_id}`, {
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
