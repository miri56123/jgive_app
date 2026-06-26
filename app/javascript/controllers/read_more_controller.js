import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["short", "full", "toggle"]
  static values = { expand: { type: String, default: "קרא עוד" }, collapse: { type: String, default: "פחות" } }

  expand() {
    this.shortTarget.classList.add("hidden")
    this.fullTarget.classList.remove("hidden")
    this.toggleTarget.textContent = this.collapseValue
    this.toggleTarget.removeEventListener("click", this.expand)
    this.toggleTarget.addEventListener("click", () => this.collapse())
  }

  collapse() {
    this.fullTarget.classList.add("hidden")
    this.shortTarget.classList.remove("hidden")
    this.toggleTarget.textContent = this.expandValue
    this.toggleTarget.removeEventListener("click", this.collapse)
    this.toggleTarget.addEventListener("click", () => this.expand())
  }

  toggle() {
    this.shortTarget.classList.contains("hidden") ? this.collapse() : this.expand()
  }
}
