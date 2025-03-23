import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "sectorSelect", 
    "sectors",
    "sollistFilter2",
    "sollistFilter3",
    "progressFilter1",
    "progressFilter2"
  ]

  connect() {
    // Ensure filters are populated on initial load
    this.updateFilterOptions()
    this.toggleSectors()
  }

  toggleSectors(event) {
    const isWorkshop = this.element.querySelector('input[type="checkbox"]').checked
    
    // Toggle sector selection for workshop projects
    this.sectorSelectTarget.style.display = isWorkshop ? 'block' : 'none'
    
    if (event) {
      // Clear selections when switching types
      if (isWorkshop) {
        this.sollistFilter2Target.value = ''
        this.sollistFilter3Target.value = ''
        this.progressFilter1Target.value = ''
        this.progressFilter2Target.value = ''
      }
      
      // Update filter dropdowns
      this.updateFilterOptions()
    }
  }

  updateFilterOptions() {
    const isWorkshop = this.element.querySelector('input[type="checkbox"]').checked
    const filterTargets = [
      this.sollistFilter2Target,
      this.sollistFilter3Target,
      this.progressFilter1Target,
      this.progressFilter2Target
    ]
    
    filterTargets.forEach(select => {
      // Get preselected value from data attribute
      const selectedValue = select.dataset.selectedValue
      
      select.innerHTML = ''
      
      // Add blank option
      const blankOption = document.createElement('option')
      blankOption.value = ''
      // blankOption.text = 'Select Filter'
      select.appendChild(blankOption)
      
      if (isWorkshop) {
        // For workshop projects, only show selected sectors except Isometry and Incoming Delivery
        const selectedSectors = Array.from(this.sectorsTarget.selectedOptions)
        selectedSectors.forEach(option => {
          // Skip Isometry and Incoming Delivery for dropdown filters
          if (!['isometry', 'incoming_delivery'].includes(option.dataset.sectorKey)) {
            const newOption = document.createElement('option')
            newOption.value = option.value
            newOption.text = option.text
            select.appendChild(newOption)
          }
        })
      } else {
        // For general projects, show all sectors except 'project', 'isometry', and 'incoming_delivery'
        Array.from(this.sectorsTarget.options).forEach(option => {
          if (option.dataset.isProjectSector !== 'true' && 
              !['isometry', 'incoming_delivery'].includes(option.dataset.sectorKey)) {
            const newOption = document.createElement('option')
            newOption.value = option.value
            newOption.text = option.text
            select.appendChild(newOption)
          }
        })
      }
      
      // Restore selected value if it exists in new options
      if (selectedValue && Array.from(select.options).some(opt => opt.value === selectedValue)) {
        select.value = selectedValue
      }
    })
  }

  // Add event listener for sector selection changes in workshop mode
  sectorChange() {
    if (this.element.querySelector('input[type="checkbox"]').checked) {
      this.updateFilterOptions()
    }
  }
}