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
    Category.new(slug: "transactions", name: "Versioned Transactions", description: "How modern Solana transactions reference accounts via lookup tables instead of inlining each 32-byte pubkey, lifting the ~35-account ceiling.",          order: 5),
    Category.new(slug: "programs",     name: "Programs (Executable)",  description: "On-chain programs are ELF shared objects loaded by one of Solana's BPF loaders.",                                                                          order: 6)
  ].freeze

  CONTENT_DIR = Rails.root.join("content", "learn")

  def all
    @entries ||= load_all
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
    @entries = nil
  end

  private

  FRONTMATTER_RE = /\A---\s*\n(.*?\n)---\s*\n?(.*)\z/m

  def load_all
    raise "content/learn/ directory missing at #{CONTENT_DIR}" unless CONTENT_DIR.exist?

    paths = Dir.glob(CONTENT_DIR.join("**", "*.md"))
    raise "content/learn/ is empty — no Learn entries found" if paths.empty?

    paths.map { |path| parse_entry(path) }
         .sort_by { |e| [category_order(e.category), e.slug.to_s] }
  end

  def parse_entry(path)
    raw = File.read(path)
    unless (match = FRONTMATTER_RE.match(raw))
      raise "Missing or malformed YAML frontmatter in #{path}"
    end

    meta = YAML.safe_load(match[1], permitted_classes: [ Date ])
    body = match[2].to_s.strip.presence

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
