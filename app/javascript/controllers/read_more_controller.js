import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["short", "full", "toggle"]

  expand() {
    this.shortTarget.classList.add("hidden")
    this.fullTarget.classList.remove("hidden")
    this.toggleTarget.textContent = "פחות"
    this.toggleTarget.removeEventListener("click", this.expand)
    this.toggleTarget.addEventListener("click", () => this.collapse())
  }

  collapse() {
    this.fullTarget.classList.add("hidden")
    this.shortTarget.classList.remove("hidden")
    this.toggleTarget.textContent = "קרא עוד"
    this.toggleTarget.removeEventListener("click", this.collapse)
    this.toggleTarget.addEventListener("click", () => this.expand())
  }

  toggle() {
    this.shortTarget.classList.contains("hidden") ? this.collapse() : this.expand()
  }
}
