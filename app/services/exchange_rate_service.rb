require "net/http"

class ExchangeRateService
  API_URL   = "https://api.frankfurter.dev/v1/latest"
  CACHE_TTL = 1.hour

  def self.to_ils(currency)
    return 1.0 if currency == "ILS"

    Rails.cache.fetch("exchange_rate/#{currency}_to_ILS", expires_in: CACHE_TTL) do
      uri  = URI("#{API_URL}?from=#{currency}&to=ILS")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = true
      http.open_timeout = 5
      http.read_timeout = 5
      rate = JSON.parse(http.get(uri.request_uri).body).dig("rates", "ILS").to_f
      rate.positive? ? rate : 1.0
    end
  rescue => e
    Rails.logger.warn("ExchangeRateService: could not fetch #{currency}→ILS rate: #{e.message}")
    1.0
  end
end
