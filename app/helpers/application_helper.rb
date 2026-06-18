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

  def hebrew_time_ago(time)
    diff = (Time.current - time).to_i
    case diff
    when (0...MINUTE)        then "עכשיו"
    when (MINUTE...HOUR)     then "לפני כ-#{diff / MINUTE} דקות"
    when (HOUR...DAY)        then "לפני כ-#{diff / HOUR} שעות"
    when (DAY...MONTH)       then "לפני כ-#{diff / DAY} ימים"
    else                          "לפני כ-#{diff / MONTH} חודשים"
    end
  end
end
