// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import jQuery from "jquery"
import "@popperjs/core"
import * as bootstrap from "bootstrap"
import "highcharts"
import "controllers/language_controller"
import "controllers/nested_form_controller"
import "controllers/image_preview_controller"
import "controllers/modal_controller"

// Initialize Bootstrap
document.addEventListener("turbo:load", () => {
  // Initialize all tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })

  // Initialize all popovers
  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl)
  })

  // Initialize all modals
  const modalTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="modal"]'))
  modalTriggerList.map(function (modalTriggerEl) {
    return new bootstrap.Modal(modalTriggerEl)
  })
})

window.jQuery = jQuery
window.$ = jQuery

// Configure Bootstrap modals globally
bootstrap.Modal.Default.backdrop = false;
