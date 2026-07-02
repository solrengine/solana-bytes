class PagesController < ApplicationController
  # USDC mint — 82 bytes, instantly recognizable, fully decoded by the
  # Mint layout. Shown live on the landing so visitors see the product
  # before reading about it.
  FEATURED_ACCOUNT_ADDRESS = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v".freeze

  def home
    @public_stats = fetch_public_stats
    @featured_account = fetch_featured_account
  end

  # Static About page — U19. Tells the project's story for hackathon
  # judges, contributors, and curious visitors. No data; the view is the
  # whole thing.
  def about
  end

  private

  # Live decode sample for the landing. Cached for an hour (mint layouts
  # are effectively static) and fully optional — any RPC or decode failure
  # hides the section instead of degrading the homepage.
  def fetch_featured_account
    result = RpcAccountFetcher.fetch(FEATURED_ACCOUNT_ADDRESS, network: "mainnet-beta", expires_in: 1.hour)
    value = result&.dig("result", "value")
    return nil if value.nil?

    AccountPresenter.new(FEATURED_ACCOUNT_ADDRESS, value, max_data: 256)
  rescue StandardError => e
    Rails.logger.error("Featured account decode failed: #{e.class} #{e.message}")
    nil
  end

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
