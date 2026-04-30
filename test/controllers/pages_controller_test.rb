require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET / returns 200 and renders the hero band" do
    get "/"
    assert_response :success
    assert_includes response.body, "A field guide to Solana accounts."
    assert_includes response.body, "Solana Bytes shows you, and lets you prove you understand."
  end

  # Covers AE1: form posts to /lookup with account_result Turbo Frame target
  test "Visualize tile preserves Turbo Frame integrity for the address form" do
    get "/"
    assert_response :success
    # Form action points at /lookup
    assert_match %r{action="/lookup"}, response.body
    # Form targets the account_result Turbo Frame
    assert_match %r{data-turbo-frame="account_result"}, response.body
    # turbo_frame_tag carries turbo_action="advance"
    assert_match %r{<turbo-frame[^>]*data-turbo-action="advance"}, response.body
    # Stimulus address-form controller still attached
    assert_includes response.body, 'data-controller="address-form"'
  end

  # Covers AE2: 10 chips link to /types from the Learn tile
  test "Learn tile shows one chip per AccountTaxonomy entry plus a CTA, all linking to /types" do
    get "/"
    assert_response :success
    # Count /types links inside the Learn tile region.
    # Anchor on the tile subhead text (unique to the tile; not present in the
    # navbar) and slice up to the Play tile heading.
    learn_section = response.body.match(/account types, byte-by-byte(?:.*?)(?=Play)/m).to_s
    types_links_in_learn = learn_section.scan(%r{href="/types"}).length
    # 10 chips (AccountTaxonomy.flat_entries.length) + 1 primary CTA
    assert_equal AccountTaxonomy.flat_entries.length + 1, types_links_in_learn,
      "Learn tile should contain one /types link per entry plus the CTA"
    # Sanity: every taxonomy entry name appears as chip text in the Learn region
    AccountTaxonomy.flat_entries.each do |entry|
      assert_includes learn_section, entry.name,
        "Learn tile should include a chip for entry '#{entry.name}'"
    end
  end

  # Play tile shows the 3-step "How to Play" explainer (top streaks intentionally
  # omitted from / per design revision; the leaderboard remains visible on /challenges
  # and /leaderboard).
  test "Play tile shows compact body bullets and CTA to /challenges" do
    get "/"
    assert_response :success
    # Compact body bullets in the narrow Play tile
    assert_includes response.body, "3 lives, no hints"
    assert_includes response.body, "Build streaks"
    assert_includes response.body, "Climb the leaderboard"
    # CTA links to /challenges
    assert_match %r{href="/challenges"}, response.body
    # Top streaks partial should NOT render on / under the current design
    refute_includes response.body, "No scores yet — be the first!"
  end

  # Covers AE5: smoke check that responsive grid classes are rendered.
  # Layout is 3 equal-weight columns on desktop (Visualize / Learn / Play),
  # stacking vertically on mobile.
  test "Bento layout uses responsive grid classes for mobile stacking" do
    get "/"
    assert_response :success
    assert_match %r{grid-cols-1}, response.body
    assert_match %r{md:grid-cols-3}, response.body
  end

  test "all three tile headings are present" do
    get "/"
    assert_response :success
    assert_match %r{>\s*Visualize\s*<}, response.body
    assert_match %r{>\s*Learn\s*<}, response.body
    assert_match %r{>\s*Play\s*<}, response.body
  end

  test "loading-controller targets are wired on the new layout" do
    get "/"
    assert_response :success
    assert_includes response.body, 'data-controller="loading"'
    assert_includes response.body, 'data-loading-target="hero"'
    assert_includes response.body, 'data-loading-target="spinner"'
    assert_includes response.body, 'data-loading-target="frame"'
  end

  # --- Live-decoded hero (Idea #1, plan U1) ---

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

  # Covers AE1: hero hex grid renders when the cached/fetched sample is available
  test "hero renders interactive hex grid when featured account loads successfully" do
    RpcStubRegistry.responses[USDC_MINT_ADDRESS] = usdc_sample_account_response
    get "/"
    assert_response :success
    # The hero partial wraps the hex_view in a hidden md:block container
    assert_match %r{class="hidden md:block[^"]*"}, response.body
    # The hero caption identifies the sample
    assert_includes response.body, "USDC mint, decoded — hover any byte"
    # The hex_view partial mounts a hex-viewer Stimulus controller (the existing one)
    assert_includes response.body, 'data-controller="hex-viewer"'
    # The decoded SPL Mint produces 7 regions; "Mint Authority Option" and "Supply" are signature labels
    assert_includes response.body, "Mint Authority Option"
    assert_includes response.body, "Supply"
  end

  # Covers AE3: graceful fallback when the sample is unavailable
  test "hero degrades cleanly when featured account cannot be loaded" do
    # No response registered for USDC mint → stub returns nil → controller leaves @featured_account = nil
    get "/"
    assert_response :success
    # Hero copy still renders
    assert_includes response.body, "A field guide to Solana accounts."
    assert_includes response.body, "Solana Bytes shows you, and lets you prove you understand."
    # Bento tiles still render
    assert_match %r{>\s*Visualize\s*<}, response.body
    assert_match %r{>\s*Learn\s*<}, response.body
    assert_match %r{>\s*Play\s*<}, response.body
    # Hero partial caption is NOT present (partial did not render)
    refute_includes response.body, "USDC mint, decoded — hover any byte"
  end

  # Covers AE4: mobile-hide class is wired on the hero partial
  test "hero hex grid is hidden on mobile via Tailwind responsive utility" do
    RpcStubRegistry.responses[USDC_MINT_ADDRESS] = usdc_sample_account_response
    get "/"
    assert_response :success
    # The hero partial's outer wrapper carries `hidden md:block`. The Bento grid uses
    # `grid-cols-1 md:grid-cols-2`, so a substring match scoped to the segment between
    # the hero subhead text and the start of the Bento grid catches the partial.
    hero_section = response.body.match(/Solana Bytes shows you(?:.*?)(?=>\s*Visualize\s*<)/m).to_s
    assert_match %r{hidden md:block}, hero_section,
      "Hero partial should carry `hidden md:block` so the hex grid hides at mobile widths"
  end

  # Covers AE2: hero hex grid is hover-only — clicking does not navigate
  test "hero hex grid cells are not wrapped in anchor links" do
    RpcStubRegistry.responses[USDC_MINT_ADDRESS] = usdc_sample_account_response
    get "/"
    assert_response :success
    # The hex_view partial emits cells as <td> elements without enclosing <a> wrappers.
    # Pull the hero region (between caption and first Bento class) and assert no <a tag
    # appears immediately around `data-region`.
    hero_section = response.body.match(/USDC mint, decoded(?:.*?)(?=>\s*Visualize\s*<)/m).to_s
    refute_match %r{<a[^>]*>\s*<td[^>]*data-region}, hero_section,
      "Hero hex cells must not be wrapped in anchor tags (hover-only, non-navigating)"
  end
end
