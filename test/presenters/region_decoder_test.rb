require "test_helper"

class RegionDecoderTest < ActiveSupport::TestCase
  # Known USDC Mint data (SPL Mint, 82 bytes)
  # Mint Authority: 2wmVCSfPxGPjrnMMn7rchp4uaeoTqN39mXFC2kPdENDq (Circle)
  # Supply: large number, Decimals: 6, Initialized: true, Freeze Authority: some
  USDC_MINT_OWNER = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"

  def build_spl_mint_bytes(mint_authority: nil, supply: 1000000, decimals: 6, freeze_authority: nil)
    bytes = []

    # Mint authority option (u32) + pubkey (32 bytes)
    if mint_authority
      bytes += [ 1, 0, 0, 0 ] # Some
      bytes += mint_authority
    else
      bytes += [ 0, 0, 0, 0 ] # None
      bytes += [ 0 ] * 32
    end

    # Supply (u64 LE)
    bytes += [ supply ].pack("Q<").bytes

    # Decimals (u8)
    bytes << decimals

    # Is initialized (u8)
    bytes << 1

    # Freeze authority option (u32) + pubkey (32 bytes)
    if freeze_authority
      bytes += [ 1, 0, 0, 0 ] # Some
      bytes += freeze_authority
    else
      bytes += [ 0, 0, 0, 0 ] # None
      bytes += [ 0 ] * 32
    end

    bytes
  end

  def build_spl_token_bytes(mint:, owner:, amount: 0, state: 1)
    bytes = []
    bytes += mint       # 32 bytes
    bytes += owner      # 32 bytes
    bytes += [ amount ].pack("Q<").bytes # 8 bytes
    bytes += [ 0, 0, 0, 0 ] # delegate option: None
    bytes += [ 0 ] * 32 # delegate (empty)
    bytes << state       # state
    bytes += [ 0, 0, 0, 0 ] # is_native option: None
    bytes += [ 0 ] * 8  # native amount (reserved)
    bytes += [ 0 ].pack("Q<").bytes # delegated_amount
    bytes += [ 0, 0, 0, 0 ] # close authority option: None
    bytes += [ 0 ] * 32 # close authority (empty)
    bytes
  end

  # --- SPL Mint Tests ---

  test "decode_spl_mint returns correct number of regions for basic mint" do
    bytes = build_spl_mint_bytes(decimals: 6, supply: 1_000_000)
    assert_equal 82, bytes.length

    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)
    named_regions = regions.reject { |r| r.name == "Data" }

    # Should have: mint_auth_option, mint_authority, supply, decimals, is_initialized, freeze_auth_option, freeze_authority
    assert_equal 7, named_regions.length
  end

  test "decode_spl_mint correctly parses decimals" do
    bytes = build_spl_mint_bytes(decimals: 9, supply: 0)
    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)

    decimals_region = regions.find { |r| r.id == "decimals" }
    assert_not_nil decimals_region
    assert_equal "9", decimals_region.decoded_value
    assert_equal 44, decimals_region.start
    assert_equal 1, decimals_region.length
  end

  test "decode_spl_mint correctly parses supply" do
    bytes = build_spl_mint_bytes(supply: 1_000_000_000)
    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)

    supply_region = regions.find { |r| r.id == "supply" }
    assert_not_nil supply_region
    assert_equal "1000000000", supply_region.decoded_value
    assert_equal 36, supply_region.start
    assert_equal 8, supply_region.length
  end

  test "decode_spl_mint with mint authority shows Some" do
    authority_bytes = (1..32).to_a
    bytes = build_spl_mint_bytes(mint_authority: authority_bytes)
    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)

    option_region = regions.find { |r| r.id == "mint_auth_option" }
    assert_equal "Some", option_region.decoded_value

    auth_region = regions.find { |r| r.id == "mint_authority" }
    assert_equal "green", auth_region.color
    assert auth_region.decoded_value.length > 0
  end

  test "decode_spl_mint without mint authority shows None" do
    bytes = build_spl_mint_bytes
    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)

    option_region = regions.find { |r| r.id == "mint_auth_option" }
    assert_equal "None", option_region.decoded_value
  end

  test "decode_spl_mint regions cover exactly 82 bytes" do
    bytes = build_spl_mint_bytes
    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)

    total_covered = regions.sum(&:length)
    assert_equal 82, total_covered
  end

  test "decode_spl_mint regions have no gaps or overlaps" do
    bytes = build_spl_mint_bytes(mint_authority: (1..32).to_a, freeze_authority: (33..64).to_a)
    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)

    # Sort by start offset
    sorted = regions.sort_by(&:start)
    sorted.each_cons(2) do |a, b|
      assert_equal a.start + a.length, b.start,
        "Gap or overlap between '#{a.name}' (#{a.start}+#{a.length}) and '#{b.name}' (#{b.start})"
    end
  end

  # --- SPL Token Account Tests ---

  test "decode_spl_token returns correct number of regions" do
    mint = (1..32).to_a
    owner = (33..64).to_a
    bytes = build_spl_token_bytes(mint: mint, owner: owner, amount: 500)
    assert_equal 165, bytes.length

    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)
    named_regions = regions.reject { |r| r.name == "Data" }

    # mint, owner, amount, delegate_option, delegate(empty), state, is_native, native(reserved), delegated_amount, close_auth_option, close_auth(empty)
    assert_equal 11, named_regions.length
  end

  test "decode_spl_token correctly parses amount" do
    mint = (1..32).to_a
    owner = (33..64).to_a
    bytes = build_spl_token_bytes(mint: mint, owner: owner, amount: 42_000_000)

    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)
    amount_region = regions.find { |r| r.id == "amount" }
    assert_equal "42000000", amount_region.decoded_value
    assert_equal 64, amount_region.start
    assert_equal 8, amount_region.length
  end

  test "decode_spl_token correctly parses state" do
    mint = (1..32).to_a
    owner = (33..64).to_a

    [ [ 0, "Uninitialized" ], [ 1, "Initialized" ], [ 2, "Frozen" ] ].each do |state_byte, expected_label|
      bytes = build_spl_token_bytes(mint: mint, owner: owner, state: state_byte)
      regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)
      state_region = regions.find { |r| r.id == "state" }
      assert_equal expected_label, state_region.decoded_value, "State #{state_byte} should decode to #{expected_label}"
    end
  end

  test "decode_spl_token regions cover exactly 165 bytes" do
    mint = (1..32).to_a
    owner = (33..64).to_a
    bytes = build_spl_token_bytes(mint: mint, owner: owner)
    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)

    total_covered = regions.sum(&:length)
    assert_equal 165, total_covered
  end

  # --- BPF Upgradeable Tests ---

  test "decode_bpf_upgradeable parses Program type" do
    bytes = [ 2, 0, 0, 0 ] + (1..32).to_a # type=2 (Program) + 32-byte programdata address
    regions = RegionDecoder.decode("BPFLoaderUpgradeab1e11111111111111111111111", bytes)

    type_region = regions.find { |r| r.id == "account_type" }
    assert_equal "Program", type_region.decoded_value

    addr_region = regions.find { |r| r.id == "programdata_address" }
    assert_not_nil addr_region
    assert_equal 4, addr_region.start
    assert_equal 32, addr_region.length
  end

  # --- ELF Tests ---

  test "decode_elf detects BPF machine type" do
    # Minimal ELF header (64 bytes)
    bytes = [ 0x7f, 0x45, 0x4c, 0x46 ] # magic
    bytes << 2      # 64-bit
    bytes << 1      # little-endian
    bytes << 1      # version
    bytes << 0      # UNIX System V
    bytes += [ 0 ] * 8  # padding
    bytes += [ 3, 0 ]   # e_type = Shared object
    bytes += [ 0xF7, 0 ] # e_machine = BPF
    bytes += [ 1, 0, 0, 0 ] # e_version
    bytes += [ 0 ] * 8  # entry
    bytes += [ 0 ] * 8  # phoff
    bytes += [ 0 ] * 8  # shoff
    bytes += [ 0 ] * 4  # flags
    bytes += [ 64, 0 ]  # ehsize
    bytes += [ 0 ] * 2  # phentsize
    bytes += [ 0 ] * 2  # phnum
    bytes += [ 0 ] * 2  # shentsize
    bytes += [ 0 ] * 2  # shnum
    bytes += [ 0 ] * 2  # shstrndx
    assert_equal 64, bytes.length

    regions = RegionDecoder.decode("BPFLoader2111111111111111111111111111111111", bytes)

    machine_region = regions.find { |r| r.id == "elf_machine" }
    assert_equal "BPF", machine_region.decoded_value

    class_region = regions.find { |r| r.id == "elf_class" }
    assert_equal "64-bit", class_region.decoded_value
  end

  # --- encode_base58 Tests ---

  test "encode_base58 encodes known values correctly" do
    # All zeros should produce all '1's
    result = RegionDecoder.send(:encode_base58, [ 0 ] * 32)
    assert_equal "1" * 32, result, "32 zero bytes should encode to 32 '1' characters"
  end

  test "encode_base58 encodes single byte" do
    # byte 0x01 should encode to "2" in base58
    result = RegionDecoder.send(:encode_base58, [ 1 ])
    assert_equal "2", result
  end

  test "encode_base58 handles leading zeros" do
    # [ 0, 0, 1 ] should start with "11" (two leading zeros) + encoding of 1
    result = RegionDecoder.send(:encode_base58, [ 0, 0, 1 ])
    assert result.start_with?("11"), "Should have two leading '1' chars for two zero bytes"
  end

  test "encode_base58 produces valid base58 characters only" do
    random_bytes = (1..32).to_a
    result = RegionDecoder.send(:encode_base58, random_bytes)
    valid_chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    result.each_char do |c|
      assert_includes valid_chars, c, "Character '#{c}' is not valid base58"
    end
  end

  # --- Edge Cases ---

  test "unknown owner with non-ELF data returns Data region" do
    bytes = [ 0, 1, 2, 3, 4, 5 ]
    regions = RegionDecoder.decode("SomeUnknownProgram11111111111111111111111", bytes)

    assert_equal 1, regions.length
    assert_equal "Data", regions.first.name
    assert_equal 6, regions.first.length
  end

  test "unknown owner with ELF magic decodes as ELF" do
    bytes = [ 0x7f, 0x45, 0x4c, 0x46 ] + [ 0 ] * 60
    regions = RegionDecoder.decode("SomeUnknownProgram11111111111111111111111", bytes)

    elf_magic = regions.find { |r| r.id == "elf_magic" }
    assert_not_nil elf_magic
    assert_equal "\\x7fELF", elf_magic.decoded_value
  end

  test "too-short bytes for Token returns empty with Data" do
    bytes = [ 0 ] * 10
    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)

    assert_equal 1, regions.length
    assert_equal "Data", regions.first.name
  end
end
