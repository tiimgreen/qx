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
    this.toggleSectors()
    this.updateFilterOptions()
  }

  toggleSectors(event) {
    const isWorkshop = this.element.querySelector('input[type="checkbox"]').checked
    
    // Toggle sector selection for workshop projects
    this.sectorSelectTarget.style.display = isWorkshop ? 'block' : 'none'
    
    if (event) {
      // Update filter dropdowns
      this.updateFilterOptions()
      
      // Clear selections when switching types
      if (isWorkshop) {
        this.sollistFilter2Target.value = ''
        this.sollistFilter3Target.value = ''
        this.progressFilter1Target.value = ''
        this.progressFilter2Target.value = ''
      } else {
        this.sectorsTarget.selectedIndex = -1
      }
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
      const currentValue = select.value
      select.innerHTML = ''
      
      // Add blank option
      const blankOption = document.createElement('option')
      blankOption.value = ''
      blankOption.text = 'Select Filter'
      select.appendChild(blankOption)
      
      if (isWorkshop) {
        // For workshop projects, only show selected sectors
        const selectedSectors = Array.from(this.sectorsTarget.selectedOptions)
        selectedSectors.forEach(option => {
          const newOption = document.createElement('option')
          newOption.value = option.value
          newOption.text = option.text
          select.appendChild(newOption)
        })
      } else {
        // For general projects, show all sectors except 'project'
        Array.from(this.sectorsTarget.options).forEach(option => {
          if (option.value !== 'project') {
            const newOption = document.createElement('option')
            newOption.value = option.value
            newOption.text = option.text
            select.appendChild(newOption)
          }
        })
      }
      
      // Restore previous value if it exists in new options
      if (Array.from(select.options).some(opt => opt.value === currentValue)) {
        select.value = currentValue
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