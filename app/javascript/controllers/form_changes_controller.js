import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["completeButton", "form"]

  connect() {
    // Store initial form state after a slight delay to ensure all form fields are properly initialized
    setTimeout(() => {
      this.storeInitialState()
    }, 100)
  }

  storeInitialState() {
    this.initialFormState = this.serializeForm()
    this.initialStateStored = true
    // Ensure complete button is visible initially
    if (this.hasCompleteButtonTarget) {
      this.completeButtonTarget.style.display = ''
    }
  }

  serializeForm() {
    const formData = {}
    const elements = this.formTarget.elements

    for (let i = 0; i < elements.length; i++) {
      const element = elements[i]
      if (element.name && !element.disabled) {
        if (element.type === 'checkbox' || element.type === 'radio') {
          formData[element.name] = element.checked
        } else if (element.type === 'select-multiple') {
          formData[element.name] = Array.from(element.options)
            .filter(option => option.selected)
            .map(option => option.value)
        } else if (element.type === 'file') {
          // Skip file inputs as they can't be compared reliably
          continue
        } else {
          formData[element.name] = element.value
        }
      }
    }
    return formData
  }

  checkFormChanges() {
    if (!this.initialStateStored) return

    const currentState = this.serializeForm()
    let hasChanges = false

    for (const [key, value] of Object.entries(currentState)) {
      const initialValue = this.initialFormState[key]
      
      if (Array.isArray(value)) {
        // Handle multi-select
        if (!Array.isArray(initialValue) || 
            value.length !== initialValue.length || 
            !value.every((v, i) => v === initialValue[i])) {
          hasChanges = true
          break
        }
      } else if (value !== initialValue) {
        hasChanges = true
        break
      }
    }

    if (this.hasCompleteButtonTarget) {
      this.completeButtonTarget.style.display = hasChanges ? 'none' : ''
    }
  }
}
