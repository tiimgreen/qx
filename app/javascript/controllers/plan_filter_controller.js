import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filter", "row"]

  connect() {
    // Only initialize filter if we have rows
    if (this.hasRowTarget) {
      this.filter()
    }
  }

  filter() {
    // Only filter if we have both filter and rows
    if (!this.hasFilterTarget || !this.hasRowTarget) return

    const selectedType = this.filterTarget.value
    
    this.rowTargets.forEach(row => {
      const workType = row.dataset.workType
      if (selectedType === 'all' || selectedType === workType) {
        row.classList.remove('d-none')
      } else {
        row.classList.add('d-none')
      }
    })
  }
}
