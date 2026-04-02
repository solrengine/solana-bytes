Solrengine::Rpc.configure do |config|
  config.network = ENV.fetch("SOLANA_NETWORK", "mainnet-beta")
end
