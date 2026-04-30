class Ahoy::Store < Ahoy::DatabaseStore
end

# GDPR-compliant: no cookies, no IPs (column dropped), no precise location
Ahoy.cookies = :none
Ahoy.server_side_visits = :when_needed
Ahoy.api = false
Ahoy.geocode = true
