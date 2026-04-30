require "test_helper"

class AccountPresenterTest < ActiveSupport::TestCase
  TOKEN_PROGRAM = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
  UNKNOWN_OWNER = "So11111111111111111111111111111111111111112"
  ELF_MAGIC = [ 0x7f, 0x45, 0x4c, 0x46 ].freeze

  def build_account(owner:, bytes:)
    {
      "lamports" => 1_000_000,
      "owner" => owner,
      "executable" => false,
      "rentEpoch" => 0,
      "data" => [ Base64.strict_encode64(bytes.pack("C*")), "base64" ]
    }
  end

  def spl_mint_bytes
    bytes = []
    bytes += [ 0, 0, 0, 0 ]                  # mint_authority option = None
    bytes += [ 0 ] * 32                      # mint_authority pubkey (empty)
    bytes += [ 1_000_000 ].pack("Q<").bytes  # supply
    bytes << 6                                # decimals
    bytes << 1                                # is_initialized
    bytes += [ 0, 0, 0, 0 ]                  # freeze_authority option = None
    bytes += [ 0 ] * 32                      # freeze_authority pubkey (empty)
    bytes
  end

  test "decoded? returns true for known program with parsed regions" do
    presenter = AccountPresenter.new("Addr1", build_account(owner: TOKEN_PROGRAM, bytes: spl_mint_bytes))
    assert presenter.decoded?
  end

  test "decoded? returns false when owner is unknown and bytes are not ELF" do
    random_bytes = (0..63).to_a # plain incrementing bytes, no ELF magic
    presenter = AccountPresenter.new("Addr2", build_account(owner: UNKNOWN_OWNER, bytes: random_bytes))
    refute presenter.decoded?
  end

  test "decoded? returns true when unknown owner has ELF magic" do
    bytes = ELF_MAGIC + [ 2, 1, 1, 0 ] + [ 0 ] * 56 # 64-byte minimal ELF header
    presenter = AccountPresenter.new("Addr3", build_account(owner: UNKNOWN_OWNER, bytes: bytes))
    assert presenter.decoded?
  end

  test "decoded? returns false for empty data even with known owner" do
    presenter = AccountPresenter.new("Addr4", build_account(owner: TOKEN_PROGRAM, bytes: []))
    refute presenter.decoded?
  end
end
