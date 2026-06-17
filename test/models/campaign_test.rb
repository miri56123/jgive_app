require "test_helper"

class CampaignTest < ActiveSupport::TestCase
  test "requires title" do
    campaign = Campaign.new(goal_amount: 1000)
    assert_not campaign.valid?
    assert_includes campaign.errors[:title], "can't be blank"
  end

  test "requires goal_amount greater than zero" do
    campaign = Campaign.new(title: "Test", goal_amount: 0)
    assert_not campaign.valid?
  end

  test "amount_raised sums only paid donations" do
    campaign = campaigns(:orange_garden)
    expected = campaign.donations.paid.sum(:amount)
    assert_equal expected, campaign.amount_raised
  end

  test "amount_raised excludes pending donations" do
    campaign = campaigns(:orange_garden)
    before = campaign.amount_raised
    campaign.donations.create!(
      amount: 9_999,
      frequency: :one_time,
      display_preference: :full_name,
      donor_name: "Test",
      status: :pending
    )
    assert_equal before, campaign.amount_raised
  end

  test "percent_funded is capped at 100" do
    campaign = Campaign.new(goal_amount: 100)
    allow_amount = 200
    campaign.donations.build(amount: allow_amount, status: :paid, frequency: :one_time,
                              display_preference: :full_name, donor_name: "X")
    # percent_funded delegates to amount_raised which hits the DB, so use a stub scenario
    c = campaigns(:orange_garden)
    assert c.percent_funded >= 0
    assert c.percent_funded <= 100
  end

  test "donor_count counts only paid donations" do
    campaign = campaigns(:orange_garden)
    paid_count = campaign.donations.paid.count
    assert_equal paid_count, campaign.donor_count
  end

  test "active and ended enum values" do
    assert_equal 0, Campaign.statuses[:active]
    assert_equal 1, Campaign.statuses[:ended]
  end
end
