class ChallengesController < ApplicationController
  CHALLENGE_ACCOUNTS = [
    { address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", label: "USDC Mint", difficulty: "easy" },
    { address: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB", label: "USDT Mint", difficulty: "easy" },
    { address: "2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo", label: "PYUSD (Token-2022)", difficulty: "hard" }
  ].freeze

  MAX_DATA_DISPLAY = 10_240

  def show
    account_info = CHALLENGE_ACCOUNTS.sample
    @address = account_info[:address]
    @difficulty = account_info[:difficulty]

    result = fetch_account(@address)

    if result.nil?
      flash[:alert] = "Could not reach Solana mainnet. Check your connection and try again."
      return redirect_to challenges_path
    end

    account_value = result.dig("result", "value")

    if account_value.nil?
      flash[:alert] = "Account #{@address[0..7]}... not found on mainnet."
      return redirect_to challenges_path
    end

    @account = AccountPresenter.new(@address, account_value, max_data: MAX_DATA_DISPLAY)

    # Pick a random region as the target (exclude generic "Data")
    meaningful_regions = @account.regions.select { |r| r.name != "Data" && r.decoded_value.present? }
    @target_region = meaningful_regions.sample

    unless @target_region
      flash[:alert] = "Could not generate a challenge. Try again."
      return redirect_to challenges_path
    end
  end

  def index
    # Landing page for the game
  end

  private

  def fetch_account(address)
    # Challenge accounts are always on mainnet
    rpc_url = rpc_url_for("mainnet-beta")

    3.times do |attempt|
      client = Solrengine::Rpc::Client.new(rpc_url: rpc_url)
      response = client.request("getAccountInfo", [ address, { "encoding" => "base64" } ])
      return response if response.present?
    rescue => e
      Rails.logger.error("RPC error (attempt #{attempt + 1}/3): #{e.class} - #{e.message}")
      sleep(0.5 * (attempt + 1)) if attempt < 2
    end

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
