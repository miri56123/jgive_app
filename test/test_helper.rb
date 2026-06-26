ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors, threshold: 100)
    fixtures :campaigns, :donations
  end
end

module ActionDispatch
  module Integration
    class Session
      # Always supply the :locale key (nil = default Hebrew at "/") so the optional
      # "(:locale)" route segment doesn't capture positional path-helper arguments
      # such as campaign_donations_path(@campaign). Path helpers in integration
      # tests run on the session object, so the default must live here.
      def default_url_options
        { locale: nil }
      end
    end
  end
end
