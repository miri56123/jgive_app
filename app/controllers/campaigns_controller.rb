class CampaignsController < ApplicationController
  def index
    @campaigns = Campaign
      .order(status: :asc, created_at: :desc)
      .left_joins(:donations)
      .select("campaigns.*, SUM(donations.amount * donations.exchange_rate) AS amount_raised_cache, COUNT(donations.id) AS donor_count_cache")
      .group("campaigns.id")
  end

  def show
    @campaign = Campaign.find(params[:id])
    @recent_donations = @campaign.donations.recent.limit(Campaign::RECENT_DONATIONS_LIMIT)
    @donation = Donation.new(idempotency_key: SecureRandom.uuid)
    @exchange_rates = exchange_rates_from_ils
  end
end
