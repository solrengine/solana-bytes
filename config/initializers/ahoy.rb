class Ahoy::Store < Ahoy::DatabaseStore
end

# GDPR-compliant: no cookies, masked IPs
Ahoy.cookies = :none
Ahoy.mask_ips = true
Ahoy.server_side_visits = :when_needed
Ahoy.api = false
Ahoy.geocode = true
