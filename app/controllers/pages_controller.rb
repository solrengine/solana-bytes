class PagesController < ApplicationController
  FEATURED_ACCOUNT_ADDRESS = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v".freeze

  def home
    account_data = RpcAccountFetcher.fetch(FEATURED_ACCOUNT_ADDRESS, network: "mainnet-beta", expires_in: 1.hour, race_condition_ttl: 30.seconds)
    account_value = account_data&.dig("result", "value")
    @featured_account = account_value ? AccountPresenter.new(FEATURED_ACCOUNT_ADDRESS, account_value) : nil
  end
end
