require "test_helper"

class LearnControllerTest < ActionDispatch::IntegrationTest
  LIVE_SLUGS = %w[mint token-account stake-account vote-account token-metadata address-lookup-table].freeze

  test "GET /learn returns 200 and links to live entries by canonical URL" do
    get "/learn"
    assert_response :success
    # Each live entry is rendered as a card linking to its canonical
    # /learn/<category>/<slug> URL (U22).
    LIVE_SLUGS.each do |slug|
      entry = AccountTaxonomy.find_by_slug(slug)
      assert_match %r{href="#{Regexp.escape(entry.learn_path)}"}, response.body,
        "/learn index should link to #{entry.learn_path}"
    end
    # The "Other account types" section lists drafts.
    assert_includes response.body, "Other account types"
    [ "Multisig", "BPF Upgradeable Program" ].each do |name|
      assert_includes response.body, name,
        "/learn index 'Other' section should list #{name.inspect}"
    end
  end

  test "GET /learn/:category/:slug returns 200 for each live entry" do
    LIVE_SLUGS.each do |slug|
      entry = AccountTaxonomy.find_by_slug(slug)
      get entry.learn_path
      assert_response :success, "#{entry.learn_path} should resolve"
    end
  end

  # Dynamic coverage: every live entry must render at its canonical URL.
  # Catches any new page that loads in the model but errors in the view
  # (bad cross-link slug, kramdown failure, missing partial, etc.).
  test "every live entry renders 200 at its canonical URL" do
    AccountTaxonomy.flat_entries.select(&:live?).each do |entry|
      get entry.learn_path
      assert_response :success, "#{entry.learn_path} (#{entry.name}) should render"
      # Names may contain HTML-special chars (e.g. "&"); compare escaped.
      assert_includes response.body, ERB::Util.html_escape(entry.name)
    end
  end

  # Every live entry must appear on its category landing page.
  test "every live entry is listed on its category page" do
    AccountTaxonomy.flat_entries.select(&:live?).map(&:category).uniq.each do |cat_slug|
      get "/learn/#{cat_slug}"
      assert_response :success
    end
  end

  test "GET /learn/:category/:bad-slug returns 404" do
    get "/learn/spl-token/no-such-entry"
    assert_response :not_found
  end

  test "GET /learn/:wrong-category/:slug returns 404 (category guard)" do
    # mint lives in spl-token; requesting it under consensus must not resolve.
    get "/learn/consensus/mint"
    assert_response :not_found
  end

  test "GET /learn/INVALID returns 404 via route constraint" do
    get "/learn/INVALID"
    assert_response :not_found
  end

  test "GET /learn/<category> renders the category landing page" do
    get "/learn/spl-token"
    assert_response :success
    assert_includes response.body, "SPL Token"
    assert_includes response.body, "Mint"
    assert_includes response.body, "Token Account"
  end

  test "GET /learn/<legacy-slug> 301-redirects to canonical URL" do
    LIVE_SLUGS.each do |slug|
      get "/learn/#{slug}"
      assert_response :moved_permanently
      assert_equal AccountTaxonomy.find_by_slug(slug).learn_path, response.location.sub(/\Ahttps?:\/\/[^\/]+/, "")
    end
  end

  test "GET /learn/unknown-single-segment returns 404" do
    # Neither a category nor a legacy entry slug — must 404, not redirect.
    get "/learn/nonexistent-thing"
    assert_response :not_found
  end

  test "GET /learn/<category>/<slug> renders fallback card when RPC sample is missing" do
    get "/learn/spl-token/mint"
    assert_response :success
    assert_includes response.body, "Sample temporarily unavailable",
      "fallback card should render when the cached RPC fetch returns nil"
    # Body is rendered via kramdown — the rendered HTML contains the
    # opening prose from the markdown file.
    assert_includes response.body, "An SPL Mint account defines a fungible token"
  end

  test "GET /learn/:category/:slug with a live sample renders body + embedded hex view" do
    stake_address = "CbrKVVDv6irzm4SYv8YnhJkN6wCTnYw9S7SqdwavCrRt"
    # Minimal initialized stake (state=1) — enough for the decoder to
    # produce regions without erroring.
    bytes = Array.new(200, 0)
    bytes[0] = 1
    RpcStubRegistry.responses[stake_address] = {
      "result" => { "value" => {
        "lamports" => 5_000_000_000, "owner" => "Stake11111111111111111111111111111111111111",
        "executable" => false, "rentEpoch" => 0, "space" => 200,
        "data" => [ Base64.strict_encode64(bytes.pack("C*")), "base64" ]
      } }
    }
    get "/learn/consensus/stake-account"
    assert_response :success
    # Prose (kramdown-rendered) keeps the opening line of the body.
    assert_includes response.body, "A Stake account delegates SOL"
    # Sample heading + cached caption.
    assert_includes response.body, "Sample: Stake Account"
    assert_includes response.body, "(cached; refreshes hourly"
    # Embedded compact hex view comes from the shared partial.
    assert_includes response.body, 'data-controller="hex-viewer"'
    assert_includes response.body, "/accounts/#{stake_address}"
    assert_includes response.body, "View full hex"
    assert_includes response.body, "Back to Learn"
    assert_includes response.body, "Try the Byte Challenge"
  end

  test "GET /learn/transactions/address-lookup-table accepts 8KB samples without truncation" do
    address = "GbL3KvBBRXJArvft1KQPMUworMDormXNfo97hkbftsT5"
    bytes = Array.new(8000, 0)
    bytes[0] = 1
    RpcStubRegistry.responses[address] = {
      "result" => { "value" => {
        "lamports" => 100_000_000, "owner" => "AddressLookupTab1e1111111111111111111111111",
        "executable" => false, "rentEpoch" => 0, "space" => 8000,
        "data" => [ Base64.strict_encode64(bytes.pack("C*")), "base64" ]
      } }
    }
    get "/learn/transactions/address-lookup-table"
    assert_response :success
    refute_match %r{showing\s+\d+\s+of\s+\d+\s+bytes}i, response.body,
      "ALT sample should not be truncated at max_data: 10_240"
  end

  test "GET /learn/:category/:slug for a draft renders the body-pending banner" do
    get "/learn/spl-token/multisig"
    assert_response :success
    # Draft banner copy.
    assert_includes response.body, "still being written"
    # Multisig has no body so the markdown card should be absent.
    refute_includes response.body, 'id="learn-body"'
  end

  test "GET /learn/:category/:slug renders kramdown tables (Byte layout)" do
    get "/learn/spl-token/mint"
    assert_response :success
    # Kramdown GFM turns Markdown tables into <table>; the layout header
    # row from mint.md must show up as a real table cell.
    assert_match %r{<table[^>]*>.*Offset.*Length.*Field.*Notes.*</table>}m,
      response.body,
      "Mint body should render the Byte layout as an HTML <table>"
  end
end
