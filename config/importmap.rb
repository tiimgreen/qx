# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js"
pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/dist/esm/index.js"
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.3.2/dist/js/bootstrap.esm.js"
pin "flag-icons", to: "flag-icons.js"

# Charting
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"
pin "@hotwired/turbo", to: "turbo.min.js"
pin "@rails/actioncable", to: "actioncable.esm.js"

# PDF Export
pin "jspdf", to: "https://cdn.skypack.dev/jspdf"
pin "html2canvas", to: "https://cdn.skypack.dev/html2canvas"
