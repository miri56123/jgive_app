class ExchangeRateRefreshJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform
    currencies = Donation::SUPPORTED_CURRENCIES.reject { |c| c == "ILS" }
    Rails.logger.info("[ExchangeRateRefreshJob] refreshing #{currencies.size} currencies")

    currencies.each do |currency|
      ExchangeRateService.to_ils(currency, force: true)
      Rails.logger.info("[ExchangeRateRefreshJob] refreshed #{currency}")
    end

    Rails.logger.info("[ExchangeRateRefreshJob] complete")
  end
end
