class AccountsController < ApplicationController
  EXAMPLE_ADDRESSES = [
    { address: "11111111111111111111111111111111", label: "System Program" },
    { address: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", label: "Token Program" },
    { address: "So11111111111111111111111111111111111111112", label: "Wrapped SOL Mint" }
  ].freeze

  MAX_DATA_DISPLAY = 10_240 # 10KB

  def lookup
    redirect_to account_path(address: params[:address].to_s.strip)
  end

  def show
    @address = params[:address]

    unless valid_base58?(@address)
      flash.now[:alert] = "Invalid Solana address"
      return render :error, status: :unprocessable_entity
    end

    result = fetch_account(@address)

    if result.nil?
      flash.now[:alert] = "Could not reach Solana network. Try again."
      return render :error, status: :service_unavailable
    end

    account_value = result.dig("result", "value")

    if account_value.nil?
      flash.now[:alert] = "Account not found — it may not exist or has been closed."
      return render :error, status: :not_found
    end

    @account = AccountPresenter.new(@address, account_value, max_data: MAX_DATA_DISPLAY)
  end

  private

  def fetch_account(address)
    network = session[:solana_network] || ENV.fetch("SOLANA_NETWORK", "mainnet-beta")
    rpc_url = rpc_url_for(network)
    client = Solrengine::Rpc::Client.new(rpc_url: rpc_url)
    response = client.request("getAccountInfo", [ address, { "encoding" => "base64" } ])
    response.presence
  rescue => e
    Rails.logger.error("RPC error: #{e.class} - #{e.message}")
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

  def valid_base58?(address)
    return false if address.blank?
    return false unless address.length.between?(32, 44)
    address.match?(/\A[1-9A-HJ-NP-Za-km-z]+\z/)
  end
end
