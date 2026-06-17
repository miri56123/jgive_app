class DonationsController < ApplicationController
  before_action :set_campaign

  def create
    result = CreateDonation.new(campaign: @campaign, params: donation_params).call

    if result.success?
      redirect_to @campaign, notice: "תודה על תרומתך! קיבלנו את פרטיך ונצור איתך קשר להשלמת התשלום."
    else
      @recent_donations = @campaign.donations.recent.limit(20)
      @donation = result.donation
      flash.now[:alert] = result.errors.join(", ")
      render "campaigns/show", status: :unprocessable_entity
    end
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end

  def donation_params
    params.require(:donation).permit(
      :amount, :frequency, :display_preference, :donor_name, :dedication_message
    )
  end
end
