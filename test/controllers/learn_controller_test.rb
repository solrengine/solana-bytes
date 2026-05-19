require "test_helper"

class LearnControllerTest < ActionDispatch::IntegrationTest
  IN_SCOPE_SLUGS = %w[mint token-account stake-account vote-account token-metadata address-lookup-table].freeze

  test "GET /learn returns 200 and lists slugged entries + Other section" do
    get "/learn"
    assert_response :success
    # Top section: each slugged entry rendered as a card pointing at /learn/<slug>
    IN_SCOPE_SLUGS.each do |slug|
      assert_match %r{href="/learn/#{slug}"}, response.body,
        "/learn index should link to /learn/#{slug}"
    end
    # Bottom section: "Other account types" with the unslugged entries
    assert_includes response.body, "Other account types"
    # The unslugged entries appear in the Other section by name
    ["Multisig", "BPF Upgradeable Program"].each do |name|
      assert_includes response.body, name,
        "/learn index 'Other' section should list #{name.inspect}"
    end
  end

  test "GET /learn/:slug returns 200 for each in-scope slug" do
    IN_SCOPE_SLUGS.each do |slug|
      get "/learn/#{slug}"
      assert_response :success, "/learn/#{slug} should resolve"
    end
  end

  test "GET /learn/no-such-type returns 404" do
    get "/learn/no-such-type"
    assert_response :not_found
  end

  # The route constraint rejects uppercase / non-kebab slugs before the
  # controller runs.
  test "GET /learn/INVALID returns 404 via route constraint" do
    get "/learn/INVALID"
    assert_response :not_found
  end

  # U17 fetches the sample via RpcAccountFetcher → goes through the test
  # helper's StubRpcClient. When no stub is registered the fetcher returns
  # nil and the controller renders the fallback path; no exception.
  test "GET /learn/:slug renders fallback card when RPC sample is missing" do
    get "/learn/mint"
    assert_response :success
    assert_includes response.body, "Sample temporarily unavailable",
      "fallback card should render when the cached RPC fetch returns nil"
    # The explainer prose still renders even when the sample is missing
    assert_includes response.body, "An SPL Mint account defines a fungible token"
  end

  # Covers AE3 — explainer + cached live sample renders end-to-end when
  # the RPC stub registers a payload. Uses the Stake-Account sample so
  # the embedded compact hex view exercises a non-trivial decoder.
  test "GET /learn/:slug with a live sample renders explainer + embedded hex view" do
    stake_address = "CbrKVVDv6irzm4SYv8YnhJkN6wCTnYw9S7SqdwavCrRt"
    # Minimal initialized stake (state=1) — enough for the decoder to
    # produce regions without erroring.
    bytes = Array.new(200, 0)
    bytes[0] = 1 # state: Initialized
    RpcStubRegistry.responses[stake_address] = {
      "result" => { "value" => {
        "lamports" => 5_000_000_000, "owner" => "Stake11111111111111111111111111111111111111",
        "executable" => false, "rentEpoch" => 0, "space" => 200,
        "data" => [ Base64.strict_encode64(bytes.pack("C*")), "base64" ]
      }}
    }
    get "/learn/stake-account"
    assert_response :success
    # Explainer prose
    assert_includes response.body, "A Stake account delegates SOL"
    # Sample heading + cached caption
    assert_includes response.body, "Sample: Stake Account"
    assert_includes response.body, "(cached; refreshes hourly"
    # Embedded compact hex view (data-controller="hex-viewer" comes from
    # the shared _hex_view.html.erb partial)
    assert_includes response.body, 'data-controller="hex-viewer"'
    # "View full hex" CTA points at /accounts/<example_address>
    assert_includes response.body, "/accounts/#{stake_address}"
    assert_includes response.body, "View full hex"
    # Bottom exit affordances
    assert_includes response.body, "Back to Learn"
    assert_includes response.body, "Try the Byte Challenge"
  end

  # Address Lookup Tables can run up to ~8 KB. The controller passes
  # max_data: 10_240 (matching AccountsController) so the embedded sample
  # is NOT truncated for in-scope types. The presenter's `truncated`
  # marker would be nil; the "showing X of Y bytes" notice should not fire.
  test "GET /learn/address-lookup-table accepts 8KB samples without truncation" do
    address = "GbL3KvBBRXJArvft1KQPMUworMDormXNfo97hkbftsT5"
    # Build an 8000-byte ALT: 56-byte header (discriminator=1, rest zeros)
    # + ~248 32-byte address slots
    bytes = Array.new(8000, 0)
    bytes[0] = 1 # discriminator: LookupTable
    RpcStubRegistry.responses[address] = {
      "result" => { "value" => {
        "lamports" => 100_000_000, "owner" => "AddressLookupTab1e1111111111111111111111111",
        "executable" => false, "rentEpoch" => 0, "space" => 8000,
        "data" => [ Base64.strict_encode64(bytes.pack("C*")), "base64" ]
      }}
    }
    get "/learn/address-lookup-table"
    assert_response :success
    # No truncation notice should appear (max_data: 10_240 > 8000)
    refute_match %r{showing\s+\d+\s+of\s+\d+\s+bytes}i, response.body,
      "ALT sample should not be truncated at max_data: 10_240"
  end
end
