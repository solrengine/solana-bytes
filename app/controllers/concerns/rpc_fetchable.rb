module RpcFetchable
  extend ActiveSupport::Concern

  RPC_TIMEOUT = 8 # seconds — total budget for all retries

  private

  def fetch_account_cached(address, network: "mainnet-beta", expires_in: 2.minutes)
    cache_key = "rpc:account:#{network}:#{address}"

    Rails.cache.fetch(cache_key, expires_in: expires_in) do
      fetch_account_from_rpc(address, network: network)
    end
  end

  def fetch_account_from_rpc(address, network: "mainnet-beta")
    rpc_url = rpc_url_for(network)
    client = Solrengine::Rpc::Client.new(rpc_url: rpc_url)

    Timeout.timeout(RPC_TIMEOUT) do
      3.times do |attempt|
        response = client.request("getAccountInfo", [ address, { "encoding" => "base64" } ])
        return response if response.present?
      rescue Timeout::Error
        raise # let the outer timeout propagate
      rescue => e
        Rails.logger.error("RPC error (attempt #{attempt + 1}/3): #{e.class} - #{e.message}")
        sleep(0.5 * (attempt + 1)) if attempt < 2
      end
    end

    nil
  rescue Timeout::Error
    Rails.logger.error("RPC timeout after #{RPC_TIMEOUT}s for #{address}")
    nil
  end

  def rpc_url_for(network)
    case network
    when "devnet"
      ENV.fetch("SOLANA_RPC_DEVNET_URL", "https://api.devnet.solana.com")
    when "testnet"
      ENV.fetch("SOLANA_RPC_TESTNET_URL", "https://api.testnet.solana.com")
    else
      ENV.fetch("SOLANA_RPC_MAINNET_URL", "https://api.mainnet-beta.solana.com")
    end
  end
end
