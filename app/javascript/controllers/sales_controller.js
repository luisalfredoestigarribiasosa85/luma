import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lines", "template", "line", "product", "quantity", "unitPrice", "subtotal", "discount", "summaryCount", "summarySubtotal", "summaryTotal", "paymentMethod", "cashBlock", "cashReceived", "changeLabel", "change"]
  static values = { stockLimit: Boolean }

  connect() {
    this.loadCatalog()
    this.nextLineIndex = this.countLines() + 1
    // Si la línea ya viene con un producto elegido (ej. desde "Vender" en /products),
    // precargar precio, stock y subtotal.
    this.productTargets.forEach((select) => {
      if (select.value) this.selectProduct({ currentTarget: select })
    })
    this.toggleCash()
    this.recalculate()
  }

  loadCatalog() {
    const node = document.getElementById("sale-catalog")
    this.catalog = node ? JSON.parse(node.textContent) : []
  }

  countLines() {
    return this.lineTargets.length
  }

  addLine() {
    const content = this.templateTarget.innerHTML.replaceAll(/__INDEX__/g, this.nextLineIndex++)
    this.linesTarget.insertAdjacentHTML("beforeend", content)
    this.recalculate()
  }

  removeLine(event) {
    event.currentTarget.closest("[data-sales-target='line']").remove()
    this.recalculate()
  }

  selectProduct(event) {
    const select = event.currentTarget
    const product = this.findProduct(select.value)
    const line = select.closest("[data-sales-target='line']")
    const priceField = line.querySelector("[data-sales-target='unitPrice']")
    const quantityField = line.querySelector("[data-sales-target='quantity']")
    const stockHint = line.querySelector("[data-sales-target='stockHint']")

    if (product) {
      priceField.value = product.price

      if (this.stockLimitValue) {
        // En ventas no se puede vender más de lo que hay.
        if (product.stock >= 1) {
          quantityField.max = product.stock
          stockHint.textContent = `Stock: ${product.stock} ${product.unit}`
          stockHint.classList.remove("text-alert")
          stockHint.classList.add("text-faint")
        } else {
          quantityField.removeAttribute("max")
          stockHint.textContent = "Sin stock"
          stockHint.classList.remove("text-faint")
          stockHint.classList.add("text-alert")
        }
      } else {
        // En compras no se limita la cantidad: se está reponiendo.
        quantityField.removeAttribute("max")
        stockHint.textContent = `Stock actual: ${product.stock} ${product.unit}`
      }
    } else {
      priceField.value = ""
      quantityField.removeAttribute("max")
      stockHint.textContent = "—"
      stockHint.classList.remove("text-alert")
      stockHint.classList.add("text-faint")
    }
    this.recalculate()
  }

  toggleCash() {
    if (!this.hasCashBlockTarget || !this.hasPaymentMethodTarget) return
    this.cashBlockTarget.classList.toggle("hidden", this.paymentMethodTarget.value !== "cash")
    this.recalculate()
  }

  recalculate() {
    let subtotal = 0
    let count = 0

    this.lineTargets.forEach((line) => {
      const quantity = parseFloat(line.querySelector("[data-sales-target='quantity']").value) || 0
      const price = parseFloat(line.querySelector("[data-sales-target='unitPrice']").value) || 0
      const lineTotal = quantity * price

      line.querySelector("[data-sales-target='subtotal']").textContent = this.format(lineTotal)
      subtotal += lineTotal

      if (line.querySelector("[data-sales-target='product']").value) count++
    })

    const discount = this.hasDiscountTarget ? (parseFloat(this.discountTarget.value) || 0) : 0
    const total = Math.max(subtotal - discount, 0)

    this.summaryCountTarget.textContent = count
    this.summarySubtotalTarget.textContent = this.format(subtotal)
    this.summaryTotalTarget.textContent = this.format(total)

    if (this.hasCashBlockTarget && this.hasCashReceivedTarget) {
      const received = parseFloat(this.cashReceivedTarget.value) || 0
      const change = received - total
      if (received === 0 || change >= 0) {
        this.changeLabelTarget.textContent = "Vuelto"
        this.changeTarget.textContent = this.format(Math.max(change, 0))
        this.changeTarget.classList.remove("text-alert")
        this.changeTarget.classList.add("text-bronze")
      } else {
        this.changeLabelTarget.textContent = "Faltan"
        this.changeTarget.textContent = this.format(-change)
        this.changeTarget.classList.remove("text-bronze")
        this.changeTarget.classList.add("text-alert")
      }
    }
  }

  findProduct(id) {
    return this.catalog.find((p) => String(p.id) === String(id))
  }

  format(value) {
    const number = new Intl.NumberFormat("es", { minimumFractionDigits: 0, maximumFractionDigits: 2 }).format(value)
    return `Gs. ${number}`
  }
}