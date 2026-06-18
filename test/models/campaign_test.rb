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
    expected = campaign.donations.sum("amount * exchange_rate")
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
    # Reload to clear memoized @amount_raised so we re-query the DB
    assert_equal before + 250, Campaign.find(campaign.id).amount_raised
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

  test "progress_pct uses bonus_goal_amount as ceiling when present" do
    campaign = campaigns(:orange_garden)
    if campaign.bonus_goal_amount.present?
      expected = [ (campaign.amount_raised.to_f / campaign.bonus_goal_amount.to_f * 100), 100 ].min.round(2)
      assert_equal expected, campaign.progress_pct
    else
      expected = [ (campaign.amount_raised.to_f / campaign.goal_amount.to_f * 100), 100 ].min.round(2)
      assert_equal expected, campaign.progress_pct
    end
  end

  test "progress_pct is never above 100" do
    campaign = campaigns(:orange_garden)
    assert campaign.progress_pct <= 100
    assert campaign.progress_pct >= 0
  end

  test "goal_marker_pct returns nil when no bonus goal" do
    campaign = campaigns(:food_bank)
    assert_nil campaign.goal_marker_pct
  end

  test "goal_marker_pct returns correct percentage when bonus goal present" do
    campaign = campaigns(:orange_garden)
    if campaign.bonus_goal_amount.present?
      expected = (campaign.goal_amount.to_f / campaign.bonus_goal_amount.to_f * 100).round(2)
      assert_equal expected, campaign.goal_marker_pct
    end
  end

  test "preset_amounts returns food presets for food campaign" do
    campaign = campaigns(:food_bank)
    amounts = campaign.preset_amounts.map { |p| p[:amount] }
    assert_includes amounts, 50
    assert_includes amounts, 100
  end

  test "preset_amounts returns tree presets for non-food campaign" do
    campaign = campaigns(:orange_garden)
    amounts = campaign.preset_amounts.map { |p| p[:amount] }
    assert_includes amounts, 180
    assert_includes amounts, 360
  end

  test "RECENT_DONATIONS_LIMIT constant is defined" do
    assert_equal 20, Campaign::RECENT_DONATIONS_LIMIT
  end

  test "requires organization_name" do
    campaign = Campaign.new(title: "Test", goal_amount: 1000)
    assert_not campaign.valid?
    assert_includes campaign.errors[:organization_name], "can't be blank"
  end
end
