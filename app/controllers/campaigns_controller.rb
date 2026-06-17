class CampaignsController < ApplicationController
  def index
    @campaigns = Campaign.all.order(created_at: :desc)
  end

  def show
    @campaign = Campaign.find(params[:id])
    @recent_donations = @campaign.donations.recent.limit(20)
    @donation = Donation.new
  end
end
