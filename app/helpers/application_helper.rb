module ApplicationHelper
  def country_flag(country)
    return "" if country.blank?

    code = country.length == 2 ? country.upcase : CountryCodes::NAME_TO_CODE[country]
    return "" unless code

    code.chars.map { |c| (c.ord - 65 + 0x1F1E6).chr(Encoding::UTF_8) }.join
  end
end
