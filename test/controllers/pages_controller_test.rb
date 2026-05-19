require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET / returns 200 and renders the hero band" do
    get "/"
    assert_response :success
    assert_includes response.body, "A field guide to Solana accounts."
    assert_includes response.body, "Solana Bytes shows you, and lets you prove you understand."
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

  # --- Live-decoded hero ---

  USDC_MINT_ADDRESS = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"

  # Build a valid 82-byte SPL Mint payload (all-zero authorities, supply 0,
  # decimals 0). Decodes cleanly through RegionDecoder; produces 7 named regions.
  def usdc_sample_account_response(bytes_array: Array.new(82, 0))
    base64 = Base64.strict_encode64(bytes_array.pack("C*"))
    {
      "result" => {
        "context" => { "slot" => 12345 },
        "value" => {
          "lamports" => 369_583_392,
          "owner" => "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
          "executable" => false,
          "rentEpoch" => 0,
          "space" => 82,
          "data" => [ base64, "base64" ]
        }
      }
    }
  end

  test "hero renders interactive hex grid when featured account loads successfully" do
    RpcStubRegistry.responses[USDC_MINT_ADDRESS] = usdc_sample_account_response
    get "/"
    assert_response :success
    assert_match %r{class="hidden md:block[^"]*"}, response.body
    assert_includes response.body, "USDC mint, decoded — hover any byte"
    assert_includes response.body, 'data-controller="hex-viewer"'
    assert_includes response.body, "Mint Authority Option"
    assert_includes response.body, "Supply"
  end

  # Graceful fallback when the sample is unavailable: hero copy and the
  # type-picker grid both still render so the page never falls back to
  # an empty state.
  test "hero degrades cleanly when featured account cannot be loaded" do
    get "/"
    assert_response :success
    assert_includes response.body, "A field guide to Solana accounts."
    assert_includes response.body, "Solana Bytes shows you, and lets you prove you understand."
    # Type-picker still renders — sample a couple of stable entry names
    assert_includes response.body, "Mint"
    assert_includes response.body, "Token Account"
    # Hero partial caption is NOT present (partial did not render)
    refute_includes response.body, "USDC mint, decoded — hover any byte"
  end

  # The hero partial wraps the hex grid in `hidden md:block`. Anchor on the
  # endorsements section heading (which immediately follows the hero) to
  # scope the regex to the hero region.
  test "hero hex grid is hidden on mobile via Tailwind responsive utility" do
    RpcStubRegistry.responses[USDC_MINT_ADDRESS] = usdc_sample_account_response
    get "/"
    assert_response :success
    hero_section = response.body.match(/Solana Bytes shows you(?:.*?)(?=FROM THE SOLANA ECOSYSTEM)/m).to_s
    assert_match %r{hidden md:block}, hero_section,
      "Hero partial should carry `hidden md:block` so the hex grid hides at mobile widths"
  end

  # Hero hex cells must remain hover-only (no anchor wrappers) so clicks
  # don't navigate. Scoped to the region between the hero caption and the
  # endorsements heading.
  test "hero hex grid cells are not wrapped in anchor links" do
    RpcStubRegistry.responses[USDC_MINT_ADDRESS] = usdc_sample_account_response
    get "/"
    assert_response :success
    hero_section = response.body.match(/USDC mint, decoded(?:.*?)(?=FROM THE SOLANA ECOSYSTEM)/m).to_s
    refute_match %r{<a[^>]*>\s*<td[^>]*data-region}, hero_section,
      "Hero hex cells must not be wrapped in anchor tags (hover-only, non-navigating)"
  end
end
