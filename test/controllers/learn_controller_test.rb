require "test_helper"

class LearnControllerTest < ActionDispatch::IntegrationTest
  IN_SCOPE_SLUGS = %w[mint token-account stake-account vote-account token-metadata address-lookup-table].freeze

  test "GET /learn returns 200" do
    get "/learn"
    assert_response :success
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
  test "GET /learn/:slug handles a missing RPC sample without raising" do
    get "/learn/mint"
    assert_response :success
  end
end
