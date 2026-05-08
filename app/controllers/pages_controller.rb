class PagesController < ApplicationController
  FEATURED_ACCOUNT_ADDRESS = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v".freeze

  def home
    account_data = RpcAccountFetcher.fetch(FEATURED_ACCOUNT_ADDRESS, network: "mainnet-beta", expires_in: 1.hour, race_condition_ttl: 30.seconds)
    account_value = account_data&.dig("result", "value")
    @featured_account = account_value ? AccountPresenter.new(FEATURED_ACCOUNT_ADDRESS, account_value) : nil
    @public_stats = fetch_public_stats
  end

  private

  # Public, homepage-safe subset of the metrics tracked in /stats.
  # Excludes individual users, IPs, and granular game results.
  def fetch_public_stats
    Rails.cache.fetch("public_stats:home", expires_in: 5.minutes, race_condition_ttl: 30.seconds) do
      {
        accounts_analyzed: Ahoy::Event.where(name: "account_viewed").count,
        total_visits:      Ahoy::Visit.count,
        total_pageviews:   Ahoy::Event.where(name: "pageview").count,
        total_challenges:  Ahoy::Event.where(name: "challenge_started").count,
        total_countries:   Ahoy::Visit.where.not(country: [ nil, "" ]).distinct.count(:country)
      }
    end
  rescue StandardError
    nil
  end
end
