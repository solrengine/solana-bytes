require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "pixel_logo renders dark variant by default" do
    html = pixel_logo
    assert_match %r{<img[^>]+src="[^"]*sb-logo-dark[^"]*"}, html
    assert_match %r{width="32"}, html
    assert_match %r{height="32"}, html
    assert_match %r{image-rendering:pixelated}, html
    assert_match %r{alt="Solana Bytes"}, html
  end

  test "pixel_logo accepts light variant" do
    html = pixel_logo(variant: :light)
    assert_match %r{<img[^>]+src="[^"]*sb-logo-light[^"]*"}, html
  end

  test "pixel_logo respects custom size" do
    html = pixel_logo(size: 24)
    assert_match %r{width="24"}, html
    assert_match %r{height="24"}, html
  end

  test "pixel_logo accepts custom css class" do
    html = pixel_logo(css_class: "shrink-0")
    assert_match %r{class="shrink-0"}, html
  end

  test "pixel_logo raises on invalid variant" do
    assert_raises(ArgumentError) { pixel_logo(variant: :purple) }
  end
end
