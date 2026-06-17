class CampaignsController < ApplicationController
  def index
    @campaigns = Campaign.order(status: :asc, created_at: :desc)
  end

  def show
    @campaign = Campaign.find(params[:id])
    @recent_donations = @campaign.donations.recent.limit(Campaign::RECENT_DONATIONS_LIMIT)
    @donation = Donation.new
  end
end
