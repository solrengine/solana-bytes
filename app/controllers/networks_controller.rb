class NetworksController < ApplicationController
  VALID_NETWORKS = %w[mainnet-beta devnet testnet].freeze

  def update
    network = params[:network]
    session[:solana_network] = network if VALID_NETWORKS.include?(network)
    redirect_back(fallback_location: root_path)
  end
end
