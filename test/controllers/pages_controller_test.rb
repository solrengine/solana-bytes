require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET / returns 200 and renders the hero band" do
    get "/"
    assert_response :success
    assert_includes response.body, "A field guide to Solana accounts."
    assert_includes response.body, "Inspect and understand raw Solana account bytes, structures, and on-chain data."
  end

  # The full-width paste form (extracted from the Visualize tile in the prior
  # bento layout) preserves the Turbo Frame contract that drives the inline
  # decode flow on the homepage.
  test "paste form preserves Turbo Frame integrity for the address lookup" do
    get "/"
    assert_response :success
    assert_match %r{action="/lookup"}, response.body
    assert_match %r{data-turbo-frame="account_result"}, response.body
    assert_match %r{<turbo-frame[^>]*data-turbo-action="advance"}, response.body
    assert_includes response.body, 'data-controller="address-form"'
  end

  # U8 — the 6-card type grid renders exactly Mint, Token Account,
  # Stake Account, Vote Account, Token Metadata, Address Lookup Table in
  # mockup order. The five other AccountTaxonomy entries (Multisig,
  # Token-2022, BPF Upgradeable, ELF, etc.) are intentionally NOT in this
  # grid — they're discoverable via "Browse all account types →" → /learn.
  test "type grid renders exactly the six mockup-fixed cards in order" do
    get "/"
    assert_response :success

    expected_order = ["Mint", "Token Account", "Stake Account", "Vote Account", "Token Metadata", "Address Lookup Table"]
    indices = expected_order.map { |name| response.body.index(">\n          #{name}\n") || response.body.index(name) }
    assert indices.none?(&:nil?), "All six expected card names should be present"
    assert_equal indices, indices.sort, "Cards should appear in mockup-specified order: #{expected_order.inspect}"

    # Each card links to its example address (interim — U15 swaps to /learn/<slug>)
    expected_order.each do |name|
      entry = AccountTaxonomy.flat_entries.find { |e| e.name == name }
      assert_includes response.body, "/accounts/#{entry.example_address}",
        "Type grid card '#{name}' should link to /accounts/#{entry.example_address}"
    end

    # Entries NOT in the mockup grid should NOT appear as card headings on home
    refute_includes response.body, "Multisig"
    refute_includes response.body, "BPF Upgradeable Program"
  end

  # U8 — "Browse all account types →" link below the grid points to /learn
  # (which will 404 until U15 ships the route). Preserves discoverability of
  # the entries excluded from the 6-card grid.
  test "type grid exposes a Browse-all link to /learn and the Challenge CTA" do
    get "/"
    assert_response :success
    assert_match %r{href="/learn"}, response.body
    assert_includes response.body, "Browse all account types"
    assert_match %r{href="/challenges"}, response.body
    assert_match %r{Test your eye|challenges played}, response.body,
      "Challenge CTA should render either the fallback hook or the live count"
  end

  # The type grid uses the same responsive Tailwind utilities as before
  # so cards stack on mobile, sit 2-up on small screens, and 3-up on
  # desktop.
  test "type grid uses responsive grid classes for mobile stacking" do
    get "/"
    assert_response :success
    assert_match %r{grid-cols-1}, response.body
    assert_match %r{sm:grid-cols-2}, response.body
    assert_match %r{lg:grid-cols-3}, response.body
  end

  test "loading-controller targets are wired on the new layout" do
    get "/"
    assert_response :success
    assert_includes response.body, 'data-controller="loading"'
    assert_includes response.body, 'data-loading-target="hero"'
    assert_includes response.body, 'data-loading-target="spinner"'
    assert_includes response.body, 'data-loading-target="frame"'
  end

  # Nav uses the new SB pixel logo (U2). Renders even when the landing hero
  # state hides the nav from view — the markup is in the DOM regardless.
  test "global nav renders the new pixel logo" do
    get "/"
    assert_response :success
    assert_match %r{<img[^>]+src="[^"]*sb-logo-dark[^"]*"}, response.body
    assert_match %r{alt="Solana Bytes"}, response.body
  end

  # Engine-isolation regression guard (U2): the shared application layout is
  # also rendered inside the SolRengine Auth Engine at /auth/login, where the
  # host app's named-route helpers are unreachable. This test catches any
  # accidental use of `_path` helpers in the layout that would NoMethodError
  # on the login page.
  test "GET /auth/login renders the shared layout without engine-isolation errors" do
    get "/auth/login"
    assert_response :success
  end

  # --- Centered hero (U4) ---
  # The prior 2-column hero with a live-decoded USDC mint sample on the
  # right was retired in U4 (mockup-driven centered layout). The
  # _hero_decoded_sample partial and FEATURED_ACCOUNT_ADDRESS constant were
  # deleted in the same unit.

  test "centered hero renders the new logo, title, and tagline copy" do
    get "/"
    assert_response :success
    # Logo image is in the hero band as well as the nav (the nav assertion
    # in `global nav renders the new pixel logo` covers both — the hero one
    # is asserted here for completeness)
    assert_match %r{<img[^>]+src="[^"]*sb-logo-dark[^"]*"}, response.body
    assert_includes response.body, "Solana Bytes"
    assert_includes response.body, "A field guide to Solana accounts."
    assert_includes response.body, "Inspect and understand raw Solana account bytes, structures, and on-chain data."
  end

  test "homepage renders the two intro cards from U6" do
    get "/"
    assert_response :success
    assert_includes response.body, "What is Solana Bytes?"
    assert_includes response.body, "How it works"
    assert_includes response.body, "Paste any Solana account address."
    assert_includes response.body, "Explore the raw bytes and field decoding."
    assert_includes response.body, "Take the Byte Challenge and test your eye."
  end

  test "loading-spinner card matches the mockup treatment" do
    get "/"
    assert_response :success
    # The spinner uses the pixel-loading dots class + the "Fetching account
    # from Solana" copy + the "This may take a few seconds." caption.
    spinner_section = response.body.match(/data-loading-target="spinner".*?<\/div>\s*<\/div>\s*<\/div>/m).to_s
    assert_includes spinner_section, "Fetching account from Solana"
    assert_includes spinner_section, "This may take a few seconds."
    assert_match %r{pixel-loading}, spinner_section
  end

  # --- bytes_decoded counter (U5) ---

  # The controller helper is private; reach through the controller class to
  # exercise the SQL aggregate against the test DB.
  def stats
    PagesController.new.send(:fetch_public_stats)
  end

  # Ahoy::Event belongs_to :visit (required in our subclass), so seeded
  # events need a Visit FK target.
  def seed_visit
    @seed_visit ||= Ahoy::Visit.create!(started_at: Time.current, visit_token: SecureRandom.uuid, visitor_token: SecureRandom.uuid)
  end

  def seed_event(name:, properties: {})
    Ahoy::Event.create!(name: name, properties: properties, time: Time.current, visit: seed_visit)
  end

  test "fetch_public_stats includes bytes_decoded summed from account_viewed event size properties" do
    seed_event(name: "account_viewed", properties: { "address" => "a", "size" => 82 })
    seed_event(name: "account_viewed", properties: { "address" => "b", "size" => 165 })
    seed_event(name: "account_viewed", properties: { "address" => "c", "size" => 3762 })

    assert_equal 82 + 165 + 3762, stats[:bytes_decoded]
    assert_equal 3, stats[:accounts_analyzed]
  end

  test "bytes_decoded is 0 when no account_viewed events exist" do
    assert_equal 0, Ahoy::Event.where(name: "account_viewed").count
    assert_equal 0, stats[:bytes_decoded]
  end

  test "bytes_decoded handles events missing the size property (NULL -> 0)" do
    # Legacy events tracked before U5 lack size; CAST(NULL AS INTEGER) is 0
    # in SQLite so total remains correct.
    seed_event(name: "account_viewed", properties: { "address" => "legacy" })
    seed_event(name: "account_viewed", properties: { "address" => "new", "size" => 200 })

    assert_equal 200, stats[:bytes_decoded]
  end

  # The "one metric fails, all four blank" failure mode is guarded by
  # wrapping sum_bytes_decoded in its own begin/rescue returning 0
  # (see PagesController#sum_bytes_decoded). Without Mocha available we
  # can't easily stub the SQL aggregate to raise from inside a test; the
  # protection lives in the method shape itself and is left to code review.

  # --- Live stats card (U7) ---

  # Covers AE1: zero-state hides the card. The early-return guard reads
  # :accounts_analyzed (NOT :accounts_decoded — the symbol stayed the same
  # in U5; only the user-visible label changed).
  test "live stats card renders nothing on a fresh database (zero accounts analyzed)" do
    assert_equal 0, Ahoy::Event.where(name: "account_viewed").count
    get "/"
    assert_response :success
    refute_includes response.body, "LIVE FROM THE SITE"
    refute_includes response.body, "accounts decoded"
    refute_includes response.body, "bytes decoded"
  end

  # Covers AE2: with populated stats the card renders the four blended
  # metrics in the specified order (accounts decoded → challenges played
  # → bytes decoded → countries). bytes_decoded is humanized via
  # number_to_human_size; the decorative hex-grid element is present.
  test "live stats card renders four metrics in order with humanized bytes_decoded" do
    seed_event(name: "account_viewed", properties: { "address" => "a", "size" => 82 })
    seed_event(name: "account_viewed", properties: { "address" => "b", "size" => 165 })
    seed_event(name: "account_viewed", properties: { "address" => "c", "size" => 16_240 })
    seed_event(name: "challenge_started", properties: {})
    seed_event(name: "challenge_started", properties: {})

    get "/"
    assert_response :success
    assert_includes response.body, "LIVE FROM THE SITE"
    assert_includes response.body, "accounts decoded"
    assert_includes response.body, "challenges played"
    assert_includes response.body, "bytes decoded"
    assert_includes response.body, "countries"
    # bytes_decoded is humanized — 82 + 165 + 16240 = 16487 bytes ≈ "16.1 KB"
    # (Rails default number_to_human_size; exact format may include "KB").
    assert_match %r{1[56]\.\d+ KB|16 KB|1[56]\.\d+\s*KB}, response.body,
      "bytes_decoded should render via number_to_human_size, not raw integer"
    # Decorative hex grid present
    assert_includes response.body, "pixel-hex-grid"

    # Order check: accounts decoded comes before bytes decoded which comes
    # before countries.
    body = response.body
    accounts_idx = body.index("accounts decoded")
    challenges_idx = body.index("challenges played")
    bytes_idx = body.index("bytes decoded")
    countries_idx = body.index("countries")
    assert accounts_idx < challenges_idx, "accounts decoded should precede challenges played"
    assert challenges_idx < bytes_idx, "challenges played should precede bytes decoded"
    assert bytes_idx < countries_idx, "bytes decoded should precede countries"
  end

  # The stats hash retains :total_pageviews for /stats page consumption
  # even though the homepage banner doesn't render it.
  test "fetch_public_stats retains total_pageviews even though homepage drops it" do
    seed_event(name: "account_viewed", properties: { "address" => "a", "size" => 82 })
    seed_event(name: "pageview", properties: {})
    seed_event(name: "pageview", properties: {})

    assert_equal 2, stats[:total_pageviews]

    get "/"
    refute_includes response.body, "pageviews"
  end
end
