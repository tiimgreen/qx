import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = {
    expanded: { type: Boolean, default: false }
  }

  connect() {
    if (!this.expandedValue) {
      this.contentTarget.classList.add('d-none')
    }
  }

  toggle() {
    this.contentTarget.classList.toggle('d-none')
    this.expandedValue = !this.expandedValue
    
    // Toggle icon
    const icon = this.element.querySelector('.toggle-icon')
    icon.classList.toggle('bi-chevron-down')
    icon.classList.toggle('bi-chevron-up')
  }
}
