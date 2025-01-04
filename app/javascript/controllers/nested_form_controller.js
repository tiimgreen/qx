// app/javascript/controllers/nested_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "fields"]
  
  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.fieldsTarget.insertAdjacentHTML('beforeend', content)
  }
  
  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest('.nested-fields')
    
    if (wrapper.dataset.newRecord) {
      wrapper.remove()
    } else {
      wrapper.querySelector("input[name*='_destroy']").value = 1
      wrapper.style.display = 'none'
    }
  }
}