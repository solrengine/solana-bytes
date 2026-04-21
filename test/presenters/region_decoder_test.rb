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

  def build_stake_bytes(state: 2, rent_exempt: 2282880, lockup_ts: 0, lockup_epoch: 0, stake_amount: 1_000_000_000)
    bytes = []

    # State (u32 LE)
    bytes += [ state ].pack("V").bytes

    # Meta: Rent Exempt Reserve (u64 LE)
    bytes += [ rent_exempt ].pack("Q<").bytes

    # Authorized Staker (32 bytes)
    bytes += (1..32).to_a

    # Authorized Withdrawer (32 bytes)
    bytes += (33..64).to_a

    # Lockup: Unix Timestamp (i64 LE)
    bytes += [ lockup_ts ].pack("q<").bytes

    # Lockup: Epoch (u64 LE)
    bytes += [ lockup_epoch ].pack("Q<").bytes

    # Lockup: Custodian (32 bytes)
    bytes += [ 0 ] * 32

    # Stake section (only for Delegated state)
    if state >= 2
      # Voter Pubkey (32 bytes)
      bytes += (65..96).to_a

      # Stake (u64 LE)
      bytes += [ stake_amount ].pack("Q<").bytes

      # Activation Epoch (u64 LE)
      bytes += [ 100 ].pack("Q<").bytes

      # Deactivation Epoch (u64 LE) — max u64 = still active
      bytes += [ 0xFFFFFFFFFFFFFFFF ].pack("Q<").bytes

      # Warmup Cooldown Rate (8 bytes)
      bytes += [ 0 ] * 8

      # Credits Observed (u64 LE)
      bytes += [ 12345 ].pack("Q<").bytes
    end

    bytes
  end

  def build_vote_bytes(version: 1, commission: 10)
    bytes = []

    # Version (u32 LE)
    bytes += [ version ].pack("V").bytes

    # Node Pubkey (32 bytes)
    bytes += (1..32).to_a

    # Authorized Voter Epoch (u64 LE)
    bytes += [ 500 ].pack("Q<").bytes

    # Authorized Voter (32 bytes)
    bytes += (33..64).to_a

    # Authorized Withdrawer (32 bytes)
    bytes += (65..96).to_a

    # Commission (u8)
    bytes << commission

    # Some vote history data
    bytes += [ 0 ] * 50

    bytes
  end

  STAKE_OWNER = "Stake11111111111111111111111111111111111111"
  VOTE_OWNER = "Vote111111111111111111111111111111111111111"

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

  # --- Stake Account Tests ---

  test "decode_stake_account returns correct regions for delegated stake" do
    bytes = build_stake_bytes(state: 2)
    assert_equal 196, bytes.length

    regions = RegionDecoder.decode(STAKE_OWNER, bytes)
    named_regions = regions.reject { |r| r.name == "Data" }

    # state + rent_exempt + staker + withdrawer + lockup_ts + lockup_epoch + custodian
    # + voter + stake + activation + deactivation + warmup + credits = 13
    assert_equal 13, named_regions.length
  end

  test "decode_stake_account parses state correctly" do
    { 0 => "Uninitialized", 1 => "Initialized", 2 => "Delegated", 3 => "RewardsPool" }.each do |val, label|
      bytes = build_stake_bytes(state: val)
      regions = RegionDecoder.decode(STAKE_OWNER, bytes)
      state_region = regions.find { |r| r.id == "stake_state" }
      assert_equal label, state_region.decoded_value, "State #{val} should decode to #{label}"
    end
  end

  test "decode_stake_account parses rent exempt reserve" do
    bytes = build_stake_bytes(rent_exempt: 2282880)
    regions = RegionDecoder.decode(STAKE_OWNER, bytes)

    rent_region = regions.find { |r| r.id == "rent_exempt_reserve" }
    assert_not_nil rent_region
    assert_equal "2282880 lamports", rent_region.decoded_value
    assert_equal 4, rent_region.start
    assert_equal 8, rent_region.length
  end

  test "decode_stake_account parses stake amount for delegated" do
    bytes = build_stake_bytes(state: 2, stake_amount: 5_000_000_000)
    regions = RegionDecoder.decode(STAKE_OWNER, bytes)

    stake_region = regions.find { |r| r.id == "stake_amount" }
    assert_not_nil stake_region
    assert_equal "5000000000 lamports", stake_region.decoded_value
  end

  test "decode_stake_account initialized only has no stake section" do
    bytes = build_stake_bytes(state: 1)
    regions = RegionDecoder.decode(STAKE_OWNER, bytes)

    voter_region = regions.find { |r| r.id == "voter_pubkey" }
    assert_nil voter_region, "Initialized stake should not have voter pubkey"
  end

  test "decode_stake_account deactivation epoch shows Active for max u64" do
    bytes = build_stake_bytes(state: 2)
    regions = RegionDecoder.decode(STAKE_OWNER, bytes)

    deact_region = regions.find { |r| r.id == "deactivation_epoch" }
    assert_not_nil deact_region
    assert_equal "Active (max u64)", deact_region.decoded_value
  end

  test "decode_stake_account regions have no gaps for delegated" do
    bytes = build_stake_bytes(state: 2)
    regions = RegionDecoder.decode(STAKE_OWNER, bytes)

    sorted = regions.sort_by(&:start)
    sorted.each_cons(2) do |a, b|
      assert_equal a.start + a.length, b.start,
        "Gap or overlap between '#{a.name}' (#{a.start}+#{a.length}) and '#{b.name}' (#{b.start})"
    end
  end

  # --- Vote Account Tests ---

  test "decode_vote_account returns correct regions" do
    bytes = build_vote_bytes(version: 1, commission: 7)
    regions = RegionDecoder.decode(VOTE_OWNER, bytes)
    named_regions = regions.reject { |r| r.name == "Data" }

    # version + node_pubkey + auth_voter_epoch + auth_voter + auth_withdrawer + commission + vote_history = 7
    assert_equal 7, named_regions.length
  end

  test "decode_vote_account parses commission" do
    bytes = build_vote_bytes(commission: 8)
    regions = RegionDecoder.decode(VOTE_OWNER, bytes)

    commission_region = regions.find { |r| r.id == "commission" }
    assert_not_nil commission_region
    assert_equal "8%", commission_region.decoded_value
    assert_equal 108, commission_region.start
    assert_equal 1, commission_region.length
  end

  test "decode_vote_account parses node pubkey" do
    bytes = build_vote_bytes
    regions = RegionDecoder.decode(VOTE_OWNER, bytes)

    node_region = regions.find { |r| r.id == "node_pubkey" }
    assert_not_nil node_region
    assert_equal 4, node_region.start
    assert_equal 32, node_region.length
    assert node_region.decoded_value.length > 0
  end

  test "decode_vote_account includes vote history for remaining bytes" do
    bytes = build_vote_bytes
    regions = RegionDecoder.decode(VOTE_OWNER, bytes)

    history_region = regions.find { |r| r.id == "vote_history" }
    assert_not_nil history_region
    assert_equal "Vote History", history_region.name
    assert_equal "gray", history_region.color
    assert_equal 109, history_region.start
  end

  test "decode_vote_account regions cover all bytes" do
    bytes = build_vote_bytes
    regions = RegionDecoder.decode(VOTE_OWNER, bytes)

    total_covered = regions.sum(&:length)
    assert_equal bytes.length, total_covered
  end

  # --- Token-2022 Extension Tests ---

  test "decode_extension_data for TransferFeeConfig" do
    # Build minimal TransferFeeConfig: 2 pubkeys + some fee data
    ext_data = (1..32).to_a + (33..64).to_a + [ 0 ] * 44
    result = RegionDecoder.send(:decode_extension_data, 1, ext_data, 0, ext_data.length)

    assert_equal 3, result.length
    assert_equal "Transfer Fee Config Authority", result[0][:name]
    assert_equal 32, result[0][:length]
    assert_equal "Withdraw Withheld Authority", result[1][:name]
    assert_equal 32, result[1][:length]
    assert_equal "Fee Config Data", result[2][:name]
  end

  test "decode_extension_data for TransferFeeAmount" do
    ext_data = [ 100, 0, 0, 0, 0, 0, 0, 0 ] # u64 LE = 100
    result = RegionDecoder.send(:decode_extension_data, 2, ext_data, 0, 8)

    assert_equal 1, result.length
    assert_equal "Withheld Amount", result[0][:name]
    assert_equal "100", result[0][:value]
  end

  test "decode_extension_data for ImmutableOwner" do
    # ImmutableOwner has 0 bytes of data
    result = RegionDecoder.send(:decode_extension_data, 7, [], 0, 0)
    assert_equal 0, result.length, "ImmutableOwner is a zero-length extension"
  end

  test "decode_extension_data for NonTransferable" do
    # NonTransferable has 0 bytes of data
    result = RegionDecoder.send(:decode_extension_data, 9, [], 0, 0)
    assert_equal 0, result.length, "NonTransferable is a zero-length extension"
  end

  test "decode_extension_data for MemoTransfer" do
    ext_data = [ 1 ] # required = true
    result = RegionDecoder.send(:decode_extension_data, 8, ext_data, 0, 1)

    assert_equal 1, result.length
    assert_equal "Require Incoming Memos", result[0][:name]
    assert_equal "Required", result[0][:value]
  end

  test "decode_extension_data for CpiGuard" do
    ext_data = [ 1 ] # locked
    result = RegionDecoder.send(:decode_extension_data, 11, ext_data, 0, 1)

    assert_equal 1, result.length
    assert_equal "Lock CPI", result[0][:name]
    assert_equal "Locked", result[0][:value]
  end

  test "decode_extension_data for InterestBearingConfig" do
    ext_data = []
    # Rate Authority (32 bytes)
    ext_data += (1..32).to_a
    # Initialization Timestamp (i64 LE)
    ext_data += [ 1_700_000_000 ].pack("q<").bytes
    # Pre-update Average Rate (i16 LE)
    ext_data += [ 500 ].pack("s<").bytes
    # Last Update Timestamp (i64 LE)
    ext_data += [ 1_700_100_000 ].pack("q<").bytes
    # Current Rate (i16 LE)
    ext_data += [ 750 ].pack("s<").bytes

    result = RegionDecoder.send(:decode_extension_data, 10, ext_data, 0, ext_data.length)

    assert_equal 5, result.length
    assert_equal "Rate Authority", result[0][:name]
    assert_equal 32, result[0][:length]
    assert_equal "Initialization Timestamp", result[1][:name]
    assert_equal "1700000000", result[1][:value]
    assert_equal "Pre-update Average Rate", result[2][:name]
    assert_equal "500 bps", result[2][:value]
    assert_equal "Last Update Timestamp", result[3][:name]
    assert_equal "Current Rate", result[4][:name]
    assert_equal "750 bps", result[4][:value]
  end

  # --- Educational Descriptions Tests ---

  test "regions include descriptions for known field IDs" do
    bytes = build_spl_mint_bytes(mint_authority: (1..32).to_a, supply: 1000)
    regions = RegionDecoder.decode(USDC_MINT_OWNER, bytes)

    supply_region = regions.find { |r| r.id == "supply" }
    assert_not_nil supply_region.description
    assert_includes supply_region.description, "smallest denomination"

    decimals_region = regions.find { |r| r.id == "decimals" }
    assert_not_nil decimals_region.description
    assert_includes decimals_region.description, "USDC"
  end

  test "stake account regions include descriptions" do
    bytes = build_stake_bytes(state: 2)
    regions = RegionDecoder.decode(STAKE_OWNER, bytes)

    staker_region = regions.find { |r| r.id == "authorized_staker" }
    assert_not_nil staker_region.description
    assert_includes staker_region.description, "delegate"

    voter_region = regions.find { |r| r.id == "voter_pubkey" }
    assert_not_nil voter_region.description
    assert_includes voter_region.description, "validator"
  end

  test "vote account regions include descriptions" do
    bytes = build_vote_bytes(commission: 5)
    regions = RegionDecoder.decode(VOTE_OWNER, bytes)

    commission_region = regions.find { |r| r.id == "commission" }
    assert_not_nil commission_region.description
    assert_includes commission_region.description, "staking rewards"
  end
end
