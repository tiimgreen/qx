import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["user", "resource", "permissions", "submitButton", "spinner", "buttonText", "successMessage"]

  connect() {
    console.log("Permissions form controller connected")
  }

  handleSubmit(event) {
    event.preventDefault()
    
    if (!this.permissionsTarget.value) {
      alert("Please select at least one permission")
      return
    }

    // Show loading state
    this.spinnerTarget.classList.remove('d-none')
    this.buttonTextTarget.textContent = 'Saving...'
    this.submitButtonTarget.disabled = true

    // Get form data
    const formData = new FormData(event.target)

    // Submit the form
    fetch(event.target.action, {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json'
      }
    })
    .then(response => {
      // Reset button state
      this.spinnerTarget.classList.add('d-none')
      this.buttonTextTarget.textContent = 'Save Permissions'
      this.submitButtonTarget.disabled = false

      if (response.ok) {
        // Show success message
        this.successMessageTarget.classList.remove('d-none')
        
        // Hide success message after 3 seconds
        setTimeout(() => {
          this.successMessageTarget.classList.add('d-none')
        }, 3000)
      } else {
        throw new Error('Failed to save permissions')
      }
    })
    .catch(error => {
      // Reset button state
      this.spinnerTarget.classList.add('d-none')
      this.buttonTextTarget.textContent = 'Save Permissions'
      this.submitButtonTarget.disabled = false
      
      // Show error
      alert('Failed to save permissions. Please try again.')
    })
  }
}
