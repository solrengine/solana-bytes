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
    offset_map[offset]
  end

  def hex_rows
    raw_bytes.each_slice(BYTES_PER_ROW).each_with_index.map do |row_bytes, index|
      HexRow.new(index * BYTES_PER_ROW, row_bytes, self)
    end
  end

  def offset_map
    @offset_map ||= {}.tap do |map|
      regions.each { |r| r.length.times { |i| map[r.start + i] = r } }
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
    "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr" => "Memo Program",
    "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s" => "Metaplex Token Metadata"
  }.freeze

  # A named region of bytes with a color and decoded value
  Region = Struct.new(:id, :name, :start, :length, :color, :decoded_value, :description, keyword_init: true) do
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

  # Opaque backgrounds (pre-blended with ~#0a0a14 dark base) so rain canvas doesn't bleed through
  REGION_COLORS = {
    "blue"   => { text: "#93c5fd", bg: "#0f1a2e",  legend_bg: "rgba(59,130,246,0.3)",  legend_border: "rgba(59,130,246,0.5)" },
    "green"  => { text: "#86efac", bg: "#0c1a12",   legend_bg: "rgba(34,197,94,0.3)",   legend_border: "rgba(34,197,94,0.5)" },
    "orange" => { text: "#fdba74", bg: "#1a1208",  legend_bg: "rgba(249,115,22,0.3)",  legend_border: "rgba(249,115,22,0.5)" },
    "purple" => { text: "#c4b5fd", bg: "#14102a",  legend_bg: "rgba(139,92,246,0.3)",  legend_border: "rgba(139,92,246,0.5)" },
    "yellow" => { text: "#fde047", bg: "#1a1806",   legend_bg: "rgba(234,179,8,0.3)",   legend_border: "rgba(234,179,8,0.5)" },
    "cyan"   => { text: "#67e8f9", bg: "#0a1a1e",   legend_bg: "rgba(6,182,212,0.3)",   legend_border: "rgba(6,182,212,0.5)" },
    "gray"   => { text: "#d1d5db", bg: "#111318", legend_bg: "rgba(107,114,128,0.3)", legend_border: "rgba(107,114,128,0.5)" }
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
end
