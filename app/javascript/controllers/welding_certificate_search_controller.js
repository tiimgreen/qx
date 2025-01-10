import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["batchNumber", "certificateId", "searchResults"]
  static values = {
    searchUrl: String,
    field: String
  }

  connect() {
    // Store initial values
    this.originalBatchNumber = this.batchNumberTarget.value
    this.originalCertificateId = this.certificateIdTarget.value
  }

  updateFromWelding(event) {
    const weldingId = event.target.value
    if (!weldingId) {
      this.clearFields()
      return
    }

    // Fetch welding details including its material certificate
    fetch(`/weldings/${weldingId}`, {
      headers: {
        "Accept": "application/json"
      }
    })
    .then(response => response.json())
    .then(welding => {
      const row = event.target.closest('.nested-welding-fields')
      if (!row) return

      // Update batch number fields in this row
      const batchNumberField = row.querySelector('[data-welding-certificate-search-target="batchNumber"][data-field="batch_number"]')
      const batchNumber1Field = row.querySelector('[data-welding-certificate-search-target="batchNumber"][data-field="batch_number1"]')
      const certificateIdField = row.querySelector('[data-welding-certificate-search-target="certificateId"][data-field="batch_number"]')
      const certificateId1Field = row.querySelector('[data-welding-certificate-search-target="certificateId"][data-field="batch_number1"]')

      if (batchNumberField) {
        batchNumberField.value = welding.batch_number || ''
        certificateIdField.value = welding.material_certificate_id || ''
      }
      if (batchNumber1Field) {
        batchNumber1Field.value = welding.batch_number1 || ''
        certificateId1Field.value = welding.material_certificate1_id || ''
      }
    })
  }

  search() {
    const query = this.batchNumberTarget.value
    if (!query) {
      this.searchResultsTarget.innerHTML = ''
      return
    }

    fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
      headers: {
        "Accept": "application/json"
      }
    })
    .then(response => response.json())
    .then(data => this.showResults(data))
  }

  clearFields() {
    const row = this.element.closest('.nested-welding-fields')
    if (!row) return

    row.querySelectorAll('[data-welding-certificate-search-target="batchNumber"]').forEach(field => {
      field.value = ''
    })
    row.querySelectorAll('[data-welding-certificate-search-target="certificateId"]').forEach(field => {
      field.value = ''
    })
  }

  showResults(certificates) {
    if (!certificates.length) {
      this.searchResultsTarget.innerHTML = '<div class="list-group"><div class="list-group-item">No results found</div></div>'
      return
    }

    const html = `
      <div class="list-group">
        ${certificates.map(cert => `
          <button type="button" class="list-group-item list-group-item-action"
                  data-action="click->welding-certificate-search#selectFromList"
                  data-certificate='${JSON.stringify(cert)}'>
            ${cert.batch_number} - ${cert.certificate_number}
          </button>
        `).join('')}
      </div>
    `
    this.searchResultsTarget.innerHTML = html
  }

  selectFromList(event) {
    event.preventDefault()
    const certificate = JSON.parse(event.target.dataset.certificate)
    this.selectCertificate(certificate)
  }

  selectCertificate(certificate) {
    const field = this.fieldValue || 'batch_number'
    const row = this.element.closest('.nested-welding-fields')
    if (!row) return

    const batchNumberField = row.querySelector(`[data-welding-certificate-search-target="batchNumber"][data-field="${field}"]`)
    const certificateIdField = row.querySelector(`[data-welding-certificate-search-target="certificateId"][data-field="${field}"]`)

    if (batchNumberField) batchNumberField.value = certificate.batch_number
    if (certificateIdField) certificateIdField.value = certificate.id

    this.searchResultsTarget.innerHTML = ''
  }
}