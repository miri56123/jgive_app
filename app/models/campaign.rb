class Campaign < ApplicationRecord
  RECENT_DONATIONS_LIMIT = 20
  FOOD_CAMPAIGN_KEYWORDS = %w[מזון לחם אוכל רעב].freeze

  enum :status, { active: 0, ended: 1 }, default: :active

  has_many :donations, dependent: :destroy

  validates :title, presence: true
  validates :organization_name, presence: true
  validates :goal_amount, presence: true, numericality: { greater_than: 0 }
  validates :cover_image_url,
            format: { with: /\Ahttps?:\/\/[^\s]+\z/i, message: "must be a valid http/https URL" },
            allow_blank: true

  # Returns the English value of an attribute when the locale is English and a
  # translation exists; otherwise falls back to the original (Hebrew) value.
  TRANSLATABLE_ATTRIBUTES = %i[title subtitle organization_name description].freeze

  TRANSLATABLE_ATTRIBUTES.each do |attr|
    define_method(:"display_#{attr}") do
      if I18n.locale == :en
        english = public_send(:"#{attr}_en")
        return english if english.present?
      end
      public_send(attr)
    end
  end

  def amount_raised
    @amount_raised ||=
      if respond_to?(:amount_raised_cache) && !amount_raised_cache.nil?
        amount_raised_cache.to_f
      else
        donations.sum("amount * exchange_rate")
      end
  end

  def donor_count
    @donor_count ||=
      if respond_to?(:donor_count_cache) && !donor_count_cache.nil?
        donor_count_cache.to_i
      else
        donations.count
      end
  end

  def percent_funded
    return 0 if goal_amount.zero?
    [ (amount_raised / goal_amount * 100).round, 100 ].min
  end

  # Percentage of the bar to fill (uses bonus_goal as ceiling when present)
  def progress_pct
    total = (bonus_goal_amount.present? ? bonus_goal_amount : goal_amount).to_f
    return 0 if total.zero?
    [ (amount_raised.to_f / total * 100), 100 ].min.round(2)
  end

  # Position of the primary-goal marker when a bonus goal exists (nil otherwise)
  def goal_marker_pct
    return nil unless bonus_goal_amount.present?
    (goal_amount.to_f / bonus_goal_amount.to_f * 100).round(2)
  end

  def preset_amounts
    if FOOD_CAMPAIGN_KEYWORDS.any? { |kw| title.include?(kw) || organization_name.to_s.include?(kw) }
      [
        { amount: 50,    label: I18n.t("campaign.presets.food.basket_1") },
        { amount: 100,   label: I18n.t("campaign.presets.food.baskets_2") },
        { amount: 250,   label: I18n.t("campaign.presets.food.baskets_5") },
        { amount: 500,   label: I18n.t("campaign.presets.food.baskets_10") },
        { amount: 1_000, label: I18n.t("campaign.presets.food.baskets_20") }
      ]
    else
      [
        { amount: 180,   label: I18n.t("campaign.presets.trees.tree_1") },
        { amount: 260,   label: I18n.t("campaign.presets.trees.trees_2") },
        { amount: 360,   label: I18n.t("campaign.presets.trees.trees_3_memory") },
        { amount: 1_800, label: I18n.t("campaign.presets.trees.mini_forest") },
        { amount: 5_000, label: I18n.t("campaign.presets.trees.children_garden") }
      ]
    end
  end
end
