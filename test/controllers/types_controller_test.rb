require "test_helper"

class TypesControllerTest < ActionDispatch::IntegrationTest
  test "GET /types returns 200" do
    get "/types"
    assert_response :success
  end

  test "GET /types lists all expected group names" do
    get "/types"
    [ "SPL Token", "Token-2022 Extensions", "Staking &amp; Voting", "Metaplex (NFTs)", "Programs (Executable)" ].each do |group|
      assert_includes response.body, group
    end
  end

  test "GET /types lists every entry name" do
    get "/types"
    AccountTaxonomy.flat_entries.each do |entry|
      assert_includes response.body, entry.name, "Expected entry '#{entry.name}' in /types response"
    end
  end

  test "GET /types links each example to the account hex viewer" do
    get "/types"
    AccountTaxonomy.flat_entries.each do |entry|
      next unless entry.example_address
      assert_includes response.body, "/accounts/#{entry.example_address}"
    end
  end
end
