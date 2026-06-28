module ApplicationHelper
  CURRENCY_SYMBOLS = { "ILS" => "₪", "USD" => "$", "EUR" => "€", "GBP" => "£", "CAD" => "CA$" }.freeze

  def format_amount(amount, currency = "ILS")
    symbol = CURRENCY_SYMBOLS.fetch(currency, currency)
    "#{symbol} #{number_with_delimiter(amount.to_i)}"
  end

  # The user's chosen display currency (from the URL); defaults to ILS.
  def display_currency
    Current.display_currency || "ILS"
  end

  # Multiplier to convert an ILS amount into the display currency.
  def display_rate
    return 1.0 if display_currency == "ILS"
    rate = ExchangeRateService.to_ils(display_currency)
    rate.positive? ? (1.0 / rate) : 1.0
  end

  # Convert an ILS-denominated amount to the display currency and format it.
  def display_amount(amount_ils)
    format_amount(amount_ils.to_f * display_rate, display_currency)
  end

  # url_for params to switch language while preserving the display currency.
  # Keeps the locale explicit when a non-ILS currency is set, so we never emit
  # a malformed "//usd" (currency segment without a locale segment).
  def locale_switch_params(target_locale)
    if display_currency == "ILS"
      { locale: (target_locale.to_s == I18n.default_locale.to_s ? nil : target_locale), currency: nil }
    else
      { locale: target_locale, currency: display_currency.downcase }
    end
  end

  # url_for params to switch display currency while preserving the locale.
  def currency_switch_params(target_currency)
    if target_currency == "ILS"
      { locale: (I18n.locale == I18n.default_locale ? nil : I18n.locale), currency: nil }
    else
      { locale: I18n.locale, currency: target_currency.downcase }
    end
  end

  MINUTE = 60
  HOUR   = 3_600
  DAY    = 86_400
  MONTH  = 2_592_000

  def time_ago(time)
    diff = (Time.current - time).to_i
    case diff
    when (0...MINUTE)        then t("helpers.time_ago.now")
    when (MINUTE...HOUR)     then t("helpers.time_ago.minutes", count: diff / MINUTE)
    when (HOUR...DAY)        then t("helpers.time_ago.hours", count: diff / HOUR)
    when (DAY...MONTH)       then t("helpers.time_ago.days", count: diff / DAY)
    else                          t("helpers.time_ago.months", count: diff / MONTH)
    end
  end
end
