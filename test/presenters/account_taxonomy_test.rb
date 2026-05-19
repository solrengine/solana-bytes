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

  test "explainer_text field exists on Entry (U21 will populate it)" do
    mint = AccountTaxonomy.find_by_slug("mint")
    # explainer_text is empty for now; U21 fills it. The test guards that
    # the struct field exists so U21 doesn't have to re-extend the struct.
    assert_respond_to mint, :explainer_text
  end

  test "every slug is a lowercase kebab-case identifier (URL-safe)" do
    AccountTaxonomy.flat_entries.each do |entry|
      next unless entry.slug
      assert_match %r{\A[a-z][a-z0-9-]*\z}, entry.slug,
        "Entry #{entry.name.inspect} has malformed slug #{entry.slug.inspect}"
    end
  end
end
