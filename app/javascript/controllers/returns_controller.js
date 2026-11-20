import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["qty", "unitPrice", "lineTotal", "total"]

  connect() {
    this.recalculate()
  }

  recalculate() {
    let total = 0

    this.qtyTargets.forEach((input, i) => {
      const qty = parseFloat(input.value) || 0
      const price = parseFloat(this.unitPriceTargets[i].value) || 0
      const lineTotal = qty * price
      total += lineTotal
      if (this.lineTotalTargets[i]) {
        this.lineTotalTargets[i].textContent = this.format(lineTotal)
      }
    })

    this.totalTarget.textContent = this.format(total)
  }

  format(value) {
    return `Gs. ${new Intl.NumberFormat("es", { minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(value)}`
  }
}
