module RegionDecoder
  extend self

  Region = AccountPresenter::Region

  def decode(owner, bytes)
    regions = case owner
    when "BPFLoaderUpgradeab1e11111111111111111111111"
      decode_bpf_upgradeable(bytes)
    when "BPFLoader2111111111111111111111111111111111",
         "BPFLoader1111111111111111111111111111111111"
      decode_elf(bytes)
    when "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
         "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
      if bytes.length >= 165
        decode_spl_token(bytes)
      elsif bytes.length >= 82
        decode_spl_mint(bytes)
      else
        []
      end
    else
      # Try ELF detection for any executable data
      if bytes.length >= 4 && bytes[0..3] == [ 0x7f, 0x45, 0x4c, 0x46 ]
        decode_elf(bytes)
      else
        []
      end
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

      break if ext_length == 0 || pos + ext_length > bytes.length

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
    when 3 # MintCloseAuthority
      if length >= 32
        [{ name: "Close Authority", offset: 0, length: 32, value: encode_base58(bytes[offset, 32]) }]
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
        [{ name: "Default State", offset: 0, length: 1, value: state }]
      else
        []
      end
    when 12 # PermanentDelegate
      if length >= 32
        [{ name: "Delegate", offset: 0, length: 32, value: encode_base58(bytes[offset, 32]) }]
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
end
