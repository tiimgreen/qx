import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 15000 }
  }

  connect() {
    this.lastData = new FormData(this.element)
    this.startAutoSave()
    this.setupBeforeUnload()
  }

  disconnect() {
    this.stopAutoSave()
    window.removeEventListener('beforeunload', this.beforeUnloadHandler)
  }

  startAutoSave() {
    this.timer = setInterval(() => {
      this.autoSave()
    }, this.intervalValue)
  }

  stopAutoSave() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  formDataChanged(currentFormData) {
    const current = new URLSearchParams(currentFormData).toString()
    const last = new URLSearchParams(this.lastData).toString()
    return current !== last
  }

  async autoSave() {
    const currentFormData = new FormData(this.element)
  
    // Remove welding fields from autosave
    const autosaveFormData = new FormData()
    for (let [key, value] of currentFormData.entries()) {
      if (!key.includes('weldings_attributes')) {
        autosaveFormData.append(key, value)
      }
    }

  if (this.formDataChanged(autosaveFormData)) {
    try {
      const token = document.querySelector("[name='csrf-token']").content
      const response = await fetch(this.element.action, {
        method: 'POST',
        body: autosaveFormData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": token,
          "X-Requested-With": "XMLHttpRequest"
        },
        credentials: 'same-origin'
      })
        
        const data = await response.json()
        
        if (response.ok) {
          this.lastData = currentFormData
          console.log('Autosaved:', data.message)
        } else {
          console.error('Autosave failed:', data.message)
        }
      } catch (error) {
        console.error('Autosave error:', error)
      }
    }
  }

  setupBeforeUnload() {
    this.beforeUnloadHandler = (event) => {
      const currentFormData = new FormData(this.element)
      if (this.formDataChanged(currentFormData)) {
        event.preventDefault()
        event.returnValue = "You have unsaved changes. Are you sure you want to leave?"
      }
    }
    
    window.addEventListener('beforeunload', this.beforeUnloadHandler)
  }
}
