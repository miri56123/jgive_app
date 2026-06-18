Rack::Attack.enabled = !Rails.env.test?

Rack::Attack.cache.store = Rails.cache

# Safelist health-check and asset paths from all throttles
Rack::Attack.safelist("allow-assets") do |req|
  req.path.start_with?("/assets", "/cable", "/up")
end

# Throttle donation submissions: max 5 per minute per IP
Rack::Attack.throttle("donations/ip", limit: 5, period: 1.minute) do |req|
  req.ip if req.post? && req.path.match?(%r{\A/campaigns/\d+/donations\z})
end

# Throttle general page requests: max 300 per 5 minutes per IP
Rack::Attack.throttle("req/ip", limit: 300, period: 5.minutes) do |req|
  req.ip
end

Rack::Attack.throttled_responder = lambda do |_env|
  [
    429,
    { "Content-Type" => "text/plain; charset=utf-8" },
    [ "יותר מדי בקשות. אנא המתן דקה ונסה שנית." ]
  ]
end
