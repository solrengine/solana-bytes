class LearnController < ApplicationController
  # /learn — directory of slugged account types + an "Other types" tail
  # that surfaces the entries without a dedicated Learn page (Multisig,
  # Token-2022, BPF Upgradeable, ELF). See app/views/learn/index.html.erb.
  def index
    @entries = AccountTaxonomy.flat_entries.select { |e| e.slug }
    @others  = AccountTaxonomy.flat_entries.reject { |e| e.slug }
  end

  # /learn/:slug — per-type explainer + cached live sample (U17).
  def show
    @entry = AccountTaxonomy.find_by_slug(params[:slug])
    raise ActiveRecord::RecordNotFound, "No Learn entry for slug=#{params[:slug].inspect}" unless @entry

    # Cached server-side fetch — bypasses /accounts/* Rack::Attack quota
    # because no public route is hit. mainnet-beta pinned: the canonical
    # example addresses only exist on mainnet; a user on devnet who clicks
    # "View full hex →" may 404 on /accounts/:address (documented).
    sample = RpcAccountFetcher.fetch(
      @entry.example_address,
      network: "mainnet-beta",
      expires_in: 1.hour,
      race_condition_ttl: 30.seconds
    )
    sample_value = sample&.dig("result", "value")
    @presenter = if sample_value
      begin
        # max_data: 10_240 matches AccountsController default — covers the
        # largest in-scope sample (ALT up to ~8 KB) without truncation.
        AccountPresenter.new(@entry.example_address, sample_value, max_data: 10_240)
      rescue StandardError => e
        Rails.logger.warn("Learn sample decode failed for #{@entry.slug}: #{e.class} #{e.message}")
        nil
      end
    end
  end
end
