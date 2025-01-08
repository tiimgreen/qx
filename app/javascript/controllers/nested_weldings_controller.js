import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container"]

  connect() {
    if (this.containerTarget.children.length === 0) {
      this.addWelding()
    }
  }

  addWelding(event) {
    if (event) event.preventDefault()
    
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML('beforeend', content)
  }

  removeWelding(event) {
    event.preventDefault()
    const item = event.target.closest('.nested-welding-fields')
    item.remove()
  }
}
