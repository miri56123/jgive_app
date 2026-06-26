module ApplicationHelper
  CURRENCY_SYMBOLS = { "ILS" => "₪", "USD" => "$", "EUR" => "€", "GBP" => "£", "CAD" => "CA$" }.freeze

  def format_amount(amount, currency = "ILS")
    symbol = CURRENCY_SYMBOLS.fetch(currency, currency)
    "#{symbol} #{number_with_delimiter(amount.to_i)}"
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
