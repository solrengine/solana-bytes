class ChallengesController < ApplicationController
  layout "game", only: :show

  CHALLENGE_ACCOUNTS = [
    { address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", label: "USDC Mint" },
    { address: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB", label: "USDT Mint" },
    { address: "So11111111111111111111111111111111111111112", label: "Wrapped SOL Mint" },
    { address: "2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo", label: "PYUSD (Token-2022)" },
    { address: "7dHbWXmci3dT8UFYWYZweBLXgycu7Y3iL6trKn1Y7ARj", label: "stSOL Mint" }
  ].freeze

  MAX_DATA_DISPLAY = 10_240
  MAX_WRONG_ATTEMPTS = 3

  def index
    @user_stats = current_user_stats
    @top_streaks = ChallengeResult.includes(:user).leaderboard.limit(5)
  end

  def show
    account_info = CHALLENGE_ACCOUNTS.sample
    @address = account_info[:address]
    @streak = (params[:streak] || 0).to_i
    @max_wrong = MAX_WRONG_ATTEMPTS

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

    meaningful_regions = @account.regions.select { |r| r.name != "Data" && r.decoded_value.present? }
    @target_region = meaningful_regions.sample

    unless @target_region
      flash[:alert] = "Could not generate a challenge. Try again."
      return redirect_to challenges_path
    end
  end

  def save_result
    unless logged_in?
      return render json: { error: "Login required" }, status: :unauthorized
    end

    result = current_user.challenge_results.create!(
      account_address: params[:account_address],
      target_field: params[:target_field],
      time_seconds: params[:time_seconds].to_f,
      attempts: params[:attempts].to_i,
      stars: params[:stars].to_i,
      streak: params[:streak].to_i
    )

    render json: {
      id: result.id,
      streak: result.streak,
      best_streak: current_user.best_streak
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def current_user_stats
    return nil unless logged_in?

    {
      best_streak: current_user.best_streak,
      total_challenges: current_user.total_challenges,
      total_stars: current_user.challenge_results.sum(:stars)
    }
  end

  def fetch_account(address)
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
