import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import html2canvas from "html2canvas"

export default class extends Controller {
  static targets = ["content"]

  async export() {
    try {
      // Show loading state
      this.element.classList.add('loading')
      
      // Initialize PDF
      const pdf = new jsPDF('p', 'pt', 'a4')
      const pageWidth = pdf.internal.pageSize.width
      const pageHeight = pdf.internal.pageSize.height
      const margin = 40
      
      // Find chart and table elements
      const chartSection = this.contentTarget.querySelector('#container').parentElement.parentElement
      const tableSection = this.contentTarget.querySelector('.table-responsive')
      
      // First page - Chart and header
      const chartScale = (pageWidth - 2 * margin) / chartSection.offsetWidth
      const chartCanvas = await html2canvas(chartSection, {
        scale: chartScale * 1.5,
        useCORS: true,
        logging: false,
        allowTaint: true,
        backgroundColor: '#ffffff'
      })

      // Add chart to first page
      const chartImgData = chartCanvas.toDataURL('image/jpeg', 1.0)
      pdf.addImage(
        chartImgData,
        'JPEG',
        margin,
        margin,
        pageWidth - 2 * margin,
        (chartCanvas.height * (pageWidth - 2 * margin)) / chartCanvas.width
      )
      
      // Get all table rows
      const rows = tableSection.querySelectorAll('tr')
      const rowsPerPage = 30
      const totalPages = Math.ceil((rows.length - 1) / rowsPerPage) // -1 for header
      
      // Create temporary container for table sections
      const tempContainer = document.createElement('div')
      tempContainer.style.position = 'absolute'
      tempContainer.style.left = '-9999px'
      document.body.appendChild(tempContainer)
      
      // For each page of the table
      for (let page = 0; page < totalPages; page++) {
        // Create a new table for this page
        const tableClone = tableSection.cloneNode(true)
        const allRows = [...tableClone.querySelectorAll('tr')]
        
        // Keep header and current page rows
        const startRow = page * rowsPerPage + 1 // +1 to skip header
        const endRow = Math.min(startRow + rowsPerPage, rows.length)
        
        // Remove rows we don't want on this page
        allRows.forEach((row, index) => {
          if (index !== 0 && (index < startRow || index >= endRow)) {
            row.remove()
          }
        })
        
        // Add to temp container and render
        tempContainer.innerHTML = ''
        tempContainer.appendChild(tableClone)
        
        // Add new page for table
        pdf.addPage()
        
        // Capture this section of the table
        const tableScale = (pageWidth - 2 * margin) / tableClone.offsetWidth
        const tableCanvas = await html2canvas(tableClone, {
          scale: tableScale * 1.5,
          useCORS: true,
          logging: false,
          allowTaint: true,
          backgroundColor: '#ffffff'
        })
        
        const tableImgData = tableCanvas.toDataURL('image/jpeg', 1.0)
        pdf.addImage(
          tableImgData,
          'JPEG',
          margin,
          margin,
          pageWidth - 2 * margin,
          (tableCanvas.height * (pageWidth - 2 * margin)) / tableCanvas.width
        )
      }
      
      // Clean up temporary container
      document.body.removeChild(tempContainer)
      
      // Save the PDF with a clean date format
      pdf.save(`progress_tracking_${new Date().toISOString().split('T')[0]}.pdf`)
      
      // Hide loading state
      this.element.classList.remove('loading')
    } catch (error) {
      console.error('Error generating PDF:', error)
      this.element.classList.remove('loading')
      alert('Error generating PDF. Please try again.')
    }
  }
}
