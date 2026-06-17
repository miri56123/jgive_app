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

  test "amount_raised includes both pending and paid donations" do
    campaign = campaigns(:orange_garden)
    expected = campaign.donations.sum(:amount)
    assert_equal expected, campaign.amount_raised
  end

  test "amount_raised updates immediately when a pending donation is created" do
    campaign = campaigns(:orange_garden)
    before = campaign.amount_raised
    campaign.donations.create!(
      amount: 250,
      frequency: :one_time,
      display_preference: :full_name,
      donor_name: "Test Donor",
      status: :pending
    )
    assert_equal before + 250, campaign.amount_raised
  end

  test "percent_funded is capped at 100" do
    c = campaigns(:orange_garden)
    assert c.percent_funded >= 0
    assert c.percent_funded <= 100
  end

  test "donor_count includes pending and paid donations" do
    campaign = campaigns(:orange_garden)
    assert_equal campaign.donations.count, campaign.donor_count
  end

  test "active and ended enum values" do
    assert_equal 0, Campaign.statuses[:active]
    assert_equal 1, Campaign.statuses[:ended]
  end
end
