import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "presetBtn", "amountField", "customCard",
    "oneTimeBtn", "recurringBtn", "frequencyRadio",
    "displayRadio", "nameField"
  ]

  connect() {
    this.refreshFrequencyUI()
    this.refreshAnonymousUI()
  }

  // ── Preset amount selection ──────────────────────────────
  selectPreset(event) {
    const amount = event.currentTarget.dataset.amount
    // Set the single amount field directly — no hidden field needed
    if (this.hasAmountFieldTarget) this.amountFieldTarget.value = amount

    this.presetBtnTargets.forEach(btn => {
      const selected = btn === event.currentTarget
      btn.classList.toggle("border-purple-500", selected)
      btn.classList.toggle("bg-purple-50", selected)
      btn.classList.toggle("border-gray-200", !selected)
    })

    // Clear custom card highlight when preset chosen
    if (this.hasCustomCardTarget) {
      this.customCardTarget.classList.remove("border-purple-500", "bg-purple-50")
      this.customCardTarget.classList.add("border-dashed", "border-gray-300")
    }
  }

  clearPreset() {
    // User typed a custom amount — deselect all presets
    this.presetBtnTargets.forEach(btn => {
      btn.classList.remove("border-purple-500", "bg-purple-50")
      btn.classList.add("border-gray-200")
    })
  }

  // ── Frequency toggle ─────────────────────────────────────
  selectOneTime() {
    const radio = this.frequencyRadioTargets.find(r => r.value === "one_time")
    if (radio) radio.checked = true
    this.refreshFrequencyUI()
  }

  selectRecurring() {
    const radio = this.frequencyRadioTargets.find(r => r.value === "recurring")
    if (radio) radio.checked = true
    this.refreshFrequencyUI()
  }

  refreshFrequencyUI() {
    const recurring = this.frequencyRadioTargets.find(r => r.value === "recurring" && r.checked)
    if (this.hasOneTimeBtnTarget) {
      this.oneTimeBtnTarget.classList.toggle("bg-white", !recurring)
      this.oneTimeBtnTarget.classList.toggle("shadow", !recurring)
      this.oneTimeBtnTarget.classList.toggle("text-purple-700", !recurring)
    }
    if (this.hasRecurringBtnTarget) {
      this.recurringBtnTarget.classList.toggle("bg-white", !!recurring)
      this.recurringBtnTarget.classList.toggle("shadow", !!recurring)
      this.recurringBtnTarget.classList.toggle("text-purple-700", !!recurring)
    }
  }

  // ── Anonymous toggle ─────────────────────────────────────
  toggleAnonymous() {
    setTimeout(() => this.refreshAnonymousUI(), 0)
  }

  refreshAnonymousUI() {
    const checked = this.displayRadioTargets.find(r => r.checked)
    const isAnonymous = checked?.value === "anonymous"
    if (this.hasNameFieldTarget) {
      this.nameFieldTarget.classList.toggle("hidden", isAnonymous)
    }
  }
}
