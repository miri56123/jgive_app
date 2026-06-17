class Donation < ApplicationRecord
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
    case display_preference
    when "full_name"    then donor_name
    when "first_name_only" then donor_name&.split&.first
    when "anonymous"    then "תורם אנונימי"
    end
  end
end
