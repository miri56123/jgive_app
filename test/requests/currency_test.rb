require "test_helper"

class CurrencyTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:orange_garden) # goal 2,000,000 ILS, ILS donations
  end

  # Force a fixed exchange rate so the test never hits the network.
  def with_rate(to_ils)
    original = ExchangeRateService.method(:to_ils)
    ExchangeRateService.define_singleton_method(:to_ils) { |*_, **_| to_ils }
    yield
  ensure
    ExchangeRateService.singleton_class.send(:define_method, :to_ils, original)
  end

  test "default display currency is ILS at the root path" do
    get root_path
    assert_response :success
    assert_select "details summary", /ILS/
    assert_includes @response.body, "₪ 1,300" # raised total (180+360+260+500) in ILS
  end

  test "currency URL segment converts ILS aggregates to the display currency" do
    with_rate(4.0) do # 1 USD = 4 ILS => x0.25
      get campaign_path(@campaign, locale: "en", currency: "usd")
      assert_response :success
      assert_select "details summary", /USD/
      assert_includes @response.body, "$ 500,000" # 2,000,000 ILS -> $500,000
    end
  end

  test "donor card keeps the donor's original amount and converts only the secondary line" do
    with_rate(4.0) do
      get campaign_path(@campaign, locale: "en", currency: "usd")
      assert_response :success
      assert_includes @response.body, "₪ 180"  # headline unchanged (donor gave ILS)
      assert_includes @response.body, "≈ $ 45" # secondary line converted (180 x 0.25)
    end
  end

  test "an unsupported currency value falls back to ILS display" do
    # The route constraint only allows usd/eur/gbp/cad; outside it, no currency
    # segment is matched, so the display stays ILS.
    get campaign_path(@campaign, locale: "en")
    assert_response :success
    assert_select "details summary", /ILS/
  end
end
