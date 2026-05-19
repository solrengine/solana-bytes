require "test_helper"

class AccountTaxonomyTest < ActiveSupport::TestCase
  IN_SCOPE_SLUGS = %w[mint token-account stake-account vote-account token-metadata address-lookup-table].freeze
  OUT_OF_SCOPE_NAMES = ["Multisig", "Token-2022 Mint/Account + Extensions", "BPF Upgradeable Program", "ELF Bytecode"].freeze

  test "all six in-scope entries have a slug" do
    IN_SCOPE_SLUGS.each do |slug|
      entry = AccountTaxonomy.find_by_slug(slug)
      assert_not_nil entry, "expected an AccountTaxonomy entry with slug=#{slug.inspect}"
      assert_equal slug, entry.slug
      assert_not_nil entry.example_address, "#{slug} should carry an example_address for the Learn live sample"
    end
  end

  test "out-of-scope entries have slug: nil so /learn does not list them" do
    OUT_OF_SCOPE_NAMES.each do |name|
      entry = AccountTaxonomy.flat_entries.find { |e| e.name == name }
      assert_not_nil entry, "taxonomy should still contain #{name.inspect}"
      assert_nil entry.slug, "#{name.inspect} should have slug: nil (not surfaced on /learn)"
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

  test "all six in-scope entries have substantive explainer_text (U21)" do
    IN_SCOPE_SLUGS.each do |slug|
      entry = AccountTaxonomy.find_by_slug(slug)
      assert_not_nil entry.explainer_text, "#{slug} should have explainer_text populated by U21"
      word_count = entry.explainer_text.to_s.split.length
      assert word_count >= 150, "#{slug} explainer_text should be at least 150 words (was #{word_count})"
      # Markdown is NOT parsed in U17 (simple_format renders plain prose);
      # raw markdown syntax in the prose would bleed through as visible
      # asterisks / hashes / brackets. Guard against that here.
      assert_no_match %r{\*\*|^#\s|\[[^\]]+\]\([^)]+\)}, entry.explainer_text,
        "#{slug} explainer_text should not contain markdown syntax (rendered via simple_format)"
    end
  end

  test "out-of-scope entries have nil explainer_text" do
    OUT_OF_SCOPE_NAMES.each do |name|
      entry = AccountTaxonomy.flat_entries.find { |e| e.name == name }
      assert_nil entry.explainer_text, "#{name.inspect} is not Learn-addressable so explainer_text should be nil"
    end
  end

  test "every slug is a lowercase kebab-case identifier (URL-safe)" do
    AccountTaxonomy.flat_entries.each do |entry|
      next unless entry.slug
      assert_match %r{\A[a-z][a-z0-9-]*\z}, entry.slug,
        "Entry #{entry.name.inspect} has malformed slug #{entry.slug.inspect}"
    end
  end
end
