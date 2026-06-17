import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel"]

  connect() {
    this.showTab(this.buttonTargets[0]?.dataset.tab || "about")
  }

  switch(event) {
    this.showTab(event.currentTarget.dataset.tab)
  }

  showTab(tabId) {
    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.id !== `tab-${tabId}`)
    })
    this.buttonTargets.forEach(btn => {
      const active = btn.dataset.tab === tabId
      btn.classList.toggle("border-purple-600", active)
      btn.classList.toggle("text-purple-600", active)
      btn.classList.toggle("border-transparent", !active)
      btn.classList.toggle("text-gray-500", !active)
    })
  }
}
