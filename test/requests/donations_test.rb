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

  test "GET campaigns index returns 200" do
    get campaigns_path
    assert_response :success
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
    assert Donation.last.pending?
  end

  test "POST create sets status to pending" do
    post campaign_donations_path(@campaign), params: {
      donation: {
        amount: 180,
        frequency: "one_time",
        display_preference: "full_name",
        donor_name: "ישראל כהן"
      }
    }
    assert Donation.last.pending?
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

  test "POST create recurring donation stores months" do
    post campaign_donations_path(@campaign), params: {
      donation: {
        amount: 180,
        frequency: "recurring",
        months: 12,
        display_preference: "full_name",
        donor_name: "ישראל כהן"
      }
    }
    assert_redirected_to campaign_path(@campaign)
    d = Donation.last
    assert d.recurring?
    assert_equal 12, d.months
  end

  test "POST create to missing campaign returns 404" do
    post campaign_donations_path(campaign_id: 99999), params: {
      donation: { amount: 180, frequency: "one_time", display_preference: "full_name", donor_name: "test" }
    }
    assert_response :not_found
  end

  test "POST create to ended campaign redirects with alert" do
    ended = campaigns(:ended_campaign)
    assert_no_difference "Donation.count" do
      post campaign_donations_path(ended), params: {
        donation: { amount: 180, frequency: "one_time", display_preference: "full_name", donor_name: "ישראל כהן" }
      }
    end
    assert_redirected_to campaign_path(ended)
    assert_match "הסתיים", flash[:alert]
  end

  test "POST create with invalid months is rejected" do
    assert_no_difference "Donation.count" do
      post campaign_donations_path(@campaign), params: {
        donation: {
          amount: 180,
          frequency: "recurring",
          months: 1,
          display_preference: "full_name",
          donor_name: "ישראל כהן"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create stores idempotency_key on the donation record" do
    key = SecureRandom.uuid
    post campaign_donations_path(@campaign), params: {
      donation: {
        amount: 180, frequency: "one_time",
        display_preference: "full_name", donor_name: "ישראל כהן",
        idempotency_key: key
      }
    }
    assert_redirected_to campaign_path(@campaign)
    assert_equal key, Donation.last.idempotency_key
  end

  test "POST create with duplicate idempotency_key is idempotent" do
    key = SecureRandom.uuid
    Donation.create!(
      campaign: @campaign, amount: 180, frequency: :one_time,
      display_preference: :full_name, donor_name: "ישראל כהן",
      idempotency_key: key
    )
    assert_no_difference "Donation.count" do
      post campaign_donations_path(@campaign), params: {
        donation: {
          amount: 999, frequency: "one_time",
          display_preference: "full_name", donor_name: "שם אחר",
          idempotency_key: key
        }
      }
    end
    assert_redirected_to campaign_path(@campaign)
  end
end
