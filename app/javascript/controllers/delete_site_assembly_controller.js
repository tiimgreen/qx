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
    this.site_assembly_id = button.getAttribute('data-site-assembly-id')
    this.projectId = button.getAttribute('data-project-id')
    const site_assemblyName = button.getAttribute('data-site-assembly-name')
    const site_assemblyNumber = button.getAttribute('data-site-assembly-number')
    
    const message = this.messageValue
      .replace('%{name}', site_assemblyName)
      .replace('%{number}', site_assemblyNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteSiteAssembly(event) {
    event.preventDefault()
    
    try {
      const currentLocale = window.location.pathname.split('/')[1] || 'de'
      console.log(`/${currentLocale}/projects/${this.projectId}/site_assemblies/${this.site_assembly_id}`)
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/site_assemblies/${this.site_assembly_id}`, {
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
