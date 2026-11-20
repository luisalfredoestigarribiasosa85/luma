import { Controller } from "@hotwired/stimulus"

let uid = 0

export default class extends Controller {
  static targets = ["input", "hidden", "listbox"]

  connect() {
    this.catalog = this.loadCatalog()
    this.matches = []
    this.activeIndex = -1
    this.listboxTarget.id = `picker-listbox-${++uid}`
    this.inputTarget.setAttribute("aria-controls", this.listboxTarget.id)

    if (this.hiddenTarget.value) this.selectById(this.hiddenTarget.value, { initial: true })
  }

  loadCatalog() {
    try {
      const node = document.getElementById("sale-catalog")
      return node ? JSON.parse(node.textContent) : []
    } catch (_e) {
      return []
    }
  }

  normalize(value) {
    return (value || "").toString().toLowerCase()
      .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
  }

  filter() {
    const q = this.normalize(this.inputTarget.value.trim())
    this.matches = q.length === 0
      ? this.catalog.slice(0, 15)
      : this.catalog.filter((p) =>
          this.normalize(p.name).includes(q) || this.normalize(p.sku).includes(q)
        ).slice(0, 15)

    this.activeIndex = this.matches.length > 0 ? 0 : -1
    this.render()
    this.open()
  }

  open() {
    this.listboxTarget.classList.remove("hidden")
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.listboxTarget.classList.add("hidden")
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.activeIndex = -1
  }

  blur() {
    setTimeout(() => this.close(), 150)
  }

  handleKeydown(event) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.moveActive(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveActive(-1)
        break
      case "Enter":
        if (!this.listboxTarget.classList.contains("hidden") && this.activeIndex >= 0) {
          event.preventDefault()
          this.selectByIndex(this.activeIndex)
        } else if (this.matches.length === 1 && this.inputTarget.value.trim().length > 0) {
          // No hay nada que elegir: solo un producto coincide con la búsqueda.
          event.preventDefault()
          this.selectByIndex(0)
        }
        break
      case "Escape":
        this.close()
        break
      case "Tab":
        this.close()
        break
    }
  }

  moveActive(delta) {
    if (this.matches.length === 0) return
    this.activeIndex = (this.activeIndex + delta + this.matches.length) % this.matches.length
    this.render()
    const option = this.listboxTarget.children[this.activeIndex]
    if (option) option.scrollIntoView({ block: "nearest" })
  }

  selectByIndex(index) {
    const product = this.matches[index]
    if (product) this.selectById(product.id)
  }

  selectById(id, { initial = false } = {}) {
    const product = this.catalog.find((p) => String(p.id) === String(id))
    if (!product) return

    this.hiddenTarget.value = product.id
    this.inputTarget.value = product.name
    this.close()

    if (!initial) {
      this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  render() {
    this.listboxTarget.innerHTML = ""

    if (this.matches.length === 0) {
      const empty = document.createElement("li")
      empty.className = "px-3 py-3 text-sm text-muted"
      empty.setAttribute("role", "option")
      empty.setAttribute("aria-disabled", "true")
      empty.textContent = "Sin resultados"
      this.listboxTarget.appendChild(empty)
      return
    }

    this.matches.forEach((product, index) => {
      const option = document.createElement("button")
      option.type = "button"
      option.setAttribute("role", "option")
      option.id = `picker-option-${uid}-${index}`
      option.setAttribute("aria-selected", index === this.activeIndex ? "true" : "false")
      option.className = `flex w-full items-center justify-between gap-3 px-3 py-2 text-left transition cursor-pointer ${
        index === this.activeIndex ? "bg-raise/70" : "hover:bg-raise/50"
      }`
      option.addEventListener("click", () => this.selectByIndex(index))

      const text = document.createElement("span")
      text.className = "min-w-0"

      const name = document.createElement("span")
      name.className = "block truncate text-sm font-medium text-ink"
      name.textContent = product.name
      text.appendChild(name)

      const meta = document.createElement("span")
      meta.className = "num block text-[11px] text-faint"
      const stockLabel = product.low ? `Stock bajo (${product.stock})` : `Stock ${product.stock} ${product.unit}`
      meta.textContent = [product.sku, stockLabel].filter(Boolean).join(" · ")
      if (product.low) meta.classList.add("text-alert")
      text.appendChild(meta)

      option.appendChild(text)

      const price = document.createElement("span")
      price.className = "num shrink-0 text-xs font-semibold text-bronze"
      price.textContent = this.formatMoney(product.price)
      option.appendChild(price)

      this.listboxTarget.appendChild(option)
    })
  }

  formatMoney(value) {
    return `Gs. ${new Intl.NumberFormat("es", { minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(value || 0)}`
  }
}
