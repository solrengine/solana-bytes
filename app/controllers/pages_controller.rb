class PagesController < ApplicationController
  def home
    # The centered hero (U4) replaced the prior 2-column layout that paired
    # the copy with a live-decoded USDC mint sample, so @featured_account is
    # no longer needed. The featured-account fetch was the only place we
    # consumed FEATURED_ACCOUNT_ADDRESS — both removed together.
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
