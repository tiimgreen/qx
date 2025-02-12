import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import html2canvas from "html2canvas"

export default class extends Controller {
  static targets = ["content"]

  async export() {
    try {
      // Show loading state
      this.element.classList.add('loading')

      const element = this.contentTarget
      const canvas = await html2canvas(element, {
        scale: 2,
        useCORS: true,
        logging: true
      })

      const imgData = canvas.toDataURL('image/jpeg', 0.98)

      // Create PDF in landscape A4
      const pdf = new jsPDF({
        orientation: 'landscape',
        unit: 'mm',
        format: 'a4'
      })

      const imgProps = pdf.getImageProperties(imgData)
      const pdfWidth = pdf.internal.pageSize.getWidth()
      const pdfHeight = pdf.internal.pageSize.getHeight()
      const imgWidth = imgProps.width
      const imgHeight = imgProps.height

      // Calculate scaling to fit the page while maintaining aspect ratio
      const ratio = Math.min(pdfWidth / imgWidth, pdfHeight / imgHeight)
      const scaledWidth = imgWidth * ratio
      const scaledHeight = imgHeight * ratio
      const x = (pdfWidth - scaledWidth) / 2
      const y = (pdfHeight - scaledHeight) / 2

      pdf.addImage(imgData, 'JPEG', x, y, scaledWidth, scaledHeight)
      // Create Blob and open in new tab
      const pdfOutput = pdf.output('blob')
      const blobUrl = URL.createObjectURL(pdfOutput)
      window.open(blobUrl, '_blank')
      
      // Clean up the Blob URL after the window opens
      setTimeout(() => URL.revokeObjectURL(blobUrl), 100)
    } catch (error) {
      console.error('PDF generation failed:', error)
    } finally {
      this.element.classList.remove('loading')
    }
  }
}
