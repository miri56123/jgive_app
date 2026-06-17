class Donation < ApplicationRecord
  DEFAULT_MONTHS = 36

  enum :status, { pending: 0, paid: 1 }, default: :pending
  enum :frequency, { one_time: 0, recurring: 1 }, default: :one_time
  enum :display_preference, { full_name: 0, first_name_only: 1, anonymous: 2 }, default: :full_name

  belongs_to :campaign

  scope :paid, -> { where(status: :paid) }
  scope :pending, -> { where(status: :pending) }
  scope :recent, -> { order(created_at: :desc) }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :frequency, presence: true
  validates :display_preference, presence: true
  validates :donor_name, presence: true, unless: :anonymous?

  def display_name
    if anonymous?     then "תורם אנונימי"
    elsif first_name_only? then donor_name&.split&.first
    else donor_name
    end
  end
end
