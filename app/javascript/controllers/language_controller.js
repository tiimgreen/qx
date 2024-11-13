import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", this.persistLanguage);
  }

  persistLanguage(event) {
    if (event.target.classList.contains("dropdown-item")) {
      localStorage.setItem(
        "preferredLanguage",
        event.target.getAttribute("href").split("locale=")[1]
      );
    }
  }
}
