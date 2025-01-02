import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = {
    url: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    console.log("WorkPackageSearch controller connected")
    console.log("URL:", this.urlValue)
    console.log("Input target:", this.hasInputTarget)
    console.log("Results target:", this.hasResultsTarget)
    this.resultsTarget.hidden = true
    this.resultsTarget.classList.add("dropdown-menu", "show")
  }

  search(event) {
    console.log("Search triggered:", event.target.value)
    const query = event.target.value

    if (query.length < this.minLengthValue) {
      this.hideResults()
      return
    }

    this.performSearch(query)
  }

  async performSearch(query) {
    try {
      console.log("Fetching from:", this.urlValue)
      const response = await fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      const data = await response.json()
      console.log("Search results:", data)
      
      this.showResults(data)
    } catch (error) {
      console.error("Error fetching work package numbers:", error)
      this.hideResults()
    }
  }

  showResults(items) {
    console.log("Showing results:", items)
    if (!Array.isArray(items) || items.length === 0) {
      this.hideResults()
      return
    }

    this.resultsTarget.innerHTML = items.map(item => `
      <button class="dropdown-item" 
              type="button" 
              data-action="click->work-package-search#select" 
              data-value="${item.value}">
        ${item.label}
      </button>
    `).join("")

    this.resultsTarget.hidden = false
    this.resultsTarget.classList.add("show")
  }

  hideResults() {
    this.resultsTarget.hidden = true
    this.resultsTarget.classList.remove("show")
  }

  select(event) {
    const selectedValue = event.currentTarget.dataset.value
    this.inputTarget.value = selectedValue
    this.hideResults()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}
