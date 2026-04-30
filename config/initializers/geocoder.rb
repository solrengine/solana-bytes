geoip_path = Rails.root.join("storage/geoip/GeoLite2-Country.mmdb")

if File.exist?(geoip_path)
  Geocoder.configure(
    ip_lookup: :geoip2,
    geoip2: { file: geoip_path.to_s }
  )
end
