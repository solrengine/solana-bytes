class AccountPresenter
  LAMPORTS_PER_SOL = 1_000_000_000.0
  BYTES_PER_ROW = 16

  attr_reader :address, :lamports, :owner, :executable, :rent_epoch, :raw_bytes, :truncated

  def initialize(address, account_data, max_data: nil)
    @address = address
    @lamports = account_data["lamports"]
    @owner = account_data["owner"]
    @executable = account_data["executable"]
    @rent_epoch = account_data["rentEpoch"]

    data_b64 = account_data.dig("data", 0) || ""
    full_bytes = Base64.decode64(data_b64).bytes

    if max_data && full_bytes.length > max_data
      @raw_bytes = full_bytes[0...max_data]
      @truncated = full_bytes.length
    else
      @raw_bytes = full_bytes
      @truncated = nil
    end
  end

  def balance_sol
    return 0 unless lamports
    lamports / LAMPORTS_PER_SOL
  end

  def data_length
    truncated || raw_bytes.length
  end

  def regions
    @regions ||= RegionDecoder.decode(owner, raw_bytes)
  end

  def region_for_offset(offset)
    regions.find { |r| offset >= r.start && offset < r.start + r.length }
  end

  def hex_rows
    raw_bytes.each_slice(BYTES_PER_ROW).each_with_index.map do |row_bytes, index|
      HexRow.new(index * BYTES_PER_ROW, row_bytes, self)
    end
  end

  def owner_label
    KNOWN_PROGRAMS[owner] || short_address(owner)
  end

  def short_address(addr)
    return "" unless addr
    "#{addr[0..3]}...#{addr[-4..]}"
  end

  KNOWN_PROGRAMS = {
    "11111111111111111111111111111111" => "System Program",
    "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA" => "Token Program",
    "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb" => "Token-2022 Program",
    "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL" => "Associated Token Program",
    "BPFLoaderUpgradeab1e11111111111111111111111" => "BPF Upgradeable Loader",
    "BPFLoader2111111111111111111111111111111111" => "BPF Loader",
    "Vote111111111111111111111111111111111111111" => "Vote Program",
    "Stake11111111111111111111111111111111111111" => "Stake Program",
    "ComputeBudget111111111111111111111111111111" => "Compute Budget Program",
    "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr" => "Memo Program"
  }.freeze

  # A named region of bytes with a color and decoded value
  Region = Struct.new(:id, :name, :start, :length, :color, :decoded_value, keyword_init: true) do
    def text_color
      REGION_COLORS.dig(color, :text) || "#d1d5db"
    end

    def bg_color
      REGION_COLORS.dig(color, :bg) || "rgba(107,114,128,0.15)"
    end

    def legend_bg
      REGION_COLORS.dig(color, :legend_bg) || "rgba(107,114,128,0.3)"
    end

    def legend_border
      REGION_COLORS.dig(color, :legend_border) || "rgba(107,114,128,0.5)"
    end
  end

  REGION_COLORS = {
    "blue"   => { text: "#93c5fd", bg: "rgba(59,130,246,0.25)",  legend_bg: "rgba(59,130,246,0.3)",  legend_border: "rgba(59,130,246,0.5)" },
    "green"  => { text: "#86efac", bg: "rgba(34,197,94,0.25)",   legend_bg: "rgba(34,197,94,0.3)",   legend_border: "rgba(34,197,94,0.5)" },
    "orange" => { text: "#fdba74", bg: "rgba(249,115,22,0.25)",  legend_bg: "rgba(249,115,22,0.3)",  legend_border: "rgba(249,115,22,0.5)" },
    "purple" => { text: "#c4b5fd", bg: "rgba(139,92,246,0.25)",  legend_bg: "rgba(139,92,246,0.3)",  legend_border: "rgba(139,92,246,0.5)" },
    "yellow" => { text: "#fde047", bg: "rgba(234,179,8,0.25)",   legend_bg: "rgba(234,179,8,0.3)",   legend_border: "rgba(234,179,8,0.5)" },
    "cyan"   => { text: "#67e8f9", bg: "rgba(6,182,212,0.25)",   legend_bg: "rgba(6,182,212,0.3)",   legend_border: "rgba(6,182,212,0.5)" },
    "gray"   => { text: "#d1d5db", bg: "rgba(107,114,128,0.15)", legend_bg: "rgba(107,114,128,0.3)", legend_border: "rgba(107,114,128,0.5)" }
  }.freeze

  class HexRow
    attr_reader :offset, :bytes

    def initialize(offset, bytes, presenter)
      @offset = offset
      @bytes = bytes
      @presenter = presenter
    end

    def offset_hex
      format("%04x", offset)
    end

    def cells
      bytes.each_with_index.map do |byte, i|
        cell_offset = offset + i
        region = @presenter.region_for_offset(cell_offset)
        HexCell.new(byte, cell_offset, region)
      end
    end

    def ascii
      bytes.map { |b| (b >= 0x20 && b <= 0x7e) ? b.chr : "." }.join
    end

    def padding_cells
      BYTES_PER_ROW - bytes.length
    end
  end

  HexCell = Struct.new(:byte, :offset, :region) do
    def hex
      format("%02x", byte)
    end

    def region_id
      region&.id
    end

    def text_color
      region&.text_color || "#d1d5db"
    end

    def bg_color
      region&.bg_color || "rgba(107,114,128,0.15)"
    end
  end

  module RegionDecoder
    extend self

    def decode(owner, bytes)
      regions = case owner
      when "BPFLoaderUpgradeab1e11111111111111111111111"
        decode_bpf_upgradeable(bytes)
      when "BPFLoader2111111111111111111111111111111111",
           "BPFLoader1111111111111111111111111111111111"
        decode_elf(bytes)
      when "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
           "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
        decode_spl_token(bytes)
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

      regions
    end

    def read_u32(bytes, offset)
      bytes[offset, 4].pack("C*").unpack1("V")
    end

    def read_u64(bytes, offset)
      bytes[offset, 8].pack("C*").unpack1("Q<")
    end

    def encode_base58(bytes)
      # Simple base58 encoding for display
      num = bytes.pack("C*").unpack1("H*").to_i(16)
      return "1" * bytes.count(0) if num.zero?

      alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
      result = ""
      while num > 0
        num, remainder = num.divmod(58)
        result = alphabet[remainder] + result
      end

      leading_zeros = bytes.take_while { |b| b.zero? }.length
      ("1" * leading_zeros) + result
    end
  end
end
