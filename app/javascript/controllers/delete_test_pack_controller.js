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
    this.test_pack_id = button.getAttribute('data-test-pack-id')
    this.projectId = button.getAttribute('data-project-id')
    const test_packName = button.getAttribute('data-test-pack-name')
    const test_packNumber = button.getAttribute('data-test-pack-number')
    
    const message = this.messageValue
      .replace('%{name}', test_packName)
      .replace('%{number}', test_packNumber)
    
    this.messageTarget.textContent = message
  }

  async deleteTestPack(event) {
    event.preventDefault()
    
    try {
      const currentLocale = window.location.pathname.split('/')[1] || 'de'
      console.log(`/${currentLocale}/projects/${this.projectId}/test_packs/${this.test_pack_id}`)
      const response = await fetch(`/${currentLocale}/projects/${this.projectId}/test_packs/${this.test_pack_id}`, {
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
