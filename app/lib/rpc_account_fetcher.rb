class RpcAccountFetcher
  PER_ATTEMPT_TIMEOUT = 4 # seconds
  RETRY_DELAYS = [ 0.5, 1.0 ].freeze

  def self.fetch(address, network: "mainnet-beta", expires_in: 2.minutes, race_condition_ttl: nil)
    cache_key = "rpc:account:#{network}:#{address}"
    options = { expires_in: expires_in, skip_nil: true }
    options[:race_condition_ttl] = race_condition_ttl if race_condition_ttl
    Rails.cache.fetch(cache_key, **options) do
      fetch_from_rpc(address, network: network)
    end
  end

  def self.fetch_from_rpc(address, network: "mainnet-beta")
    client = Solrengine::Rpc::Client.new(rpc_url: rpc_url_for(network))

    3.times do |attempt|
      begin
        Timeout.timeout(PER_ATTEMPT_TIMEOUT) do
          response = client.request("getAccountInfo", [ address, { "encoding" => "base64" } ])
          return response if response.present?
        end
      rescue Timeout::Error,
             SocketError,
             Errno::ECONNREFUSED,
             Errno::ECONNRESET,
             Errno::ETIMEDOUT,
             Solrengine::Rpc::Error => e
        Rails.logger.error("RPC #{e.class} (attempt #{attempt + 1}/3) for #{address}: #{e.message}")
        Sentry.capture_exception(e, extra: { address: address, network: network, attempt: attempt + 1 }) if attempt == 2 && defined?(Sentry)
        sleep(RETRY_DELAYS[attempt] + rand(0.0..0.2)) if attempt < 2
      rescue StandardError => e
        # Fallback: solrengine-rpc 0.1.0 may surface unwrapped Net::HTTP / JSON errors.
        # Treat as transient and retry, but report the unexpected class to Sentry.
        Rails.logger.error("RPC #{e.class} (attempt #{attempt + 1}/3) for #{address}: #{e.message}")
        Sentry.capture_exception(e, extra: { address: address, network: network, attempt: attempt + 1, fallback: true }) if attempt == 2 && defined?(Sentry)
        sleep(RETRY_DELAYS[attempt] + rand(0.0..0.2)) if attempt < 2
      end
    end

    nil
  end

  def self.rpc_url_for(network)
    case network
    when "devnet" then ENV.fetch("SOLANA_RPC_DEVNET_URL", "https://api.devnet.solana.com")
    when "testnet" then ENV.fetch("SOLANA_RPC_TESTNET_URL", "https://api.testnet.solana.com")
    else ENV.fetch("SOLANA_RPC_MAINNET_URL", "https://api.mainnet-beta.solana.com")
    end
  end
end
