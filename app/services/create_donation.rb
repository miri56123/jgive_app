class CreateDonation
  Result = Struct.new(:success, :donation, :errors, keyword_init: true) do
    def success? = success
  end

  def initialize(campaign:, params:)
    @campaign = campaign
    @params   = params
  end

  def call
    donation = @campaign.donations.build(@params)
    donation.exchange_rate = ExchangeRateService.to_ils(donation.currency)

    if donation.save
      Rails.logger.info("[CreateDonation] created id=#{donation.id} campaign=#{@campaign.id} amount=#{donation.amount} #{donation.currency}")
      Result.new(success: true, donation: donation, errors: [])
    elsif (existing = duplicate(donation))
      Rails.logger.info("[CreateDonation] duplicate prevented key=#{donation.idempotency_key} existing_id=#{existing.id}")
      Result.new(success: true, donation: existing, errors: [])
    else
      Rails.logger.warn("[CreateDonation] validation failed campaign=#{@campaign.id} errors=#{donation.errors.full_messages}")
      Result.new(success: false, donation: donation, errors: donation.errors.full_messages)
    end
  end

  private

  def duplicate(donation)
    return nil if donation.idempotency_key.blank?
    return nil unless donation.errors[:idempotency_key].any?
    Donation.find_by(idempotency_key: donation.idempotency_key)
  end
end
