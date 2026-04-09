# Rate limiting configuration
# See https://github.com/rack/rack-attack

class Rack::Attack
  # General rate limit: 60 requests per minute per IP
  throttle("req/ip", limit: 60, period: 60) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # RPC-triggering endpoints: 20 per minute per IP
  throttle("rpc/ip", limit: 20, period: 60) do |req|
    req.ip if req.path.start_with?("/accounts/", "/challenge") && req.get?
  end

  # Game result saving: 10 per minute per IP
  throttle("save/ip", limit: 10, period: 60) do |req|
    req.ip if req.path == "/challenge/result" && req.post?
  end

  # Address lookups: 30 per minute per IP
  throttle("lookup/ip", limit: 30, period: 60) do |req|
    req.ip if req.path == "/lookup" && req.post?
  end

  # Customize the response for throttled requests
  self.throttled_responder = lambda do |matched, period, limit, count|
    now = Time.current
    retry_after = (period - now.to_i % period).to_s

    headers = {
      "Content-Type" => "text/plain",
      "Retry-After" => retry_after
    }

    [ 429, headers, [ "Rate limit exceeded. Try again in #{retry_after} seconds.\n" ] ]
  end
end
