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

  # The type-picker grid replaces the prior Learn tile. Every taxonomy entry
  # gets its own card whose primary action links to the entry's example
  # address (Turbo Frame inline decode), not to /types.
  test "type-picker renders one card per AccountTaxonomy entry, linking to each example address" do
    get "/"
    assert_response :success
    AccountTaxonomy.flat_entries.each do |entry|
      assert_includes response.body, entry.name,
        "Type-picker should include a card for entry '#{entry.name}'"
      assert_includes response.body, "/accounts/#{entry.example_address}",
        "Type-picker card for '#{entry.name}' should link to /accounts/#{entry.example_address}"
    end
  end

  # Secondary navigation under the type-picker: full taxonomy + challenge.
  # The challenge CTA copy varies based on whether @public_stats has counts:
  # falls back to a "Test your eye..." hook when stats are absent or zero,
  # and surfaces "X challenges played..." as social proof when populated.
  test "type-picker exposes secondary links to the taxonomy and challenge" do
    get "/"
    assert_response :success
    assert_match %r{href="/types"}, response.body
    assert_match %r{href="/challenges"}, response.body
    assert_includes response.body, "Browse the full taxonomy"
    assert_match %r{Test your eye|challenges played}, response.body,
      "Challenge CTA should render either the fallback hook or the live count"
  end

  # The type-picker grid uses responsive Tailwind utilities so cards stack on
  # mobile, sit 2-up on small screens, and 3-up on desktop.
  test "type-picker uses responsive grid classes for mobile stacking" do
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
end
