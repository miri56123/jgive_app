class Campaign < ApplicationRecord
  RECENT_DONATIONS_LIMIT = 20
  FOOD_CAMPAIGN_KEYWORDS = %w[מזון לחם אוכל רעב].freeze

  enum :status, { active: 0, ended: 1 }, default: :active

  has_many :donations, dependent: :destroy

  validates :title, presence: true
  validates :goal_amount, presence: true, numericality: { greater_than: 0 }

  # Includes pending: a submitted donation should immediately update progress
  # per assignment spec. Transitions to paid via payment webhook in production.
  def amount_raised
    donations.sum(:amount)
  end

  def donor_count
    donations.count
  end

  def percent_funded
    return 0 if goal_amount.zero?
    [(amount_raised / goal_amount * 100).round, 100].min
  end

  # Percentage of the bar to fill (uses bonus_goal as ceiling when present)
  def progress_pct
    total = (bonus_goal_amount.present? ? bonus_goal_amount : goal_amount).to_f
    return 0 if total.zero?
    [(amount_raised.to_f / total * 100), 100].min.round(2)
  end

  # Position of the primary-goal marker when a bonus goal exists (nil otherwise)
  def goal_marker_pct
    return nil unless bonus_goal_amount.present?
    (goal_amount.to_f / bonus_goal_amount.to_f * 100).round(2)
  end

  def preset_amounts
    presets_data.map { |p| { amount: p[:amount], label: p[:label] } }
  end

  private

  def presets_data
    if FOOD_CAMPAIGN_KEYWORDS.any? { |kw| title.include?(kw) || organization_name.to_s.include?(kw) }
      [
        { amount: 50,    label: "סל מזון 1" },
        { amount: 100,   label: "2 סלי מזון" },
        { amount: 250,   label: "5 סלי מזון" },
        { amount: 500,   label: "10 סלי מזון" },
        { amount: 1_000, label: "20 סלי מזון" }
      ]
    else
      [
        { amount: 180,   label: "נטיעת עץ" },
        { amount: 260,   label: "נטיעת 2 עצים" },
        { amount: 360,   label: "נטיעת 3 עצים – לזכרם" },
        { amount: 1_800, label: "מיני חורשה" },
        { amount: 5_000, label: "גינת ילדים" }
      ]
    end
  end
end
