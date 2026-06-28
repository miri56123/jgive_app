class Current < ActiveSupport::CurrentAttributes
  # Per-request display currency chosen via the URL (see ApplicationController).
  # Reset automatically between requests.
  attribute :display_currency
end
