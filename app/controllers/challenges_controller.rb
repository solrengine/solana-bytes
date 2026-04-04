class ChallengesController < ApplicationController
  include RpcFetchable

  layout "game", only: :show

  # Compact accounts only — keeps the hex grid manageable for gameplay
  CHALLENGE_ACCOUNTS = [
    # SPL Mints (82 bytes, 7-8 fields) — easier
    { address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", label: "USDC Mint" },
    { address: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB", label: "USDT Mint" },
    { address: "So11111111111111111111111111111111111111112", label: "Wrapped SOL Mint" },
    { address: "7dHbWXmci3dT8UFYWYZweBLXgycu7Y3iL6trKn1Y7ARj", label: "stSOL Mint" },
    # Token Accounts (165 bytes, 11 fields) — harder
    { address: "CfWX7o2TswwbxusJ4hCaPobu2jLCb1hfXuXJQjVq3jQF", label: "Phantom wSOL" },
    { address: "ALZv1FW3Bc5uRtci2UHnYS34DEWCmfkN5btEYDKms9yU", label: "Jupiter USDC" },
    { address: "9bZucpaB5cSFHD5DSTsvZftUqqP1KgC8SGQkVDu42BBe", label: "Binance USDC" },
    { address: "8hGBwecvELGSWQkfA64biQtzQKLoa8GoMKvWevCWwJbo", label: "Binance USDT" },
  ].freeze

  MAX_DATA_DISPLAY = 512
  MAX_WRONG_ATTEMPTS = 3

  def index
    @user_stats = current_user_stats
    @top_streaks = ChallengeResult.includes(:user).leaderboard.limit(5)
  end

  def show
    account_info = CHALLENGE_ACCOUNTS.sample
    @address = account_info[:address]
    @account_label = account_info[:label]
    @streak = (params[:streak] || 0).to_i
    @max_wrong = MAX_WRONG_ATTEMPTS

    result = fetch_account_cached(@address, network: "mainnet-beta", expires_in: 10.minutes)

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

    ahoy.track "challenge_started", mode: logged_in? ? "ranked" : "practice"
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
      stars: [ params[:stars].to_i, 3 ].min,
      streak: [ params[:streak].to_i, 0 ].max
    )

    render json: {
      id: result.id,
      streak: result.streak,
      best_streak: current_user.best_streak
    }
  rescue ActiveRecord::RecordInvalid => e
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
end
