import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = ["dialog", "trigger"];

  connect() {
    this.modal = new Modal(this.dialogTarget);
  }

  open(event) {
    event.preventDefault();
    this.modal.show();
  }

  close() {
    this.modal.hide();
  }

  disconnect() {
    this.modal.dispose();
  }

  // Optional: Handle keyboard events
  keyup(event) {
    if (event.code === "Escape") {
      this.close();
    }
  }
}
