// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import "@hotwired/turbo-rails";
import "controllers";
import jQuery from "jquery";
import "@popperjs/core";
import * as bootstrap from "bootstrap";
import "controllers/language_controller";
import "controllers/nested_form_controller";
import "controllers/image_preview_controller";
import "controllers/modal_controller";

window.jQuery = jQuery;
window.$ = jQuery;
