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
      Result.new(success: true, donation: donation, errors: [])
    else
      Result.new(success: false, donation: donation, errors: donation.errors.full_messages)
    end
  end
end
