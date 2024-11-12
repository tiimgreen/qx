// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import jQuery from "jquery";
import * as bootstrap from "bootstrap";

// Make jQuery available globally
window.jQuery = jQuery;
window.$ = jQuery;
