class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  around_action :switch_locale

  private

  def switch_locale(&action)
    locale = params[:locale]
    locale = I18n.default_locale unless I18n.available_locales.map(&:to_s).include?(locale.to_s)
    I18n.with_locale(locale, &action)
  end

  # Keep the active locale in generated URLs. Always pass the :locale key (nil
  # for the default locale, so Hebrew stays at "/") — this stops the optional
  # "(:locale)" route segment from greedily capturing positional path arguments.
  def default_url_options
    { locale: (I18n.locale == I18n.default_locale ? nil : I18n.locale) }
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
