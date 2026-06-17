module ApplicationHelper
  def format_amount(amount)
    "₪ #{number_with_delimiter(amount.to_i)}"
  end

  def hebrew_time_ago(time)
    diff = (Time.current - time).to_i
    case diff
    when 0..59      then "עכשיו"
    when 60..3599   then "לפני כ-#{(diff / 60)} דקות"
    when 3600..86399 then "לפני כ-#{(diff / 3600)} שעות"
    when 86400..2591999 then "לפני כ-#{(diff / 86400)} ימים"
    else                  "לפני כ-#{(diff / 2592000)} חודשים"
    end
  end
end
