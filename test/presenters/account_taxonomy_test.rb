require "test_helper"

class AccountTaxonomyTest < ActiveSupport::TestCase
  LIVE_SLUGS = %w[mint token-account stake-account vote-account token-metadata address-lookup-table].freeze
  DRAFT_NAMES = [ "Multisig", "Token-2022 Mint/Account + Extensions", "BPF Upgradeable Program", "ELF Bytecode" ].freeze

  test "all six live entries have a slug, category, example_address" do
    LIVE_SLUGS.each do |slug|
      entry = AccountTaxonomy.find_by_slug(slug)
      assert_not_nil entry, "expected an AccountTaxonomy entry with slug=#{slug.inspect}"
      assert_equal slug, entry.slug
      assert entry.live?, "#{slug} should have status: live"
      assert_not_nil entry.category, "#{slug} should belong to a category"
      assert_not_nil entry.example_address, "#{slug} should carry an example_address for the Learn live sample"
    end
  end

  test "draft entries are present but flagged" do
    DRAFT_NAMES.each do |name|
      entry = AccountTaxonomy.flat_entries.find { |e| e.name == name }
      assert_not_nil entry, "taxonomy should still contain #{name.inspect}"
      assert entry.draft?, "#{name.inspect} should have status: draft (U22)"
    end
  end

  test "find_by_slug returns the matching entry" do
    assert_equal "Mint", AccountTaxonomy.find_by_slug("mint").name
    assert_equal "Address Lookup Table", AccountTaxonomy.find_by_slug("address-lookup-table").name
  end

  test "find_by_slug returns nil for unknown slugs" do
    assert_nil AccountTaxonomy.find_by_slug("nonexistent")
    assert_nil AccountTaxonomy.find_by_slug("")
    assert_nil AccountTaxonomy.find_by_slug(nil)
  end

  test "all live entries have a substantive markdown body (U22)" do
    LIVE_SLUGS.each do |slug|
      entry = AccountTaxonomy.find_by_slug(slug)
      assert_not_nil entry.body, "#{slug} should have a body populated by U22"
      word_count = entry.body.to_s.split.length
      assert word_count >= 150, "#{slug} body should be at least 150 words (was #{word_count})"
      # Every live page must include a Byte layout section.
      assert_includes entry.body, "## Byte layout",
        "#{slug} body should contain a '## Byte layout' section"
    end
  end

  test "draft entries have nil body" do
    DRAFT_NAMES.each do |name|
      entry = AccountTaxonomy.flat_entries.find { |e| e.name == name }
      assert_nil entry.body, "#{name.inspect} is a draft so body should be nil"
      # Backward-compat alias keeps returning nil too.
      assert_nil entry.explainer_text
    end
  end

  test "every slug is a lowercase kebab-case identifier (URL-safe)" do
    AccountTaxonomy.flat_entries.each do |entry|
      assert_match %r{\A[a-z][a-z0-9-]*\z}, entry.slug,
        "Entry #{entry.name.inspect} has malformed slug #{entry.slug.inspect}"
    end
  end

  test "learn_path returns the canonical /learn/<category>/<slug> URL" do
    mint = AccountTaxonomy.find_by_slug("mint")
    assert_equal "/learn/spl-token/mint", mint.learn_path

    alt = AccountTaxonomy.find_by_slug("address-lookup-table")
    assert_equal "/learn/transactions/address-lookup-table", alt.learn_path
  end

  test "categories are ordered and indexed" do
    slugs = AccountTaxonomy.categories.map(&:slug)
    assert_equal %w[spl-token token-2022 consensus metaplex transactions programs], slugs
    assert_equal "SPL Token", AccountTaxonomy.find_category("spl-token").name
    assert_nil AccountTaxonomy.find_category("nonexistent")
  end

  test "find_by_category returns entries scoped to that category" do
    spl = AccountTaxonomy.find_by_category("spl-token").map(&:slug)
    assert_includes spl, "mint"
    assert_includes spl, "token-account"
    assert_includes spl, "multisig"
    assert_empty AccountTaxonomy.find_by_category("nonexistent")
  end
end
