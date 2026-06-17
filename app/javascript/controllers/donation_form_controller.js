import { Controller } from "@hotwired/stimulus"

const CURRENCY_SYMBOLS = { ILS: "₪", USD: "$", EUR: "€", GBP: "£", CAD: "CA$" }

export default class extends Controller {
  static targets = [
    "presetBtn", "presetAmount", "amountField", "customCard",
    "oneTimeBtn", "recurringBtn", "frequencyRadio",
    "displayRadio", "nameField",
    "monthsRow", "monthsSelect", "monthsField", "monthsLabel", "totalDisplay",
    "currencySelect", "totalCurrencySymbol", "customCurrencySymbol"
  ]
  static values = { rates: Object }

  connect() {
    this.currentAmount = 0
    this.refreshFrequencyUI()
    this.refreshAnonymousUI()
  }

  // ── Preset amount selection ──────────────────────────────
  selectPreset(event) {
    const ilsAmount = parseFloat(event.currentTarget.dataset.amount)
    const amount = this.convertFromIls(ilsAmount)
    this.currentAmount = amount

    if (this.hasAmountFieldTarget) this.amountFieldTarget.value = amount

    this.presetBtnTargets.forEach(btn => {
      const selected = btn === event.currentTarget
      btn.classList.toggle("border-purple-500", selected)
      btn.classList.toggle("bg-purple-50", selected)
      btn.classList.toggle("border-gray-200", !selected)
    })

    if (this.hasCustomCardTarget) {
      this.customCardTarget.classList.remove("border-purple-500", "bg-purple-50")
      this.customCardTarget.classList.add("border-dashed", "border-gray-300")
    }

    this.updateTotal()
  }

  onCustomAmount() {
    this.currentAmount = parseFloat(this.amountFieldTarget.value) || 0
    this.clearPreset()
    this.updateTotal()
  }

  clearPreset() {
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
    const isRecurring = !!this.frequencyRadioTargets.find(r => r.value === "recurring" && r.checked)

    if (this.hasOneTimeBtnTarget) {
      this.oneTimeBtnTarget.classList.toggle("bg-white", !isRecurring)
      this.oneTimeBtnTarget.classList.toggle("shadow", !isRecurring)
      this.oneTimeBtnTarget.classList.toggle("text-purple-700", !isRecurring)
    }
    if (this.hasRecurringBtnTarget) {
      this.recurringBtnTarget.classList.toggle("bg-white", isRecurring)
      this.recurringBtnTarget.classList.toggle("shadow", isRecurring)
      this.recurringBtnTarget.classList.toggle("text-purple-700", isRecurring)
    }

    // Show/hide months row; blank the hidden field when one-time so absence validation passes
    if (this.hasMonthsRowTarget) {
      this.monthsRowTarget.classList.toggle("hidden", !isRecurring)
    }
    if (this.hasMonthsFieldTarget) {
      this.monthsFieldTarget.value = isRecurring ? this.currentMonths() : ""
    }

    // Update preset button labels
    this.updatePresetLabels(isRecurring)
    this.updateTotal()
  }

  // ── Currency ─────────────────────────────────────────────
  currentCurrency() {
    return this.hasCurrencySelectTarget ? this.currencySelectTarget.value : "ILS"
  }

  currencySymbol() {
    return CURRENCY_SYMBOLS[this.currentCurrency()] ?? this.currentCurrency()
  }

  currentRate() {
    return this.ratesValue[this.currentCurrency()] ?? 1.0
  }

  convertFromIls(ilsAmount) {
    return Math.round(ilsAmount * this.currentRate())
  }

  onCurrencyChange() {
    const isRecurring = !!this.frequencyRadioTargets.find(r => r.value === "recurring" && r.checked)
    this.updatePresetLabels(isRecurring)
    if (this.hasTotalCurrencySymbolTarget) {
      this.totalCurrencySymbolTarget.textContent = this.currencySymbol()
    }
    if (this.hasCustomCurrencySymbolTarget) {
      this.customCurrencySymbolTarget.textContent = this.currencySymbol()
    }
    this.updateTotal()
  }

  updatePresetLabels(isRecurring) {
    const months = this.currentMonths()
    const symbol = this.currencySymbol()
    this.presetBtnTargets.forEach(btn => {
      const amount = this.convertFromIls(parseFloat(btn.dataset.amount))
      const amountEl = btn.querySelector("[data-donation-form-target='presetAmount']")
      if (!amountEl) return
      if (isRecurring) {
        amountEl.textContent = `${months} × ${symbol} ${amount.toLocaleString("he-IL")}`
      } else {
        amountEl.textContent = `${symbol} ${amount.toLocaleString("he-IL")}`
      }
    })
  }

  // ── Months selector ──────────────────────────────────────
  onMonthsChange() {
    const months = this.currentMonths()
    // sync hidden field so it's submitted with the form
    if (this.hasMonthsFieldTarget) this.monthsFieldTarget.value = months
    this.updatePresetLabels(true)
    this.updateTotal()
  }

  currentMonths() {
    if (this.hasMonthsSelectTarget) return parseInt(this.monthsSelectTarget.value) || 36
    return 36
  }

  // ── Total calculation ────────────────────────────────────
  updateTotal() {
    const isRecurring = !!this.frequencyRadioTargets.find(r => r.value === "recurring" && r.checked)
    if (!isRecurring || !this.hasTotalDisplayTarget) return

    const months = this.currentMonths()
    const total = this.currentAmount * months

    if (this.hasMonthsLabelTarget) {
      this.monthsLabelTarget.textContent = `× ${months} חודשים`
    }
    if (this.hasTotalCurrencySymbolTarget) {
      this.totalCurrencySymbolTarget.textContent = this.currencySymbol()
    }
    this.totalDisplayTarget.textContent = total.toLocaleString("he-IL")
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
