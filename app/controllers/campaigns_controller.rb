class CampaignsController < ApplicationController
  def show
    @campaign = Campaign.find(params[:id])
    @recent_donations = @campaign.donations.paid.recent.limit(20)
    @donation = Donation.new
  end
end
