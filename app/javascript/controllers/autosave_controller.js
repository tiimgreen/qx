import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 300000 } // 5 minutes in milliseconds
  }

  connect() {
    if (this.element.tagName !== 'FORM') return
    
    this.form = this.element

    const formId = this.findFormId()
    
    if (!formId) {
      console.log("No form ID found, skipping autosave initialization")
      return
    }

    this.lastData = new FormData(this.form)
    this.startAutoSaveCheck()
    this.setupBeforeUnload()
  }

  findFormId() {
    const pathParts = window.location.pathname.split('/')
    const idFromPath = pathParts[pathParts.length - 2]
    if (idFromPath && !isNaN(idFromPath)) {
      return idFromPath
    }

    if (this.form?.action) {
      const actionMatch = this.form.action.match(/\/isometries\/(\d+)/)
      if (actionMatch) {
        return actionMatch[1]
      }
    }

    return null
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
    window.removeEventListener('beforeunload', this.beforeUnloadHandler)
  }

  startAutoSaveCheck() {
    this.timer = setInterval(() => {
      this.checkForChanges()
    }, this.intervalValue)
  }

  formDataChanged(currentFormData) {
    const current = Array.from(currentFormData.entries())
      .filter(([key, value]) => value !== '' && !key.includes('weldings_attributes'))
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(entry => entry.join('='))
      .join('&')

    const last = Array.from(this.lastData.entries())
      .filter(([key, value]) => value !== '' && !key.includes('weldings_attributes'))
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(entry => entry.join('='))
      .join('&')

    const hasChanged = current !== last && current !== ''

    return hasChanged
  }

  checkForChanges() {
    if (!this.form) return
    
    const now = new Date()
    const formattedTime = now.toLocaleString('en-US', { 
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false 
    })
    const currentFormData = new FormData(this.form)
    if (this.formDataChanged(currentFormData)) {
      console.log(`Changes detected at ${formattedTime}`)
      this.showConfirmation()
    } else {
      console.log(`No changes detected at ${formattedTime}`)
    }
  }

  showConfirmation() {
    if (confirm("You have unsaved changes. Would you like to save them now?")) {
      this.save()
    }
  }

  async save() {
    if (!this.form) {
      return
    }
    
    const formId = this.findFormId()
    
    if (!formId) {
      console.error("No form ID found for saving")
      return
    }
    
    const formData = new FormData(this.form)
    
    // Create a new FormData without empty values and welding fields
    const saveData = new FormData()
    for (let [key, value] of formData.entries()) {
      if (value !== '' && !key.includes('weldings_attributes')) {
        saveData.append(key, value)
      }
    }

    try {
      const response = await fetch(this.form.action, {
        method: 'PATCH',
        body: saveData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      const responseData = await response.json()

      if (response.ok) {
      } else {
        alert("Failed to save changes. Please try again.")
      }
    } catch (error) {
      console.error('Save failed:', error)
      alert("Failed to save changes. Please try again.")
    }
  }

  setupBeforeUnload() {
    this.beforeUnloadHandler = (event) => {
      if (this.formDataChanged(new FormData(this.form))) {
        event.preventDefault()
        event.returnValue = "You have unsaved changes. Are you sure you want to leave?"
      }
    }
    window.addEventListener('beforeunload', this.beforeUnloadHandler)
  }
}
