class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  around_action :switch_locale
  before_action :set_display_currency

  private

  def switch_locale(&action)
    locale = params[:locale]
    locale = I18n.default_locale unless I18n.available_locales.map(&:to_s).include?(locale.to_s)
    I18n.with_locale(locale, &action)
  end

  # Display currency chosen via the URL "(:currency)" segment (ILS is the default
  # and carries no segment). Validated against the supported set.
  def set_display_currency
    requested = params[:currency].to_s.upcase
    Current.display_currency =
      Donation::SUPPORTED_CURRENCIES.include?(requested) ? requested : "ILS"
  end

  # Keep the active locale + display currency in generated URLs. Always pass both
  # keys so the optional "(:locale)" / "(:currency)" segments don't capture
  # positional path arguments. ILS (default) carries no segment; for any other
  # currency we include the locale too, so we never emit a malformed "//usd".
  def default_url_options
    currency = Current.display_currency
    if currency.nil? || currency == "ILS"
      { locale: (I18n.locale == I18n.default_locale ? nil : I18n.locale), currency: nil }
    else
      { locale: I18n.locale, currency: currency.downcase }
    end
  end

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
