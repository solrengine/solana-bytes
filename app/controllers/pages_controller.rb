class PagesController < ApplicationController
  def home
    # The centered hero (U4) replaced the prior 2-column layout that paired
    # the copy with a live-decoded USDC mint sample, so @featured_account is
    # no longer needed. The featured-account fetch was the only place we
    # consumed FEATURED_ACCOUNT_ADDRESS — both removed together.
    @public_stats = fetch_public_stats
  end

  # Static About page — U19. Tells the project's story for hackathon
  # judges, contributors, and curious visitors. No data; the view is the
  # whole thing.
  def about
  end

  private

  # Public, homepage-safe subset of the metrics tracked in /stats.
  # Excludes individual users, IPs, and granular game results.
  #
  # `bytes_decoded` (U5) sums the `size` property attached to each
  # `account_viewed` event. The aggregate is wrapped in its own rescue so a
  # SQLite or JSON-extract error on this single metric cannot blank the
  # other four — the homepage banner relies on the whole hash being valid.
  def fetch_public_stats
    Rails.cache.fetch("public_stats:home", expires_in: 5.minutes, race_condition_ttl: 30.seconds) do
      {
        accounts_analyzed: Ahoy::Event.where(name: "account_viewed").count,
        bytes_decoded:     sum_bytes_decoded,
        total_visits:      Ahoy::Visit.count,
        total_pageviews:   Ahoy::Event.where(name: "pageview").count,
        total_challenges:  Ahoy::Event.where(name: "challenge_started").count,
        total_countries:   Ahoy::Visit.where.not(country: [ nil, "" ]).distinct.count(:country)
      }
    end
  rescue StandardError
    nil
  end

  def sum_bytes_decoded
    Ahoy::Event
      .where(name: "account_viewed")
      .sum("CAST(json_extract(properties, '$.size') AS INTEGER)")
      .to_i
  rescue StandardError => e
    Rails.logger.warn("sum_bytes_decoded failed: #{e.class} #{e.message}")
    0
  end
end
