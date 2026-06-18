class Donation < ApplicationRecord
  DEFAULT_MONTHS = 36
  SUPPORTED_CURRENCIES = %w[ILS USD EUR GBP CAD].freeze

  enum :status, { pending: 0, paid: 1 }, default: :pending
  enum :frequency, { one_time: 0, recurring: 1 }, default: :one_time
  enum :display_preference, { full_name: 0, first_name_only: 1, anonymous: 2 }, default: :full_name

  belongs_to :campaign

  # Rails enums already generate .paid, .pending, .one_time, .recurring scopes.
  scope :recent, -> { order(created_at: :desc) }

  validates :idempotency_key, uniqueness: { allow_nil: true }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, inclusion: { in: SUPPORTED_CURRENCIES }
  validates :exchange_rate, numericality: { greater_than: 0 }
  validates :frequency, presence: true
  validates :display_preference, presence: true
  validates :donor_name, presence: true, unless: :anonymous?
  validates :months,
            numericality: { only_integer: true, in: 2..DEFAULT_MONTHS },
            allow_nil: true
  validates :months, absence: true, if: :one_time?

  after_create_commit do
    fresh_campaign = Campaign.find(campaign_id)
    Turbo::StreamsChannel.broadcast_replace_to(
      fresh_campaign,
      target: "campaign-stats-#{campaign_id}",
      partial: "campaigns/stats",
      locals: { campaign: fresh_campaign }
    )
    Turbo::StreamsChannel.broadcast_prepend_to(
      fresh_campaign,
      target: "recent-donations-#{campaign_id}",
      partial: "donations/card",
      locals: { donation: self }
    )
  rescue => e
    Rails.logger.error("[Donation] broadcast failed id=#{id} error=#{e.message}")
  end

  def amount_in_ils
    amount * exchange_rate
  end

  def display_name
    if anonymous?          then "תורם אנונימי"
    elsif first_name_only? then donor_name&.split&.first
    else                        donor_name
    end
  end

  def total_committed_amount
    recurring? ? amount * months.to_i : amount
  end
end
