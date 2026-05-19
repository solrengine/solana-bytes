require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  USDC_MINT = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v".freeze

  # Build an 82-byte SPL Mint payload. Decodes cleanly through RegionDecoder.
  def mint_response(byte_count: 82)
    base64 = Base64.strict_encode64(Array.new(byte_count, 0).pack("C*"))
    {
      "result" => {
        "context" => { "slot" => 12345 },
        "value" => {
          "lamports" => 369_583_392,
          "owner" => "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
          "executable" => false,
          "rentEpoch" => 0,
          "space" => byte_count,
          "data" => [ base64, "base64" ]
        }
      }
    }
  end

  test "GET /accounts/:address renders successfully with a valid sample" do
    RpcStubRegistry.responses[USDC_MINT] = mint_response(byte_count: 82)
    get "/accounts/#{USDC_MINT}"
    assert_response :success
  end

  test "GET /accounts/:address returns 503 when RPC fetch fails" do
    # No stub registered → StubRpcClient returns nil → controller hits the
    # 'Could not reach Solana network' branch.
    get "/accounts/#{USDC_MINT}"
    assert_response :service_unavailable
  end

  test "GET /accounts/:address with invalid base58 returns 422" do
    get "/accounts/not-a-valid-base58-address!"
    assert_response :unprocessable_entity
  end

  # The ahoy.track call carries `size: @account.data_length` so the
  # bytes_decoded counter (U5) can aggregate it. The aggregate behavior is
  # covered in pages_controller_test.rb by seeding events directly with the
  # `size` property — proving the SQL formula. The controller line itself
  # ("ahoy.track ..., size: @account.data_length") is a one-liner left to
  # code review rather than tested through the full Ahoy::Visit FK stack.
end
