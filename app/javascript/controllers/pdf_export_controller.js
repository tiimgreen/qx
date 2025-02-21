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
      
      // Find chart section
      const chartSection = this.contentTarget.querySelector('#container').parentElement.parentElement
      
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
      
      // Get all pre-split table sections
      const tableSections = this.contentTarget.querySelectorAll('.pdf-table-section')
      
      // Process each table section
      for (const section of tableSections) {
        // Add new page for table
        pdf.addPage()
        
        // Make section visible temporarily for capture
        section.classList.remove('d-none')
        
        // Capture this section of the table
        const tableScale = (pageWidth - 2 * margin) / section.offsetWidth
        const tableCanvas = await html2canvas(section, {
          scale: tableScale * 1.5,
          useCORS: true,
          logging: false,
          allowTaint: true,
          backgroundColor: '#ffffff'
        })
        
        // Hide section again
        section.classList.add('d-none')
        
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
