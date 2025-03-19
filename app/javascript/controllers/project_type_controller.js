import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sectorSelect", "sectors"]

  connect() {
    this.toggleSectors()
  }

  toggleSectors() {
    const isWorkshop = this.element.querySelector('input[type="checkbox"]').checked
    this.sectorSelectTarget.style.display = isWorkshop ? "block" : "none"
    
    if (!isWorkshop) {
      // Clear selections when workshop is unchecked
      this.sectorsTarget.selectedIndex = -1
    }
  }
}