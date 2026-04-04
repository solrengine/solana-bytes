module ApplicationHelper
  COUNTRY_NAME_TO_CODE = {
    "Afghanistan" => "AF", "Albania" => "AL", "Algeria" => "DZ", "Argentina" => "AR",
    "Australia" => "AU", "Austria" => "AT", "Bangladesh" => "BD", "Belgium" => "BE",
    "Brazil" => "BR", "Canada" => "CA", "Chile" => "CL", "China" => "CN",
    "Colombia" => "CO", "Croatia" => "HR", "Czech Republic" => "CZ", "Czechia" => "CZ",
    "Denmark" => "DK", "Egypt" => "EG", "Estonia" => "EE", "Finland" => "FI",
    "France" => "FR", "Germany" => "DE", "Greece" => "GR", "Hong Kong" => "HK",
    "Hungary" => "HU", "India" => "IN", "Indonesia" => "ID", "Ireland" => "IE",
    "Israel" => "IL", "Italy" => "IT", "Japan" => "JP", "Kenya" => "KE",
    "Latvia" => "LV", "Lithuania" => "LT", "Malaysia" => "MY", "Mexico" => "MX",
    "Netherlands" => "NL", "New Zealand" => "NZ", "Nigeria" => "NG", "Norway" => "NO",
    "Pakistan" => "PK", "Peru" => "PE", "Philippines" => "PH", "Poland" => "PL",
    "Portugal" => "PT", "Romania" => "RO", "Russia" => "RU", "Saudi Arabia" => "SA",
    "Singapore" => "SG", "Slovakia" => "SK", "South Africa" => "ZA", "South Korea" => "KR",
    "Spain" => "ES", "Sweden" => "SE", "Switzerland" => "CH", "Taiwan" => "TW",
    "Thailand" => "TH", "Turkey" => "TR", "Ukraine" => "UA", "United Arab Emirates" => "AE",
    "United Kingdom" => "GB", "United States" => "US", "Vietnam" => "VN"
  }.freeze

  def country_flag(country)
    return "" if country.blank?

    code = country.length == 2 ? country.upcase : COUNTRY_NAME_TO_CODE[country]
    return "" unless code

    code.chars.map { |c| (c.ord - 65 + 0x1F1E6).chr(Encoding::UTF_8) }.join
  end
end
