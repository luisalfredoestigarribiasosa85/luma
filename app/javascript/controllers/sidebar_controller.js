import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop", "toggle"]

  connect() {
    this.query = window.matchMedia("(max-width: 1023px)")
    this.boundSync = this.sync.bind(this)
    this.boundKeydown = this.handleKeydown.bind(this)
    this.query.addEventListener("change", this.boundSync)
    document.addEventListener("keydown", this.boundKeydown)
    this.sync()
  }

  disconnect() {
    this.query.removeEventListener("change", this.boundSync)
    document.removeEventListener("keydown", this.boundKeydown)
    document.body.classList.remove("overflow-hidden")
  }

  toggle() {
    if (!this.query.matches) return
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (!this.query.matches) return
    this.panelTarget.classList.remove("-translate-x-full")
    this.panelTarget.removeAttribute("inert")
    this.panelTarget.setAttribute("aria-hidden", "false")
    this.backdropTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    if (!this.query.matches) return
    // El foco nunca puede quedar dentro de un contenedor aria-hidden/inert:
    // lo devolvemos al botón de la hamburguesa, que sigue visible.
    if (this.panelTarget.contains(document.activeElement) && this.hasToggleTarget) {
      this.toggleTarget.focus()
    }
    this.panelTarget.classList.add("-translate-x-full")
    this.panelTarget.setAttribute("aria-hidden", "true")
    this.panelTarget.setAttribute("inert", "")
    this.backdropTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  sync() {
    if (this.query.matches) {
      this.close()
    } else {
      this.panelTarget.classList.remove("-translate-x-full")
      this.panelTarget.removeAttribute("inert")
      this.panelTarget.setAttribute("aria-hidden", "false")
      this.backdropTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
      if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.close()
  }

  get isOpen() {
    return !this.panelTarget.classList.contains("-translate-x-full")
  }
}
