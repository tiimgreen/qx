import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import html2canvas from "html2canvas"

export default class extends Controller {
  static targets = ["content"]

  addPageNumber(pdf, pageNumber, totalPages) {
    const pageWidth = pdf.internal.pageSize.width
    const pageHeight = pdf.internal.pageSize.height
    const margin = 40
    const text = `${pageNumber} / ${totalPages}`
    
    pdf.setFontSize(10)
    const textWidth = pdf.getTextWidth(text)
    
    pdf.text(
      text,
      pageWidth - margin - textWidth,
      pageHeight - margin
    )
  }

  async export() {
    try {
      // Show loading state
      this.element.classList.add('loading')
      
      // Initialize PDF
      const pdf = new jsPDF('p', 'pt', 'a4')
      const pageWidth = pdf.internal.pageSize.width
      const pageHeight = pdf.internal.pageSize.height
      const margin = 40
      
      // Find chart section and first page table
      const chartSection = this.contentTarget.querySelector('#container').parentElement.parentElement
      const firstPageTable = this.contentTarget.querySelector('.pdf-first-page-table')
      
      // First page - Chart and first 20 rows
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
      
      // Add first page table
      firstPageTable.classList.remove('d-none')
      const firstTableScale = (pageWidth - 2 * margin) / firstPageTable.offsetWidth
      const firstTableCanvas = await html2canvas(firstPageTable, {
        scale: firstTableScale * 1.5,
        useCORS: true,
        logging: false,
        allowTaint: true,
        backgroundColor: '#ffffff'
      })
      firstPageTable.classList.add('d-none')
      
      const firstTableImgData = firstTableCanvas.toDataURL('image/jpeg', 1.0)
      pdf.addImage(
        firstTableImgData,
        'JPEG',
        margin,
        margin + (chartCanvas.height * (pageWidth - 2 * margin)) / chartCanvas.width + 40,
        pageWidth - 2 * margin,
        (firstTableCanvas.height * (pageWidth - 2 * margin)) / firstTableCanvas.width
      )
      
      // Get remaining table sections
      const extraPages = this.contentTarget.querySelectorAll('.pdf-extra-page-table')
      const totalPages = extraPages.length + 1
      
      // Add page number to first page
      this.addPageNumber(pdf, 1, totalPages)
      
      // Process remaining pages
      for (const section of extraPages) {
        // Add new page
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
        
        // Add page number
        const currentPage = Array.from(extraPages).indexOf(section) + 2
        this.addPageNumber(pdf, currentPage, totalPages)
      }

      // Open PDF in new tab
      const pdfOutput = pdf.output('bloburl')
      window.open(pdfOutput, '_blank')
      
      // Hide loading state
      this.element.classList.remove('loading')
    } catch (error) {
      console.error('Error generating PDF:', error)
      this.element.classList.remove('loading')
      alert('Error generating PDF. Please try again.')
    }
  }
}
