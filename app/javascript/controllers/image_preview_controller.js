import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["preview"];

  preview(event) {
    this.clearPreviews();

    Array.from(event.target.files).forEach((file) => {
      if (file) {
        const reader = new FileReader();
        reader.onload = (e) => this.createPreview(e.target.result);
        reader.readAsDataURL(file);
      }
    });
  }

  createPreview(url) {
    const wrapper = document.createElement("div");
    wrapper.classList.add("col-md-3", "mb-3");

    const image = document.createElement("img");
    image.src = url;
    image.classList.add("img-thumbnail");
    image.style.maxHeight = "150px";
    image.style.width = "auto";

    wrapper.appendChild(image);
    this.previewTarget.appendChild(wrapper);
  }

  clearPreviews() {
    this.previewTarget.innerHTML = "";
  }
}
