module RegionDecoder
  extend self

  Region = AccountPresenter::Region

  # Educational descriptions for region IDs
  DESCRIPTIONS = {
    # SPL Mint fields
    "mint_auth_option" => "COption flag: 1 = authority is set (Some), 0 = no authority (None).",
    "mint_authority" => "Can mint new tokens. If None (option=0), the supply is permanently fixed.",
    "supply" => "Total number of tokens in circulation, stored as a u64 in the smallest denomination.",
    "decimals" => "Number of decimal places. USDC uses 6 (1 USDC = 1,000,000 base units).",
    "is_initialized" => "Whether this account has been initialized. Uninitialized accounts cannot be used.",
    "freeze_auth_option" => "COption flag: 1 = freeze authority is set, 0 = tokens can never be frozen.",
    "freeze_authority" => "Can freeze token accounts, preventing transfers. Used for compliance.",
    # SPL Token Account fields
    "mint" => "The token mint this account holds. Identifies which token (USDC, SOL, etc.).",
    "token_owner" => "The wallet that owns this token account and can transfer tokens from it.",
    "amount" => "Token balance in the smallest denomination. Divide by 10^decimals for the display amount.",
    "delegate_option" => "COption flag: 1 = a delegate is authorized, 0 = no delegate.",
    "delegate" => "A wallet authorized to transfer or burn tokens on behalf of the owner.",
    "state" => "Account state: 1=Initialized (active), 2=Frozen (transfers blocked).",
    "is_native" => "Whether this is a wrapped SOL account. Native SOL is stored as lamports.",
    "delegated_amount" => "How many tokens the delegate is authorized to transfer.",
    "close_authority" => "Can close this account and reclaim the rent-exempt SOL balance.",
    # Stake account fields
    "stake_state" => "Stake account lifecycle: 0=Uninitialized, 1=Initialized, 2=Delegated, 3=RewardsPool.",
    "rent_exempt_reserve" => "Minimum SOL balance (lamports) required to keep this account rent-free.",
    "authorized_staker" => "Can delegate or deactivate the stake. Usually the wallet owner.",
    "authorized_withdrawer" => "Can withdraw SOL from the stake account. Critical security key.",
    "lockup_timestamp" => "Unix timestamp before which withdrawals are locked. 0 = no time lock.",
    "lockup_epoch" => "Epoch before which withdrawals are locked. 0 = no epoch lock.",
    "lockup_custodian" => "Can modify the lockup. If all-zeros, no custodian is set.",
    "voter_pubkey" => "The validator node's identity. This pubkey is used to identify the validator on the network.",
    "stake_amount" => "Amount of SOL delegated to the validator, in lamports.",
    "activation_epoch" => "Epoch when this stake became active. Takes effect after warmup period.",
    "deactivation_epoch" => "Epoch when deactivation was requested. Max u64 = still active.",
    "warmup_cooldown_rate" => "Rate at which stake warms up or cools down across epochs.",
    "credits_observed" => "Vote credits observed at last stake redelegation or reward claim.",
    # Vote account fields
    "vote_version" => "Vote account version. Typically 1 for current validators.",
    "node_pubkey" => "The validator's identity pubkey. Used to identify the node on the network.",
    "authorized_voter_epoch" => "Epoch for which the authorized voter is valid.",
    "authorized_voter" => "Pubkey authorized to submit votes. Usually the validator's vote key.",
    "authorized_vote_withdrawer" => "Can withdraw lamports from the vote account. Critical security key.",
    "commission" => "Percentage of staking rewards the validator keeps. 0-100%.",
    "vote_history" => "Variable-length data: recent votes, epoch credits, and last timestamp.",
    # Metaplex Token Metadata fields
    "meta_key" => "Metaplex account type discriminator. 4 = MetadataV1 (NFT or token metadata).",
    "meta_update_authority" => "Can update the metadata fields (name, URI, creators). Set to null to freeze.",
    "meta_mint" => "The SPL mint this metadata describes. Metadata is a PDA derived from the mint.",
    "meta_name_len" => "Borsh u32 length prefix for the name. Modern metadata pads to 32 bytes.",
    "meta_name" => "The NFT or token's display name (up to 32 chars, null-padded).",
    "meta_symbol_len" => "Borsh u32 length prefix for the symbol (modern: padded to 10 bytes).",
    "meta_symbol" => "Ticker symbol, e.g. 'MAD', 'DEGOD', 'y00ts'. Up to 10 chars.",
    "meta_uri_len" => "Borsh u32 length prefix for the URI (modern: padded to 200 bytes).",
    "meta_uri" => "Off-chain JSON metadata URL containing image, attributes, description.",
    "seller_fee_basis_points" => "Royalty in basis points. 500 = 5%, 420 = 4.2%. Honored by compliant marketplaces.",
    "creators_option" => "COption flag: 1 = creators list is present, 0 = no on-chain creators.",
    "creators_count" => "Number of creators (u32). Each creator is 34 bytes (pubkey + verified + share).",
    "primary_sale_happened" => "True once the NFT is first sold. Locks some metadata mutations.",
    "is_mutable" => "If false, metadata is permanently frozen — even the authority can't update it.",
    "edition_nonce" => "Optional u8 bump seed for the Edition PDA (used in master/print editions).",
    "token_standard" => "Fungibility: NonFungible (NFT), ProgrammableNonFungible (pNFT), Fungible (SPL).",
    "collection" => "Optional parent collection ref: 1-byte verified flag + 32-byte collection mint.",
    "uses" => "Optional consumable tracker (use_method + remaining + total) for usable NFTs.",
    "meta_tail" => "Remaining optional fields (collection_details, programmable_config).",
    # Address Lookup Table fields
    "lut_discriminator" => "Account variant discriminator. 1 = LookupTable.",
    "lut_deactivation_slot" => "u64::MAX = active. Otherwise the slot at which deactivation began. The table becomes invalid 513 slots after that point.",
    "lut_last_extended_slot" => "Most recent slot in which addresses were appended via ExtendLookupTable.",
    "lut_start_index" => "Position in the addresses array where the most recent extension began. Lets you tell which addresses were added in the latest extension.",
    "lut_auth_option" => "COption flag: 1 = an authority can extend or deactivate, 0 = the table is permanently frozen.",
    "lut_authority" => "Can extend the table or initiate deactivation. Once deactivation completes, the table is gone.",
    "lut_padding" => "Compiler alignment padding. Always zero — kept here so the addresses array starts on a 32-byte boundary.",
    "lookup_address" => "32-byte pubkey stored in this LUT. v0 transactions reference these by 1-byte index, lifting the ~35-account ceiling of legacy transactions.",
    # SPL Token Multisig fields
    "multisig_m" => "Threshold: number of signers required to authorize an action (m of n).",
    "multisig_n" => "Total number of signers configured. Max 11.",
    "multisig_is_initialized" => "Whether this multisig has been initialized. Uninitialized multisigs cannot be used.",
    "multisig_signer" => "One of the 11 signer pubkey slots. Empty slots are all-zero and unused.",
    "multisig_signer_empty" => "Unused signer slot — all zeros. Multisigs always reserve 11 slots regardless of n."
  }.freeze

  def decode(owner, bytes)
    regions = case owner
    when "BPFLoaderUpgradeab1e11111111111111111111111"
      decode_bpf_upgradeable(bytes)
    when "BPFLoader2111111111111111111111111111111111",
         "BPFLoader1111111111111111111111111111111111"
      decode_elf(bytes)
    when "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
         "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
      # P3 known limitation: a 355-byte Token-2022 account with extensions could
      # collide with the SPL Multisig length and route here incorrectly. In practice
      # we have not hit this; revisit if a misdecoded Token-2022 account is reported.
      if bytes.length == 355
        decode_spl_multisig(bytes)
      elsif bytes.length >= 165
        decode_spl_token(bytes)
      elsif bytes.length >= 82
        decode_spl_mint(bytes)
      else
        []
      end
    when "Stake11111111111111111111111111111111111111"
      decode_stake_account(bytes)
    when "Vote111111111111111111111111111111111111111"
      decode_vote_account(bytes)
    when "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"
      decode_metaplex_metadata(bytes)
    when "AddressLookupTab1e1111111111111111111111111"
      decode_address_lookup_table(bytes)
    else
      # Try ELF detection for any executable data
      if bytes.length >= 4 && bytes[0..3] == [ 0x7f, 0x45, 0x4c, 0x46 ]
        decode_elf(bytes)
      else
        []
      end
    end

    # Attach descriptions to regions
    regions.each do |r|
      r.description ||= DESCRIPTIONS[r.id]
    end

    # Fill remaining bytes as "Program Bytecode" or "Data"
    covered = regions.sum(&:length)
    if covered < bytes.length
      is_executable = bytes.length >= 4 && bytes[0..3] == [ 0x7f, 0x45, 0x4c, 0x46 ]
      regions << Region.new(
        id: "data",
        name: is_executable ? "Program Bytecode" : "Data",
        start: covered,
        length: bytes.length - covered,
        color: "gray",
        decoded_value: "#{bytes.length - covered} bytes"
      )
    end

    regions
  end

  private

  def decode_bpf_upgradeable(bytes)
    return [] if bytes.length < 4
    account_type = read_u32(bytes, 0)
    type_label = case account_type
    when 0 then "Uninitialized"
    when 1 then "Buffer"
    when 2 then "Program"
    when 3 then "ProgramData"
    else "Unknown (#{account_type})"
    end

    regions = [
      Region.new(id: "account_type", name: "Account Type", start: 0, length: 4, color: "orange", decoded_value: type_label)
    ]

    if bytes.length >= 36
      pubkey = encode_base58(bytes[4, 32])
      regions << Region.new(id: "programdata_address", name: "ProgramData Address", start: 4, length: 32, color: "green", decoded_value: pubkey)
    end

    regions
  end

  def decode_elf(bytes)
    return [] if bytes.length < 64

    ei_class = bytes[4]
    class_label = case ei_class
    when 1 then "32-bit"
    when 2 then "64-bit"
    else "Unknown"
    end

    ei_data = bytes[5]
    endian_label = case ei_data
    when 1 then "Little-endian"
    when 2 then "Big-endian"
    else "Unknown"
    end

    ei_osabi = bytes[7]
    osabi_label = case ei_osabi
    when 0 then "UNIX System V"
    when 3 then "Linux"
    else "OS/ABI #{ei_osabi}"
    end

    e_type = read_u16(bytes, 16)
    type_label = case e_type
    when 0 then "None"
    when 1 then "Relocatable"
    when 2 then "Executable"
    when 3 then "Shared object"
    when 4 then "Core"
    else "Type #{e_type}"
    end

    e_machine = read_u16(bytes, 18)
    machine_label = case e_machine
    when 0xF7 then "BPF"
    when 0x03 then "x86"
    when 0x3E then "x86-64"
    when 0xB7 then "AArch64"
    else "Machine #{e_machine}"
    end

    e_entry = read_u64(bytes, 24)
    e_phoff = read_u64(bytes, 32)
    e_shoff = read_u64(bytes, 40)

    [
      Region.new(id: "elf_magic", name: "ELF Magic", start: 0, length: 4, color: "orange", decoded_value: "\\x7fELF"),
      Region.new(id: "elf_class", name: "ELF Class", start: 4, length: 1, color: "blue", decoded_value: class_label),
      Region.new(id: "elf_endian", name: "Data Encoding", start: 5, length: 1, color: "blue", decoded_value: endian_label),
      Region.new(id: "elf_version", name: "ELF Version", start: 6, length: 1, color: "gray", decoded_value: bytes[6].to_s),
      Region.new(id: "elf_osabi", name: "OS/ABI", start: 7, length: 1, color: "cyan", decoded_value: osabi_label),
      Region.new(id: "elf_padding", name: "ABI Version + Padding", start: 8, length: 8, color: "gray", decoded_value: "Reserved"),
      Region.new(id: "elf_type", name: "Object Type", start: 16, length: 2, color: "purple", decoded_value: type_label),
      Region.new(id: "elf_machine", name: "Machine", start: 18, length: 2, color: "green", decoded_value: machine_label),
      Region.new(id: "elf_e_version", name: "ELF Version", start: 20, length: 4, color: "gray", decoded_value: read_u32(bytes, 20).to_s),
      Region.new(id: "elf_entry", name: "Entry Point", start: 24, length: 8, color: "orange", decoded_value: "0x#{e_entry.to_s(16)}"),
      Region.new(id: "elf_phoff", name: "Program Header Offset", start: 32, length: 8, color: "blue", decoded_value: "0x#{e_phoff.to_s(16)}"),
      Region.new(id: "elf_shoff", name: "Section Header Offset", start: 40, length: 8, color: "blue", decoded_value: "0x#{e_shoff.to_s(16)}"),
      Region.new(id: "elf_flags", name: "Flags", start: 48, length: 4, color: "gray", decoded_value: "0x#{read_u32(bytes, 48).to_s(16)}"),
      Region.new(id: "elf_ehsize", name: "ELF Header Size", start: 52, length: 2, color: "purple", decoded_value: "#{read_u16(bytes, 52)} bytes"),
      Region.new(id: "elf_phentsize", name: "Program Header Entry Size", start: 54, length: 2, color: "cyan", decoded_value: "#{read_u16(bytes, 54)} bytes"),
      Region.new(id: "elf_phnum", name: "Program Header Count", start: 56, length: 2, color: "cyan", decoded_value: read_u16(bytes, 56).to_s),
      Region.new(id: "elf_shentsize", name: "Section Header Entry Size", start: 58, length: 2, color: "green", decoded_value: "#{read_u16(bytes, 58)} bytes"),
      Region.new(id: "elf_shnum", name: "Section Header Count", start: 60, length: 2, color: "green", decoded_value: read_u16(bytes, 60).to_s),
      Region.new(id: "elf_shstrndx", name: "Section Name String Table Index", start: 62, length: 2, color: "yellow", decoded_value: read_u16(bytes, 62).to_s)
    ]
  end

  def read_u16(bytes, offset)
    bytes[offset, 2].pack("C*").unpack1("v")
  end

  def read_i16(bytes, offset)
    bytes[offset, 2].pack("C*").unpack1("s<")
  end

  def read_i64(bytes, offset)
    bytes[offset, 8].pack("C*").unpack1("q<")
  end

  def decode_spl_mint(bytes)
    # SPL Mint layout: 82 bytes
    # 0-3:   mint_authority_option (u32)
    # 4-35:  mint_authority (pubkey)
    # 36-43: supply (u64)
    # 44:    decimals (u8)
    # 45:    is_initialized (bool)
    # 46-49: freeze_authority_option (u32)
    # 50-81: freeze_authority (pubkey)

    mint_auth_option = read_u32(bytes, 0)
    regions = [
      Region.new(id: "mint_auth_option", name: "Mint Authority Option", start: 0, length: 4, color: "orange", decoded_value: mint_auth_option == 1 ? "Some" : "None")
    ]

    if mint_auth_option == 1
      mint_auth = encode_base58(bytes[4, 32])
      regions << Region.new(id: "mint_authority", name: "Mint Authority", start: 4, length: 32, color: "green", decoded_value: mint_auth)
    else
      regions << Region.new(id: "mint_authority", name: "Mint Authority (empty)", start: 4, length: 32, color: "gray", decoded_value: "None")
    end

    supply = read_u64(bytes, 36)
    decimals = bytes[44]
    is_initialized = bytes[45]

    regions << Region.new(id: "supply", name: "Supply", start: 36, length: 8, color: "purple", decoded_value: supply.to_s)
    regions << Region.new(id: "decimals", name: "Decimals", start: 44, length: 1, color: "blue", decoded_value: decimals.to_s)
    regions << Region.new(id: "is_initialized", name: "Is Initialized", start: 45, length: 1, color: "yellow", decoded_value: is_initialized == 1 ? "Yes" : "No")

    freeze_auth_option = read_u32(bytes, 46)
    regions << Region.new(id: "freeze_auth_option", name: "Freeze Authority Option", start: 46, length: 4, color: "orange", decoded_value: freeze_auth_option == 1 ? "Some" : "None")

    if freeze_auth_option == 1
      freeze_auth = encode_base58(bytes[50, 32])
      regions << Region.new(id: "freeze_authority", name: "Freeze Authority", start: 50, length: 32, color: "cyan", decoded_value: freeze_auth)
    else
      regions << Region.new(id: "freeze_authority", name: "Freeze Authority (empty)", start: 50, length: 32, color: "gray", decoded_value: "None")
    end

    # Token-2022 extensions (after base 82 bytes)
    if bytes.length > 82
      regions.concat(decode_token_extensions(bytes, 82))
    end

    regions
  end

  def decode_spl_token(bytes)
    return [] if bytes.length < 165 # SPL Token account is 165 bytes

    mint = encode_base58(bytes[0, 32])
    token_owner = encode_base58(bytes[32, 32])
    amount = read_u64(bytes, 64)
    delegate_option = read_u32(bytes, 72)

    regions = [
      Region.new(id: "mint", name: "Mint", start: 0, length: 32, color: "blue", decoded_value: mint),
      Region.new(id: "token_owner", name: "Owner", start: 32, length: 32, color: "green", decoded_value: token_owner),
      Region.new(id: "amount", name: "Amount", start: 64, length: 8, color: "purple", decoded_value: amount.to_s),
      Region.new(id: "delegate_option", name: "Delegate Option", start: 72, length: 4, color: "orange", decoded_value: delegate_option == 1 ? "Some" : "None")
    ]

    if delegate_option == 1 && bytes.length >= 108
      delegate = encode_base58(bytes[76, 32])
      regions << Region.new(id: "delegate", name: "Delegate", start: 76, length: 32, color: "cyan", decoded_value: delegate)
    else
      regions << Region.new(id: "delegate_empty", name: "Delegate (empty)", start: 76, length: 32, color: "gray", decoded_value: "None")
    end

    state = bytes[108]
    state_label = case state
    when 0 then "Uninitialized"
    when 1 then "Initialized"
    when 2 then "Frozen"
    else "Unknown (#{state})"
    end

    regions << Region.new(id: "state", name: "State", start: 108, length: 1, color: "yellow", decoded_value: state_label)

    is_native_option = read_u32(bytes, 109)
    regions << Region.new(id: "is_native", name: "Is Native", start: 109, length: 4, color: "orange", decoded_value: is_native_option == 1 ? "Yes" : "No")

    if is_native_option == 1 && bytes.length >= 121
      native_amount = read_u64(bytes, 113)
      regions << Region.new(id: "native_amount", name: "Native Amount", start: 113, length: 8, color: "purple", decoded_value: native_amount.to_s)
    else
      regions << Region.new(id: "native_reserved", name: "Native (reserved)", start: 113, length: 8, color: "gray", decoded_value: "N/A")
    end

    delegated_amount = read_u64(bytes, 121)
    regions << Region.new(id: "delegated_amount", name: "Delegated Amount", start: 121, length: 8, color: "purple", decoded_value: delegated_amount.to_s)

    close_authority_option = read_u32(bytes, 129)
    regions << Region.new(id: "close_authority_option", name: "Close Authority Option", start: 129, length: 4, color: "orange", decoded_value: close_authority_option == 1 ? "Some" : "None")

    if close_authority_option == 1 && bytes.length >= 165
      close_auth = encode_base58(bytes[133, 32])
      regions << Region.new(id: "close_authority", name: "Close Authority", start: 133, length: 32, color: "cyan", decoded_value: close_auth)
    else
      regions << Region.new(id: "close_authority_empty", name: "Close Authority (empty)", start: 133, length: 32, color: "gray", decoded_value: "None")
    end

    # Token-2022 extensions (after base 165 bytes)
    if bytes.length > 165
      regions.concat(decode_token_extensions(bytes, 165))
    end

    regions
  end

  # --- Stake Account Decoder ---

  STAKE_STATES = {
    0 => "Uninitialized",
    1 => "Initialized",
    2 => "Delegated",
    3 => "RewardsPool"
  }.freeze

  def decode_stake_account(bytes)
    return [] if bytes.length < 4

    state = read_u32(bytes, 0)
    state_label = STAKE_STATES[state] || "Unknown (#{state})"

    regions = [
      Region.new(id: "stake_state", name: "State", start: 0, length: 4, color: "yellow", decoded_value: state_label)
    ]

    # Meta section (offset 4-123)
    return regions if bytes.length < 124

    rent_exempt = read_u64(bytes, 4)
    regions << Region.new(id: "rent_exempt_reserve", name: "Rent Exempt Reserve", start: 4, length: 8, color: "orange", decoded_value: "#{rent_exempt} lamports")

    staker = encode_base58(bytes[12, 32])
    regions << Region.new(id: "authorized_staker", name: "Authorized Staker", start: 12, length: 32, color: "green", decoded_value: staker)

    withdrawer = encode_base58(bytes[44, 32])
    regions << Region.new(id: "authorized_withdrawer", name: "Authorized Withdrawer", start: 44, length: 32, color: "green", decoded_value: withdrawer)

    lockup_ts = read_i64(bytes, 76)
    regions << Region.new(id: "lockup_timestamp", name: "Lockup: Unix Timestamp", start: 76, length: 8, color: "orange", decoded_value: lockup_ts.to_s)

    lockup_epoch = read_u64(bytes, 84)
    regions << Region.new(id: "lockup_epoch", name: "Lockup: Epoch", start: 84, length: 8, color: "orange", decoded_value: lockup_epoch.to_s)

    custodian = encode_base58(bytes[92, 32])
    regions << Region.new(id: "lockup_custodian", name: "Lockup: Custodian", start: 92, length: 32, color: "cyan", decoded_value: custodian)

    # Stake section (only if state >= Delegated, offset 124-195)
    if state >= 2 && bytes.length >= 196
      voter = encode_base58(bytes[124, 32])
      regions << Region.new(id: "voter_pubkey", name: "Voter Pubkey", start: 124, length: 32, color: "blue", decoded_value: voter)

      stake_amt = read_u64(bytes, 156)
      regions << Region.new(id: "stake_amount", name: "Stake", start: 156, length: 8, color: "purple", decoded_value: "#{stake_amt} lamports")

      activation = read_u64(bytes, 164)
      regions << Region.new(id: "activation_epoch", name: "Activation Epoch", start: 164, length: 8, color: "blue", decoded_value: activation.to_s)

      deactivation = read_u64(bytes, 172)
      deactivation_label = deactivation == 0xFFFFFFFFFFFFFFFF ? "Active (max u64)" : deactivation.to_s
      regions << Region.new(id: "deactivation_epoch", name: "Deactivation Epoch", start: 172, length: 8, color: "blue", decoded_value: deactivation_label)

      regions << Region.new(id: "warmup_cooldown_rate", name: "Warmup/Cooldown Rate", start: 180, length: 8, color: "gray", decoded_value: "8 raw bytes")

      credits = read_u64(bytes, 188)
      regions << Region.new(id: "credits_observed", name: "Credits Observed", start: 188, length: 8, color: "purple", decoded_value: credits.to_s)
    end

    regions
  end

  # --- Vote Account Decoder ---

  def decode_vote_account(bytes)
    return [] if bytes.length < 109

    version = read_u32(bytes, 0)
    regions = [
      Region.new(id: "vote_version", name: "Version", start: 0, length: 4, color: "yellow", decoded_value: version.to_s)
    ]

    node_pubkey = encode_base58(bytes[4, 32])
    regions << Region.new(id: "node_pubkey", name: "Node Pubkey", start: 4, length: 32, color: "blue", decoded_value: node_pubkey)

    auth_voter_epoch = read_u64(bytes, 36)
    regions << Region.new(id: "authorized_voter_epoch", name: "Authorized Voter Epoch", start: 36, length: 8, color: "orange", decoded_value: auth_voter_epoch.to_s)

    auth_voter = encode_base58(bytes[44, 32])
    regions << Region.new(id: "authorized_voter", name: "Authorized Voter", start: 44, length: 32, color: "green", decoded_value: auth_voter)

    auth_withdrawer = encode_base58(bytes[76, 32])
    regions << Region.new(id: "authorized_vote_withdrawer", name: "Authorized Withdrawer", start: 76, length: 32, color: "green", decoded_value: auth_withdrawer)

    commission = bytes[108]
    regions << Region.new(id: "commission", name: "Commission", start: 108, length: 1, color: "purple", decoded_value: "#{commission}%")

    # Remaining bytes are variable-length vote history
    if bytes.length > 109
      regions << Region.new(id: "vote_history", name: "Vote History", start: 109, length: bytes.length - 109, color: "gray", decoded_value: "#{bytes.length - 109} bytes")
    end

    regions
  end

  # --- Metaplex Token Metadata Decoder ---

  METAPLEX_KEYS = {
    0 => "Uninitialized",
    1 => "EditionV1",
    2 => "MasterEditionV1",
    3 => "ReservationListV1",
    4 => "MetadataV1",
    5 => "ReservationListV2",
    6 => "MasterEditionV2",
    7 => "EditionMarker",
    8 => "UseAuthorityRecord",
    9 => "CollectionAuthorityRecord",
    10 => "TokenOwnedEscrow",
    11 => "TokenRecord",
    12 => "MetadataDelegate",
    13 => "EditionMarkerV2",
    14 => "HolderDelegate"
  }.freeze

  TOKEN_STANDARDS = {
    0 => "NonFungible",
    1 => "FungibleAsset",
    2 => "Fungible",
    3 => "NonFungibleEdition",
    4 => "ProgrammableNonFungible",
    5 => "ProgrammableNonFungibleEdition"
  }.freeze

  def decode_metaplex_metadata(bytes)
    return [] if bytes.length < 1

    key = bytes[0]
    key_label = METAPLEX_KEYS[key] || "Unknown (#{key})"
    regions = [ Region.new(id: "meta_key", name: "Key", start: 0, length: 1, color: "yellow", decoded_value: key_label) ]

    # Only MetadataV1 has the layout decoded below
    return regions unless key == 4
    return regions if bytes.length < 65

    regions << Region.new(id: "meta_update_authority", name: "Update Authority", start: 1, length: 32, color: "green", decoded_value: encode_base58(bytes[1, 32]))
    regions << Region.new(id: "meta_mint", name: "Mint", start: 33, length: 32, color: "blue", decoded_value: encode_base58(bytes[33, 32]))

    offset = 65

    # Name: u32 length + bytes (padded to 32)
    return regions if bytes.length < offset + 4
    name_len = read_u32(bytes, offset)
    regions << Region.new(id: "meta_name_len", name: "Name Length", start: offset, length: 4, color: "orange", decoded_value: name_len.to_s)
    offset += 4
    if name_len > 0 && bytes.length >= offset + name_len
      regions << Region.new(id: "meta_name", name: "Name", start: offset, length: name_len, color: "purple", decoded_value: read_padded_string(bytes, offset, name_len))
      offset += name_len
    end

    # Symbol: u32 length + bytes (padded to 10)
    return regions if bytes.length < offset + 4
    sym_len = read_u32(bytes, offset)
    regions << Region.new(id: "meta_symbol_len", name: "Symbol Length", start: offset, length: 4, color: "orange", decoded_value: sym_len.to_s)
    offset += 4
    if sym_len > 0 && bytes.length >= offset + sym_len
      regions << Region.new(id: "meta_symbol", name: "Symbol", start: offset, length: sym_len, color: "cyan", decoded_value: read_padded_string(bytes, offset, sym_len))
      offset += sym_len
    end

    # URI: u32 length + bytes (padded to 200)
    return regions if bytes.length < offset + 4
    uri_len = read_u32(bytes, offset)
    regions << Region.new(id: "meta_uri_len", name: "URI Length", start: offset, length: 4, color: "orange", decoded_value: uri_len.to_s)
    offset += 4
    if uri_len > 0 && bytes.length >= offset + uri_len
      regions << Region.new(id: "meta_uri", name: "URI", start: offset, length: uri_len, color: "yellow", decoded_value: read_padded_string(bytes, offset, uri_len))
      offset += uri_len
    end

    # seller_fee_basis_points (u16)
    return regions if bytes.length < offset + 2
    sfbp = read_u16(bytes, offset)
    regions << Region.new(id: "seller_fee_basis_points", name: "Seller Fee", start: offset, length: 2, color: "purple", decoded_value: "#{sfbp} bps (#{(sfbp / 100.0).round(2)}%)")
    offset += 2

    # creators: Option<Vec<Creator>>
    return regions if bytes.length < offset + 1
    creators_flag = bytes[offset]
    regions << Region.new(id: "creators_option", name: "Creators", start: offset, length: 1, color: "orange", decoded_value: creators_flag == 1 ? "Some" : "None")
    offset += 1

    if creators_flag == 1 && bytes.length >= offset + 4
      num = read_u32(bytes, offset)
      regions << Region.new(id: "creators_count", name: "Creators Count", start: offset, length: 4, color: "orange", decoded_value: num.to_s)
      offset += 4

      num.times do |i|
        break if bytes.length < offset + 34
        addr = encode_base58(bytes[offset, 32])
        verified = bytes[offset + 32] == 1
        share = bytes[offset + 33]
        label = "#{addr[0, 6]}…#{addr[-4..]} verified=#{verified} share=#{share}%"
        regions << Region.new(
          id: "creator_#{i}",
          name: "Creator ##{i + 1}",
          start: offset,
          length: 34,
          color: "green",
          decoded_value: label,
          description: "Creator entry: 32-byte pubkey + 1-byte verified flag + 1-byte royalty share (0-100%)."
        )
        offset += 34
      end
    end

    # primary_sale_happened (bool)
    if bytes.length >= offset + 1
      regions << Region.new(id: "primary_sale_happened", name: "Primary Sale Happened", start: offset, length: 1, color: "blue", decoded_value: bytes[offset] == 1 ? "true" : "false")
      offset += 1
    end

    # is_mutable (bool)
    if bytes.length >= offset + 1
      regions << Region.new(id: "is_mutable", name: "Is Mutable", start: offset, length: 1, color: "blue", decoded_value: bytes[offset] == 1 ? "true" : "false")
      offset += 1
    end

    # edition_nonce: Option<u8>
    if bytes.length >= offset + 1
      flag = bytes[offset]
      if flag == 1 && bytes.length >= offset + 2
        regions << Region.new(id: "edition_nonce", name: "Edition Nonce", start: offset, length: 2, color: "cyan", decoded_value: "Some(#{bytes[offset + 1]})")
        offset += 2
      else
        regions << Region.new(id: "edition_nonce", name: "Edition Nonce", start: offset, length: 1, color: "cyan", decoded_value: "None")
        offset += 1
      end
    end

    # token_standard: Option<TokenStandard>
    if bytes.length >= offset + 1
      flag = bytes[offset]
      if flag == 1 && bytes.length >= offset + 2
        std = TOKEN_STANDARDS[bytes[offset + 1]] || "Unknown (#{bytes[offset + 1]})"
        regions << Region.new(id: "token_standard", name: "Token Standard", start: offset, length: 2, color: "yellow", decoded_value: std)
        offset += 2
      else
        regions << Region.new(id: "token_standard", name: "Token Standard", start: offset, length: 1, color: "yellow", decoded_value: "None")
        offset += 1
      end
    end

    # collection: Option<{verified: bool, key: Pubkey}> — 1 + 1 + 32 = 34 when Some
    if bytes.length >= offset + 1
      flag = bytes[offset]
      if flag == 1 && bytes.length >= offset + 34
        verified = bytes[offset + 1] == 1
        col_key = encode_base58(bytes[offset + 2, 32])
        regions << Region.new(id: "collection", name: "Collection", start: offset, length: 34, color: "purple", decoded_value: "verified=#{verified} key=#{col_key[0, 6]}…#{col_key[-4..]}")
        offset += 34
      else
        regions << Region.new(id: "collection", name: "Collection", start: offset, length: 1, color: "purple", decoded_value: "None")
        offset += 1
      end
    end

    # uses: Option<Uses> — 1 + 17 when Some
    if bytes.length >= offset + 1
      flag = bytes[offset]
      if flag == 1 && bytes.length >= offset + 18
        regions << Region.new(id: "uses", name: "Uses", start: offset, length: 18, color: "orange", decoded_value: "Some (use_method + remaining + total)")
        offset += 18
      else
        regions << Region.new(id: "uses", name: "Uses", start: offset, length: 1, color: "orange", decoded_value: "None")
        offset += 1
      end
    end

    # Any remaining bytes are collection_details + programmable_config options
    if offset < bytes.length
      remaining = bytes.length - offset
      regions << Region.new(id: "meta_tail", name: "Collection Details / Programmable Config", start: offset, length: remaining, color: "gray", decoded_value: "#{remaining} bytes of remaining optional fields")
    end

    regions
  end

  # --- Address Lookup Table Decoder ---

  ALT_ACTIVE_SLOT = 0xFFFFFFFFFFFFFFFF

  def decode_address_lookup_table(bytes)
    return [] if bytes.length < 56

    discriminator = read_u32(bytes, 0)
    return [] unless discriminator == 1 # Only the LookupTable variant is decoded

    regions = [
      Region.new(id: "lut_discriminator", name: "Type", start: 0, length: 4, color: "yellow", decoded_value: "LookupTable")
    ]

    deactivation_slot = read_u64(bytes, 4)
    deactivation_label = deactivation_slot == ALT_ACTIVE_SLOT ? "Active (max u64)" : deactivation_slot.to_s
    regions << Region.new(id: "lut_deactivation_slot", name: "Deactivation Slot", start: 4, length: 8, color: "orange", decoded_value: deactivation_label)

    last_extended = read_u64(bytes, 12)
    regions << Region.new(id: "lut_last_extended_slot", name: "Last Extended Slot", start: 12, length: 8, color: "blue", decoded_value: last_extended.to_s)

    start_index = bytes[20]
    regions << Region.new(id: "lut_start_index", name: "Last Extension Start Index", start: 20, length: 1, color: "purple", decoded_value: start_index.to_s)

    auth_option = bytes[21]
    regions << Region.new(id: "lut_auth_option", name: "Authority Option", start: 21, length: 1, color: "orange", decoded_value: auth_option == 1 ? "Some" : "None")

    if auth_option == 1
      authority = encode_base58(bytes[22, 32])
      regions << Region.new(id: "lut_authority", name: "Authority", start: 22, length: 32, color: "green", decoded_value: authority)
    else
      regions << Region.new(id: "lut_authority", name: "Authority (frozen)", start: 22, length: 32, color: "gray", decoded_value: "None — table is permanently frozen")
    end

    regions << Region.new(id: "lut_padding", name: "Padding", start: 54, length: 2, color: "gray", decoded_value: "Reserved (always 0)")

    # Addresses array: tightly packed 32-byte pubkeys, up to 256 entries.
    # All addresses share id="lookup_address" so the legend has a single chip,
    # but each region carries its own decoded_value so hover shows the right pubkey.
    pos = 56
    index = 0
    while pos + 32 <= bytes.length
      addr = encode_base58(bytes[pos, 32])
      regions << Region.new(
        id: "lookup_address",
        name: "Lookup Address",
        start: pos,
        length: 32,
        color: "cyan",
        decoded_value: "##{index + 1}: #{addr}"
      )
      pos += 32
      index += 1
    end

    regions
  end

  # --- SPL Token Multisig Decoder ---

  MULTISIG_SIZE = 355
  MULTISIG_MAX_SIGNERS = 11

  def decode_spl_multisig(bytes)
    return [] unless bytes.length == MULTISIG_SIZE

    m = bytes[0]
    n = bytes[1]
    is_initialized = bytes[2]

    regions = [
      Region.new(id: "multisig_m", name: "M (Threshold)", start: 0, length: 1, color: "purple", decoded_value: m.to_s),
      Region.new(id: "multisig_n", name: "N (Total Signers)", start: 1, length: 1, color: "purple", decoded_value: n.to_s),
      Region.new(id: "multisig_is_initialized", name: "Is Initialized", start: 2, length: 1, color: "yellow", decoded_value: is_initialized == 1 ? "Yes" : "No")
    ]

    # 11 signer slots × 32 bytes, starting at offset 3
    MULTISIG_MAX_SIGNERS.times do |i|
      offset = 3 + i * 32
      slot_bytes = bytes[offset, 32]
      empty = slot_bytes.all?(&:zero?)

      if empty
        regions << Region.new(
          id: "multisig_signer_empty",
          name: "Signer Slot ##{i + 1} (empty)",
          start: offset,
          length: 32,
          color: "gray",
          decoded_value: "Unused"
        )
      else
        regions << Region.new(
          id: "multisig_signer",
          name: "Signer ##{i + 1}",
          start: offset,
          length: 32,
          color: "green",
          decoded_value: encode_base58(slot_bytes)
        )
      end
    end

    regions
  end

  # --- Token-2022 Extensions ---

  EXTENSION_TYPES = {
    0 => "Uninitialized",
    1 => "TransferFeeConfig",
    2 => "TransferFeeAmount",
    3 => "MintCloseAuthority",
    4 => "ConfidentialTransferMint",
    5 => "ConfidentialTransferAccount",
    6 => "DefaultAccountState",
    7 => "ImmutableOwner",
    8 => "MemoTransfer",
    9 => "NonTransferable",
    10 => "InterestBearingConfig",
    11 => "CpiGuard",
    12 => "PermanentDelegate",
    13 => "NonTransferableAccount",
    14 => "TransferHook",
    15 => "TransferHookAccount",
    16 => "ConfidentialTransferFee",
    17 => "ConfidentialTransferFeeAmount",
    18 => "MetadataPointer",
    19 => "TokenMetadata",
    20 => "GroupPointer",
    21 => "GroupMemberPointer",
    22 => "TokenGroup",
    23 => "TokenGroupMember"
  }.freeze

  EXTENSION_COLORS = %w[blue green purple cyan orange yellow].freeze

  def decode_token_extensions(bytes, base_size)
    regions = []
    pos = base_size

    # Account type byte (1 = Mint, 2 = Account)
    if pos < bytes.length
      account_type = bytes[pos]
      type_label = case account_type
      when 1 then "Mint"
      when 2 then "Account"
      else "Unknown (#{account_type})"
      end
      regions << Region.new(id: "ext_account_type", name: "Account Type (Token-2022)", start: pos, length: 1, color: "yellow", decoded_value: type_label)
      pos += 1
    end

    # Parse TLV extensions
    ext_index = 0
    while pos + 4 <= bytes.length
      ext_type_raw = read_u16(bytes, pos)
      ext_length = read_u16(bytes, pos + 2)
      ext_name = EXTENSION_TYPES[ext_type_raw] || "Extension #{ext_type_raw}"
      color = EXTENSION_COLORS[ext_index % EXTENSION_COLORS.length]

      # Extension header (type + length)
      regions << Region.new(
        id: "ext_#{ext_index}_header",
        name: "#{ext_name} (header)",
        start: pos,
        length: 4,
        color: "orange",
        decoded_value: "Type: #{ext_type_raw}, Length: #{ext_length}"
      )
      pos += 4

      # Zero-length extensions (ImmutableOwner, NonTransferable)
      if ext_length == 0
        ext_decoded = decode_extension_data(ext_type_raw, bytes, pos, 0)
        # Zero-length extensions have no data region to add
        ext_index += 1
        next
      end

      break if pos + ext_length > bytes.length

      # Extension data — decode known extensions
      ext_decoded = decode_extension_data(ext_type_raw, bytes, pos, ext_length)

      if ext_decoded.any?
        ext_decoded.each_with_index do |region, i|
          region_with_offset = Region.new(
            id: "ext_#{ext_index}_#{i}",
            name: region[:name],
            start: pos + region[:offset],
            length: region[:length],
            color: color,
            decoded_value: region[:value]
          )
          regions << region_with_offset
        end
      else
        regions << Region.new(
          id: "ext_#{ext_index}_data",
          name: ext_name,
          start: pos,
          length: ext_length,
          color: color,
          decoded_value: "#{ext_length} bytes"
        )
      end

      pos += ext_length
      ext_index += 1
    end

    regions
  end

  def decode_extension_data(ext_type, bytes, offset, length)
    case ext_type
    when 1 # TransferFeeConfig
      fields = []
      if length >= 32
        fields << { name: "Transfer Fee Config Authority", offset: 0, length: 32, value: encode_base58(bytes[offset, 32]) }
      end
      if length >= 64
        fields << { name: "Withdraw Withheld Authority", offset: 32, length: 32, value: encode_base58(bytes[offset + 32, 32]) }
      end
      if length > 64
        fields << { name: "Fee Config Data", offset: 64, length: length - 64, value: "#{length - 64} bytes" }
      end
      fields
    when 2 # TransferFeeAmount
      if length >= 8
        withheld = read_u64(bytes, offset)
        [ { name: "Withheld Amount", offset: 0, length: 8, value: withheld.to_s } ]
      else
        []
      end
    when 3 # MintCloseAuthority
      if length >= 32
        [ { name: "Close Authority", offset: 0, length: 32, value: encode_base58(bytes[offset, 32]) } ]
      else
        []
      end
    when 6 # DefaultAccountState
      if length >= 1
        state = case bytes[offset]
        when 0 then "Uninitialized"
        when 1 then "Initialized"
        when 2 then "Frozen"
        else "Unknown (#{bytes[offset]})"
        end
        [ { name: "Default State", offset: 0, length: 1, value: state } ]
      else
        []
      end
    when 7 # ImmutableOwner — 0 bytes, presence only
      []
    when 8 # MemoTransfer
      if length >= 1
        required = bytes[offset] == 1 ? "Required" : "Not Required"
        [ { name: "Require Incoming Memos", offset: 0, length: 1, value: required } ]
      else
        []
      end
    when 9 # NonTransferable — 0 bytes, presence only
      []
    when 10 # InterestBearingConfig
      fields = []
      if length >= 32
        fields << { name: "Rate Authority", offset: 0, length: 32, value: encode_base58(bytes[offset, 32]) }
      end
      if length >= 40
        init_ts = read_i64(bytes, offset + 32)
        fields << { name: "Initialization Timestamp", offset: 32, length: 8, value: init_ts.to_s }
      end
      if length >= 42
        pre_rate = read_i16(bytes, offset + 40)
        fields << { name: "Pre-update Average Rate", offset: 40, length: 2, value: "#{pre_rate} bps" }
      end
      if length >= 50
        last_ts = read_i64(bytes, offset + 42)
        fields << { name: "Last Update Timestamp", offset: 42, length: 8, value: last_ts.to_s }
      end
      if length >= 52
        current_rate = read_i16(bytes, offset + 50)
        fields << { name: "Current Rate", offset: 50, length: 2, value: "#{current_rate} bps" }
      end
      fields
    when 11 # CpiGuard
      if length >= 1
        locked = bytes[offset] == 1 ? "Locked" : "Unlocked"
        [ { name: "Lock CPI", offset: 0, length: 1, value: locked } ]
      else
        []
      end
    when 12 # PermanentDelegate
      if length >= 32
        [ { name: "Delegate", offset: 0, length: 32, value: encode_base58(bytes[offset, 32]) } ]
      else
        []
      end
    when 14 # TransferHook
      fields = []
      if length >= 32
        fields << { name: "Hook Authority", offset: 0, length: 32, value: encode_base58(bytes[offset, 32]) }
      end
      if length >= 64
        fields << { name: "Hook Program ID", offset: 32, length: 32, value: encode_base58(bytes[offset + 32, 32]) }
      end
      fields
    when 18 # MetadataPointer
      fields = []
      if length >= 32
        fields << { name: "Pointer Authority", offset: 0, length: 32, value: encode_base58(bytes[offset, 32]) }
      end
      if length >= 64
        fields << { name: "Metadata Address", offset: 32, length: 32, value: encode_base58(bytes[offset + 32, 32]) }
      end
      fields
    when 19 # TokenMetadata
      fields = []
      if length >= 32
        fields << { name: "Update Authority", offset: 0, length: 32, value: encode_base58(bytes[offset, 32]) }
      end
      if length >= 64
        fields << { name: "Mint", offset: 32, length: 32, value: encode_base58(bytes[offset + 32, 32]) }
      end
      # After the two pubkeys, there are borsh-encoded strings: name, symbol, uri
      str_offset = 64
      %w[Name Symbol URI].each do |label|
        break if str_offset + 4 > length
        str_len = read_u32(bytes, offset + str_offset)
        str_offset += 4
        break if str_offset + str_len > length
        str_val = bytes[offset + str_offset, str_len].pack("C*").force_encoding("UTF-8")
        fields << { name: label, offset: str_offset - 4, length: 4 + str_len, value: str_val }
        str_offset += str_len
      end
      fields
    else
      []
    end
  end

  def read_u32(bytes, offset)
    bytes[offset, 4].pack("C*").unpack1("V")
  end

  def read_u64(bytes, offset)
    bytes[offset, 8].pack("C*").unpack1("Q<")
  end

  def encode_base58(bytes)
    Base58.binary_to_base58(bytes.pack("C*"), :bitcoin)
  end

  def read_padded_string(bytes, offset, length)
    bytes[offset, length].pack("C*").force_encoding("UTF-8").delete("\x00").strip
  end
end
