import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filter", "row"]

  connect() {
    // Initial filter state
    this.filter()
  }

  filter() {
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
