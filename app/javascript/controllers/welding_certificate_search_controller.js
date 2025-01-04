import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["batchNumber", "certificateId", "searchResults"]
  static values = {
    searchUrl: String
  }

  search() {
    const query = this.batchNumberTarget.value
    if (!query) {
      this.clearSelection()  // Called without event
      return
    }

    fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
      headers: {
        "Accept": "application/json"
      }
    })
    .then(response => response.json())
    .then(data => {
      const exactMatch = data.find(cert => cert.batch_number.toLowerCase() === query.toLowerCase())
      
      if (exactMatch) {
        this.selectCertificate(exactMatch)
      } else {
        this.clearSelection()  // Called without event
        
        if (data.length > 0) {
          this.showResults(data)
        } else {
          this.searchResultsTarget.innerHTML = `
            <div class="alert alert-warning">
              <small>No certificates found</small>
            </div>
          `
        }
      }
    })
  }

  clearSelection(event = null) {  // Make event parameter optional
    if (event) {
      event.preventDefault()
    }
    this.certificateIdTarget.value = ""
    this.batchNumberTarget.value = ""
    this.searchResultsTarget.innerHTML = ""
  }

  // Rest of the controller remains the same...
  selectCertificate(certificate) {
    this.certificateIdTarget.value = certificate.id
    this.batchNumberTarget.value = certificate.batch_number
    this.searchResultsTarget.innerHTML = `
      <div class="alert alert-success">
        <small>
          ${certificate.certificate_number} (${certificate.batch_number})
          <a href="#" data-action="click->welding-certificate-search#clearSelection" class="float-end text-danger">
            <i class="bi bi-x"></i>
          </a>
        </small>
      </div>
    `
  }

  showResults(certificates) {
    if (certificates.length === 0) {
      this.searchResultsTarget.innerHTML = `
        <div class="alert alert-warning">
          <small>No certificates found</small>
        </div>
      `
      return
    }

    const html = certificates.map(cert => `
      <a href="#" class="list-group-item list-group-item-action py-1" 
         data-action="click->welding-certificate-search#selectFromList"
         data-certificate='${JSON.stringify(cert)}'>
        <small>${cert.certificate_number} (${cert.batch_number})</small>
      </a>
    `).join("")

    this.searchResultsTarget.innerHTML = `
      <div class="list-group position-absolute w-100 shadow-sm" style="z-index: 1000">
        ${html}
      </div>
    `
  }

  selectFromList(event) {
    event.preventDefault()
    const certificate = JSON.parse(event.currentTarget.dataset.certificate)
    this.selectCertificate(certificate)
  }
}