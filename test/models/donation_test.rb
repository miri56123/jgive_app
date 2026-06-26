require "test_helper"

class DonationTest < ActiveSupport::TestCase
  def valid_attrs
    {
      campaign: campaigns(:orange_garden),
      amount: 180,
      frequency: :one_time,
      display_preference: :full_name,
      donor_name: "ישראל כהן"
    }
  end

  test "valid with all required attributes" do
    assert Donation.new(valid_attrs).valid?
  end

  test "amount must be greater than zero" do
    d = Donation.new(valid_attrs.merge(amount: 0))
    assert_not d.valid?
    assert_includes d.errors[:amount], I18n.t("errors.messages.greater_than", count: 0)
  end

  test "amount cannot be negative" do
    d = Donation.new(valid_attrs.merge(amount: -50))
    assert_not d.valid?
  end

  test "donor_name required when not anonymous" do
    d = Donation.new(valid_attrs.merge(donor_name: nil, display_preference: :full_name))
    assert_not d.valid?
    assert_includes d.errors[:donor_name], I18n.t("errors.messages.blank")
  end

  test "donor_name required when first_name_only" do
    d = Donation.new(valid_attrs.merge(donor_name: nil, display_preference: :first_name_only))
    assert_not d.valid?
    assert_includes d.errors[:donor_name], I18n.t("errors.messages.blank")
  end

  test "donor_name not required when anonymous" do
    d = Donation.new(valid_attrs.merge(donor_name: nil, display_preference: :anonymous))
    assert d.valid?
  end

  test "status defaults to pending" do
    d = Donation.new(valid_attrs)
    assert d.pending?
  end

  test "frequency defaults to one_time" do
    d = Donation.new(valid_attrs)
    assert d.one_time?
  end

  test ".paid scope returns only paid donations" do
    paid = Donation.paid
    assert paid.all? { |d| d.paid? }
  end

  test ".pending scope returns only pending donations" do
    pending = Donation.pending
    assert pending.all? { |d| d.pending? }
  end

  test "display_name returns full name for full_name preference" do
    d = Donation.new(valid_attrs.merge(donor_name: "ישראל כהן", display_preference: :full_name))
    assert_equal "ישראל כהן", d.display_name
  end

  test "display_name returns first name only for first_name_only preference" do
    d = Donation.new(valid_attrs.merge(donor_name: "ישראל כהן", display_preference: :first_name_only))
    assert_equal "ישראל", d.display_name
  end

  test "display_name returns anonymous label" do
    d = Donation.new(valid_attrs.merge(display_preference: :anonymous, donor_name: nil))
    assert_equal "תורם אנונימי", d.display_name
  end

  test "display_name with first_name_only and nil donor_name returns nil safely" do
    d = Donation.new(valid_attrs.merge(display_preference: :first_name_only, donor_name: nil))
    assert_nil d.display_name
  end

  test "enum values are correct integers" do
    assert_equal 0, Donation.statuses[:pending]
    assert_equal 1, Donation.statuses[:paid]
    assert_equal 0, Donation.frequencies[:one_time]
    assert_equal 1, Donation.frequencies[:recurring]
    assert_equal 0, Donation.display_preferences[:full_name]
    assert_equal 1, Donation.display_preferences[:first_name_only]
    assert_equal 2, Donation.display_preferences[:anonymous]
  end

  test "DEFAULT_MONTHS constant is 36" do
    assert_equal 36, Donation::DEFAULT_MONTHS
  end

  test "recurring donation accepts months field" do
    d = Donation.new(valid_attrs.merge(frequency: :recurring, months: 12))
    assert d.valid?
    assert_equal 12, d.months
  end

  test "months must be between 2 and DEFAULT_MONTHS" do
    assert_not Donation.new(valid_attrs.merge(frequency: :recurring, months: 1)).valid?
    assert_not Donation.new(valid_attrs.merge(frequency: :recurring, months: 37)).valid?
    assert_not Donation.new(valid_attrs.merge(frequency: :recurring, months: 0)).valid?
    assert     Donation.new(valid_attrs.merge(frequency: :recurring, months: 2)).valid?
    assert     Donation.new(valid_attrs.merge(frequency: :recurring, months: 36)).valid?
  end

  test "months can be nil for one-time donations" do
    d = Donation.new(valid_attrs.merge(frequency: :one_time, months: nil))
    assert d.valid?
  end

  test "months must be absent for one_time donations" do
    d = Donation.new(valid_attrs.merge(frequency: :one_time, months: 12))
    assert_not d.valid?
    assert_includes d.errors[:months], I18n.t("errors.messages.present")
  end

  test "total_committed_amount for one_time equals amount" do
    d = Donation.new(valid_attrs.merge(amount: 180, frequency: :one_time))
    assert_equal 180, d.total_committed_amount
  end

  test "total_committed_amount for recurring equals amount times months" do
    d = Donation.new(valid_attrs.merge(amount: 180, frequency: :recurring, months: 12))
    assert_equal 2160, d.total_committed_amount
  end

  test "total_committed_amount for recurring with nil months defaults to 0" do
    d = Donation.new(valid_attrs.merge(amount: 180, frequency: :recurring, months: nil))
    assert_equal 0, d.total_committed_amount
  end

  test "idempotency_key allows nil on multiple donations" do
    Donation.create!(valid_attrs.merge(idempotency_key: nil))
    d2 = Donation.new(valid_attrs.merge(idempotency_key: nil))
    assert d2.valid?
  end

  test "idempotency_key must be unique when present" do
    key = SecureRandom.uuid
    Donation.create!(valid_attrs.merge(idempotency_key: key))
    d2 = Donation.new(valid_attrs.merge(idempotency_key: key))
    assert_not d2.valid?
    assert_includes d2.errors[:idempotency_key], I18n.t("errors.messages.taken")
  end
end
