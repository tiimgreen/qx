import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  connect() {
    this.modal = new Modal(this.element)
  }

  disconnect() {
    if (this.modal) {
      this.modal.dispose()
    }
  }

  close() {
    this.modal.hide()
  }
}
