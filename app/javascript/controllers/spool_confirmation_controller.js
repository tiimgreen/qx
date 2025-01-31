import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submitButton", "completeButton"]

  connect() {
    if (this.hasCheckboxTarget) {
      this.updateButtons()
    }
  }

  updateButtons() {
    if (this.hasCheckboxTarget) {
      const isChecked = this.checkboxTarget.checked
      
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = !isChecked
      }
      
      if (this.hasCompleteButtonTarget) {
        this.completeButtonTarget.classList.toggle('d-none', !isChecked)

      }
    }
  }
}
