import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.initializeChart()
  }

  initializeChart() {
    const chartData = JSON.parse(this.element.dataset.chart)
    const chart = Highcharts.chart(this.element, chartData)
  }
}
