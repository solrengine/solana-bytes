module ApplicationHelper
  LOGO_VARIANTS = %i[light dark].freeze

  def country_flag(country)
    return "" if country.blank?

    code = country.length == 2 ? country.upcase : CountryCodes::NAME_TO_CODE[country]
    return "" unless code

    code.chars.map { |c| (c.ord - 65 + 0x1F1E6).chr(Encoding::UTF_8) }.join
  end

  def pixel_logo(variant: :dark, size: 32, css_class: nil)
    raise ArgumentError, "pixel_logo variant must be one of #{LOGO_VARIANTS.inspect}, got #{variant.inspect}" unless LOGO_VARIANTS.include?(variant)

    image_tag(
      "sb-logo-#{variant}.png",
      alt: "Solana Bytes",
      width: size,
      height: size,
      class: css_class,
      style: "image-rendering:pixelated;display:inline-block;vertical-align:middle"
    )
  end
end
