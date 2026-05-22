class LearnController < ApplicationController
  # GET /learn — directory grouped by category, plus an "Other types" rail
  # for drafts (entries with content but no published explainer yet).
  def index
    @categories = AccountTaxonomy.categories
    @drafts     = AccountTaxonomy.flat_entries.select(&:draft?)
  end

  # GET /learn/:slug — dispatches between category landing pages and
  # legacy entry-slug 301 redirects (e.g., /learn/mint → /learn/spl-token/mint).
  def category
    slug = params[:slug]

    if (cat = AccountTaxonomy.find_category(slug))
      @category = cat
      @live     = cat.live_entries
      @drafts   = cat.entries.select(&:draft?)
      render :category
      return
    end

    if (legacy = AccountTaxonomy.find_by_slug(slug))
      redirect_to legacy.learn_path, status: :moved_permanently
      return
    end

    raise ActiveRecord::RecordNotFound, "No Learn entry or category for slug=#{slug.inspect}"
  end

  # GET /learn/:category/:slug — canonical per-entry page.
  def show
    @entry = AccountTaxonomy.find_by_slug(params[:slug])
    raise ActiveRecord::RecordNotFound, "No Learn entry for slug=#{params[:slug].inspect}" unless @entry
    raise ActiveRecord::RecordNotFound, "Entry #{@entry.slug} lives in category #{@entry.category.inspect}, not #{params[:category].inspect}" if @entry.category != params[:category]

    @category = AccountTaxonomy.find_category(@entry.category)
    @presenter = fetch_sample(@entry) if @entry.kind == "account" && @entry.example_address.present?
  end

  private

  # Cached server-side fetch — bypasses the /accounts/* Rack::Attack quota
  # because no public route is hit. mainnet-beta pinned: the canonical
  # example addresses only exist on mainnet; a user on devnet who clicks
  # "View full hex →" may 404 on /accounts/:address (documented).
  def fetch_sample(entry)
    sample = RpcAccountFetcher.fetch(
      entry.example_address,
      network: "mainnet-beta",
      expires_in: 1.hour,
      race_condition_ttl: 30.seconds
    )
    sample_value = sample&.dig("result", "value")
    return nil unless sample_value

    # max_data: 10_240 matches AccountsController default — covers the
    # largest in-scope sample (ALT up to ~8 KB) without truncation.
    AccountPresenter.new(entry.example_address, sample_value, max_data: 10_240)
  rescue StandardError => e
    Rails.logger.warn("Learn sample decode failed for #{entry.slug}: #{e.class} #{e.message}")
    nil
  end
end
