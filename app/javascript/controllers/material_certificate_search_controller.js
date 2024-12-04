import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "results", "selected"]

  connect() {
    console.log("Controller connected");
    this.searchTimeout = null;
    // Log the search target and its dataset on connect
    console.log("Search target:", this.searchTarget);
    console.log("Search target dataset:", this.searchTarget.dataset);
  }

  search() {
    clearTimeout(this.searchTimeout);
    const query = this.searchTarget.value.trim();
    
    // Debug logging
    console.log("Search query:", query);
    console.log("Search target:", this.searchTarget);
    console.log("Search URL from dataset:", this.searchTarget.getAttribute("data-material-certificate-search-url"));
    
    if (query.length < 2) {
      this.resultsTarget.innerHTML = '';
      return;
    }

    this.searchTimeout = setTimeout(() => {
      // Get URL from data attribute
      const searchUrl = this.searchTarget.getAttribute("data-material-certificate-search-url");
      
      if (!searchUrl) {
        console.error('Search URL not found in:', this.searchTarget.dataset);
        return;
      }

      const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
      
      // Debug log the full URL being fetched
      const fullUrl = `${searchUrl}?q=${encodeURIComponent(query)}`;
      console.log('Fetching URL:', fullUrl);

      fetch(fullUrl, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken,
          'X-Requested-With': 'XMLHttpRequest'
        },
        credentials: 'same-origin'
      })
      .then(response => {
        if (!response.ok) throw new Error(`Network response was not ok: ${response.status}`);
        return response.json();
      })
      .then(data => {
        console.log('Received data:', data);
        this.showResults(data);
      })
      .catch(error => {
        console.error('Error:', error);
        this.resultsTarget.innerHTML = '<div class="alert alert-danger">Error loading results</div>';
      });
    }, 300);
  }

  showResults(certificates) {
    if (!Array.isArray(certificates)) {
      console.error('Expected array of certificates, got:', certificates);
      return;
    }

    this.resultsTarget.innerHTML = certificates.map(cert => `
      <button type="button" 
              class="list-group-item list-group-item-action" 
              data-action="click->material-certificate-search#selectCertificate"
              data-certificate-id="${cert.id}"
              data-certificate-number="${cert.certificate_number}"
              data-batch-number="${cert.batch_number}">
        ${cert.certificate_number} - ${cert.batch_number}
      </button>
    `).join('');
  }

  selectCertificate(event) {
    const button = event.currentTarget;
    const certificateId = button.dataset.certificateId;
    const certificateNumber = button.dataset.certificateNumber;
    const batchNumber = button.dataset.batchNumber;

    if (!this.selectedTarget.querySelector(`[data-certificate-id="${certificateId}"]`)) {
      const certificateElement = document.createElement('div');
      certificateElement.className = 'selected-certificate mb-2';
      certificateElement.dataset.certificateId = certificateId;
      certificateElement.innerHTML = `
        <input type="hidden" name="isometry[material_certificate_ids][]" value="${certificateId}">
        <div class="d-flex align-items-center">
          <span class="me-2">${certificateNumber} - ${batchNumber}</span>
          <button type="button" class="btn btn-sm btn-danger remove-certificate" data-action="click->material-certificate-search#removeCertificate">×</button>
        </div>
      `;
      this.selectedTarget.appendChild(certificateElement);
    }

    this.searchTarget.value = '';
    this.resultsTarget.innerHTML = '';
  }

  removeCertificate(event) {
    const button = event.currentTarget;
    const certificateElement = button.closest('.selected-certificate');
    certificateElement.remove();
  }
}