class DonationsController < ApplicationController
  before_action :set_campaign
  before_action :require_active_campaign

  def create
    result = CreateDonation.new(campaign: @campaign, params: donation_params).call

    if result.success?
      redirect_to @campaign, notice: t("flash.donations.success")
    else
      @recent_donations = @campaign.donations.recent.limit(Campaign::RECENT_DONATIONS_LIMIT)
      @donation = result.donation
      @exchange_rates = exchange_rates_from_ils
      flash.now[:alert] = result.errors.join(", ")
      render "campaigns/show", status: :unprocessable_entity
    end
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end

  def require_active_campaign
    unless @campaign.active?
      redirect_to @campaign, alert: t("flash.donations.campaign_ended")
    end
  end

  def donation_params
    params.require(:donation).permit(
      :amount, :currency, :frequency, :months, :display_preference,
      :donor_name, :dedication_message, :idempotency_key
    )
  end
end
