class ExchangeRateRefreshJob < ApplicationJob
  queue_as :default

  def perform
    Donation::SUPPORTED_CURRENCIES.each do |currency|
      next if currency == "ILS"
      ExchangeRateService.to_ils(currency, force: true)
    end
  end
end
