require "test_helper"

class DonationsTest < ActionDispatch::IntegrationTest
  def setup
    @campaign = campaigns(:orange_garden)
  end

  test "GET campaign show returns 200" do
    get campaign_path(@campaign)
    assert_response :success
  end

  test "GET missing campaign returns 404" do
    get campaign_path(id: 99999)
    assert_response :not_found
  end

  test "POST create with valid params creates pending donation and redirects" do
    assert_difference "Donation.count", 1 do
      post campaign_donations_path(@campaign), params: {
        donation: {
          amount: 180,
          frequency: "one_time",
          display_preference: "full_name",
          donor_name: "ישראל כהן",
          dedication_message: ""
        }
      }
    end
    assert_redirected_to campaign_path(@campaign)
    assert_equal "pending", Donation.last.status
  end

  test "POST create with missing amount re-renders form with error" do
    assert_no_difference "Donation.count" do
      post campaign_donations_path(@campaign), params: {
        donation: {
          amount: "",
          frequency: "one_time",
          display_preference: "full_name",
          donor_name: "ישראל כהן"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create without donor name when not anonymous re-renders with error" do
    assert_no_difference "Donation.count" do
      post campaign_donations_path(@campaign), params: {
        donation: {
          amount: 180,
          frequency: "one_time",
          display_preference: "full_name",
          donor_name: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create anonymous donation does not require donor name" do
    assert_difference "Donation.count", 1 do
      post campaign_donations_path(@campaign), params: {
        donation: {
          amount: 180,
          frequency: "one_time",
          display_preference: "anonymous",
          donor_name: ""
        }
      }
    end
    assert_redirected_to campaign_path(@campaign)
  end
end
