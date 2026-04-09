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

  VALID_ADDRESSES = CHALLENGE_ACCOUNTS.map { |a| a[:address] }.to_set.freeze

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
    @streak = verified_streak
    @total_stars = verified_total_stars
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

    # Sign the challenge state so it can't be tampered with
    @challenge_token = challenge_verifier.generate({
      address: @address,
      target_field: @target_region.name,
      streak: @streak,
      total_stars: @total_stars,
      issued_at: Time.current.to_i
    })

    # Pre-generate signed tokens for correct answer (streak+1) with 1/2/3 star variants
    @next_token_3star = next_challenge_token(@streak + 1, @total_stars + 3)
    @next_token_2star = next_challenge_token(@streak + 1, @total_stars + 2)
    @next_token_1star = next_challenge_token(@streak + 1, @total_stars + 1)

    ahoy.track "challenge_started", mode: logged_in? ? "ranked" : "practice"
  end

  def save_result
    unless logged_in?
      return render json: { error: "Login required" }, status: :unauthorized
    end

    # Verify the signed challenge token
    token_data = begin
      challenge_verifier.verify(params[:challenge_token]).with_indifferent_access
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      return render json: { error: "Invalid challenge token" }, status: :unprocessable_entity
    end

    # Reject expired tokens (5 minutes max)
    if Time.current.to_i - token_data[:issued_at] > 300
      return render json: { error: "Challenge expired" }, status: :unprocessable_entity
    end

    # Use server-verified values for streak and address
    result = current_user.challenge_results.create!(
      account_address: token_data[:address],
      target_field: token_data[:target_field],
      time_seconds: params[:time_seconds].to_f,
      attempts: [ params[:attempts].to_i, 1 ].max,
      stars: [ params[:stars].to_i, 3 ].min,
      streak: [ token_data[:streak], 0 ].max
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

    best_streak, total_challenges, total_stars = current_user.challenge_results.pick(
      Arel.sql("MAX(streak)"),
      Arel.sql("COUNT(*)"),
      Arel.sql("SUM(stars)")
    )

    {
      best_streak: best_streak || 0,
      total_challenges: total_challenges || 0,
      total_stars: total_stars || 0
    }
  end

  def next_challenge_token(streak, total_stars)
    token = challenge_verifier.generate({ streak: streak, total_stars: total_stars, issued_at: Time.current.to_i })
    "/challenge?token=#{CGI.escape(token)}"
  end

  def challenge_verifier
    @challenge_verifier ||= Rails.application.message_verifier("challenge")
  end

  # Verify streak/stars from a signed token passed via query params (from previous correct answer)
  def verified_streak
    return 0 unless params[:token].present?
    data = challenge_verifier.verify(params[:token]).with_indifferent_access
    [ data[:streak].to_i, 0 ].max
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    0
  end

  def verified_total_stars
    return 0 unless params[:token].present?
    data = challenge_verifier.verify(params[:token]).with_indifferent_access
    [ data[:total_stars].to_i, 0 ].max
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    0
  end
end
