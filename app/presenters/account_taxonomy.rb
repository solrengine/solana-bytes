require "yaml"

# Loads /learn reference entries from content/learn/<category>/<slug>.md.
# Each file carries YAML frontmatter (typed metadata) and a Markdown body
# rendered to HTML in the view layer via kramdown.
#
# Public API preserved across the U22 migration:
#   AccountTaxonomy.flat_entries           → Array<Entry> (every status)
#   AccountTaxonomy.find_by_slug(slug)     → Entry or nil
#   AccountTaxonomy.find_by_category(slug) → Array<Entry>
#   AccountTaxonomy.categories             → Array<Category> (ordered)
#   AccountTaxonomy.find_category(slug)    → Category or nil
module AccountTaxonomy
  extend self

  Entry = Struct.new(
    :name, :slug, :category, :kind, :status,
    :program_id, :program_label, :size,
    :summary, :example_address, :example_label, :fields,
    :body, :see_also, :sources, :last_verified,
    keyword_init: true
  ) do
    # `.description` and `.explainer_text` are pre-migration accessors used
    # by views/tests written before content moved into Markdown files.
    # Resolving them through `summary` / `body` keeps the legacy call sites
    # working without churn.
    def description = summary
    def explainer_text = body

    # Canonical URL — always use this instead of hand-building /learn paths.
    def learn_path
      return nil unless category && slug
      "/learn/#{category}/#{slug}"
    end

    def live? = status == "live"
    def draft? = status == "draft"
  end

  Category = Struct.new(:slug, :name, :description, :order, keyword_init: true) do
    def entries = AccountTaxonomy.find_by_category(slug)
    def live_entries = entries.select(&:live?)
  end

  CATEGORIES = [
    Category.new(slug: "spl-token",    name: "SPL Token",              description: "The canonical fungible token program. Every SPL token on Solana uses this layout.",                                                                       order: 1),
    Category.new(slug: "token-2022",   name: "Token-2022 Extensions",  description: "Token-2022 extends SPL Token with post-base TLV blocks for fees, interest, confidential transfers, metadata, and more.",                                  order: 2),
    Category.new(slug: "consensus",    name: "Staking & Voting",       description: "Core accounts for Solana's proof-of-stake consensus. Every validator has a Vote account; every delegator has a Stake account.",                          order: 3),
    Category.new(slug: "metaplex",     name: "Metaplex (NFTs)",        description: "The Metaplex Token Metadata program attaches rich metadata to SPL mints — the foundation of every Solana NFT.",                                            order: 4),
    Category.new(slug: "bubblegum",    name: "Compressed NFTs",        description: "Bubblegum stores NFTs in a Merkle tree instead of individual accounts — millions of NFTs for the cost of a few accounts.",                              order: 5),
    Category.new(slug: "transactions", name: "Transactions",           description: "How Solana transactions are encoded on the wire — signatures, message header, account ordering, instructions, and versioned lookup tables.",            order: 6),
    Category.new(slug: "native",       name: "Native Program Instructions", description: "Instruction data layouts for Solana's built-in programs — System, Stake, Vote, Compute Budget.",                                                       order: 7),
    Category.new(slug: "programs",     name: "Programs (Executable)",  description: "On-chain programs are ELF shared objects loaded by one of Solana's BPF loaders.",                                                                          order: 8),
    Category.new(slug: "anchor",       name: "Anchor",                 description: "Conventions the Anchor framework layers on top of raw accounts and instructions — discriminators, space, and rent.",                                     order: 9),
    Category.new(slug: "addressing",   name: "Addresses & PDAs",       description: "How Solana derives program-controlled addresses and associated token accounts from seeds.",                                                              order: 10),
    Category.new(slug: "encoding",     name: "Encoding & Layout",      description: "Cross-cutting serialization rules — optional types, Borsh vs bincode, and how rent ties to account size.",                                              order: 11)
  ].freeze

  CONTENT_DIR = Rails.root.join("content", "learn")

  def all
    (@by_locale ||= {})[I18n.locale] ||= load_all(I18n.locale)
  end

  alias_method :flat_entries, :all

  def find_by_slug(slug)
    return nil if slug.blank?
    all.find { |e| e.slug == slug.to_s }
  end

  def find_by_category(category_slug)
    return [] if category_slug.blank?
    all.select { |e| e.category == category_slug.to_s }
  end

  def categories = CATEGORIES

  def find_category(slug)
    return nil if slug.blank?
    CATEGORIES.find { |c| c.slug == slug.to_s }
  end

  # Test/dev hook: drop the memoized entries so a subsequent .all reloads
  # from disk. Used when content/learn/*.md is edited in a running process.
  def reset!
    @by_locale = nil
  end

  private

  FRONTMATTER_RE = /\A---\s*\n(.*?\n)---\s*\n?(.*)\z/m
  # Matches a locale-variant filename like "mint.es.md" so the base loader
  # can skip translation overlays when enumerating canonical entries.
  LOCALE_SUFFIX_RE = /\.[a-z]{2}\.md\z/

  def load_all(locale)
    raise "content/learn/ directory missing at #{CONTENT_DIR}" unless CONTENT_DIR.exist?

    base_paths = Dir.glob(CONTENT_DIR.join("**", "*.md")).reject { |p| p.match?(LOCALE_SUFFIX_RE) }
    raise "content/learn/ is empty — no Learn entries found" if base_paths.empty?

    base_paths.map { |path| build_entry(path, locale) }
              .sort_by { |e| [ category_order(e.category), e.slug.to_s ] }
  end

  # Builds an Entry from its canonical (default-locale) file. When the
  # requested locale isn't the default and a sibling <slug>.<locale>.md
  # exists, its name/summary/body overlay the base values. Structural
  # frontmatter (offsets, sizes, program_id, sources, slug, category) is
  # never translated — it lives only in the base file, so byte-level facts
  # can't drift between languages. Missing translation → English fallback.
  def build_entry(base_path, locale)
    meta, body = parse_file(base_path)
    entry = entry_from(meta, body)
    return entry if locale.to_s == I18n.default_locale.to_s

    overlay_path = base_path.sub(/\.md\z/, ".#{locale}.md")
    return entry unless File.exist?(overlay_path)

    t_meta, t_body = parse_file(overlay_path)
    entry.name    = t_meta["name"].presence    || entry.name
    entry.summary = t_meta["summary"].presence || entry.summary
    entry.body    = t_body.presence            || entry.body
    entry
  end

  def parse_file(path)
    raw = File.read(path)
    unless (match = FRONTMATTER_RE.match(raw))
      raise "Missing or malformed YAML frontmatter in #{path}"
    end
    meta = YAML.safe_load(match[1], permitted_classes: [ Date ]) || {}
    body = match[2].to_s.strip.presence
    [ meta, body ]
  end

  def entry_from(meta, body)
    Entry.new(
      name:            meta["name"],
      slug:            meta["slug"],
      category:        meta["category"],
      kind:            meta["kind"] || "account",
      status:          meta["status"] || "live",
      program_id:      meta["program_id"],
      program_label:   meta["program_label"],
      size:            meta["size"],
      summary:         meta["summary"],
      example_address: meta["example_address"],
      example_label:   meta["example_label"],
      fields:          meta["fields"] || [],
      body:            body,
      see_also:        meta["see_also"] || [],
      sources:         meta["sources"] || [],
      last_verified:   meta["last_verified"]&.to_s
    )
  end

  def category_order(slug)
    CATEGORIES.find { |c| c.slug == slug }&.order || 99
  end
end
