class Campaign < ApplicationRecord
  enum :status, { active: 0, ended: 1 }, default: :active

  has_many :donations, dependent: :destroy

  validates :title, presence: true
  validates :goal_amount, presence: true, numericality: { greater_than: 0 }

  def amount_raised
    donations.paid.sum(:amount)
  end

  def donor_count
    donations.paid.count
  end

  def percent_funded
    return 0 if goal_amount.zero?
    [(amount_raised / goal_amount * 100).round, 100].min
  end

  def preset_amounts
    [
      { amount: 180, label: "נטיעת עץ" },
      { amount: 260, label: "נטיעת 2 עצים" },
      { amount: 360, label: "נטיעת 3 עצים – לזכרם" },
      { amount: 1_800, label: "מיני חורשה" },
      { amount: 5_000, label: "גינת ילדים" }
    ]
  end
end
