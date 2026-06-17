class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def exchange_rates_from_ils
    Donation::SUPPORTED_CURRENCIES.each_with_object({ "ILS" => 1.0 }) do |currency, rates|
      next if currency == "ILS"
      rate_to_ils = ExchangeRateService.to_ils(currency)
      rates[currency] = rate_to_ils.positive? ? (1.0 / rate_to_ils).round(6) : 1.0
    end
  end
end
