import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["template", "fields"];

  remove(event) {
    event.preventDefault();
    const wrapper = event.target.closest(".nested-fields");

    if (wrapper.dataset.newRecord == "true") {
      wrapper.remove();
    } else {
      wrapper.style.display = "none";
      wrapper.querySelector("input[name*='_destroy']").value = "1";
    }
  }

  add(event) {
    event.preventDefault();
    const content = this.templateTarget.innerHTML.replace(
      /NEW_RECORD/g,
      new Date().getTime()
    );
    this.fieldsTarget.insertAdjacentHTML("beforeend", content);
  }
}
