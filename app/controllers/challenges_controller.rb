require "digest"

class ChallengesController < ApplicationController
  layout "game", only: :show

  # Compact accounts only — keeps the hex grid manageable for gameplay
  CHALLENGE_ACCOUNTS = [
    # SPL Mints (82 bytes, 7-8 fields)
    { address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", label: "USDC Mint",        tier: :easy },
    { address: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB", label: "USDT Mint",        tier: :easy },
    { address: "So11111111111111111111111111111111111111112",  label: "Wrapped SOL Mint", tier: :easy },
    { address: "7dHbWXmci3dT8UFYWYZweBLXgycu7Y3iL6trKn1Y7ARj", label: "stSOL Mint",       tier: :easy },
    # Token Accounts (165 bytes, 11 fields)
    { address: "CfWX7o2TswwbxusJ4hCaPobu2jLCb1hfXuXJQjVq3jQF", label: "Phantom wSOL",  tier: :medium },
    { address: "ALZv1FW3Bc5uRtci2UHnYS34DEWCmfkN5btEYDKms9yU", label: "Jupiter USDC",  tier: :medium },
    { address: "9bZucpaB5cSFHD5DSTsvZftUqqP1KgC8SGQkVDu42BBe", label: "Binance USDC",  tier: :medium },
    { address: "8hGBwecvELGSWQkfA64biQtzQKLoa8GoMKvWevCWwJbo", label: "Binance USDT",  tier: :medium },
    # Stake Accounts (200 bytes, 13 fields) + Vote Account (3762 bytes)
    { address: "CbrKVVDv6irzm4SYv8YnhJkN6wCTnYw9S7SqdwavCrRt", label: "Stake Account", tier: :hard },
    { address: "EmutJdbKJ55hUyth15bar8ZxDCchR44udAXWYg9eLLDL", label: "Stake Account", tier: :hard },
    { address: "J2nUHEAgZFRyuJbFjdqPrAa9gyWDuc7hErtDQHPhsYRp", label: "Vote Account",  tier: :hard }
  ].freeze

  TIERS = {
    "easy"   => { label: "Easy",   description: "82-byte Mints — 7 fields",          color: "text-green-400" },
    "medium" => { label: "Medium", description: "165-byte Token Accounts — 11 fields", color: "text-yellow-400" },
    "hard"   => { label: "Hard",   description: "Stake & Vote — 13+ fields",         color: "text-red-400" }
  }.freeze

  MAX_DATA_DISPLAY = 512
  MAX_WRONG_ATTEMPTS = 3

  def index
    @user_stats = current_user_stats
    @top_streaks = ChallengeResult.includes(:user).leaderboard.limit(5)
    @active_tier = resolved_tier
  end

  def show
    @tier = resolved_tier
    session[:challenge_tier] = @tier

    pool = challenge_pool(@tier)
    account_info = pool.sample

    if account_info.nil?
      flash[:alert] = "No challenge accounts available for this tier."
      return redirect_to challenges_path
    end

    @address = account_info[:address]
    @account_label = account_info[:label]
    @streak = verified_streak
    @total_stars = verified_total_stars
    @max_wrong = MAX_WRONG_ATTEMPTS

    result = RpcAccountFetcher.fetch(@address, network: "mainnet-beta", expires_in: 10.minutes)

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
      user_id: current_user&.id,
      issued_at: Time.current.to_i
    }, purpose: :challenge_progress)

    # Pre-generate signed tokens for correct answer (streak+1) with 1/2/3 star variants
    @next_token_3star = next_challenge_token(@streak + 1, @total_stars + 3, @tier)
    @next_token_2star = next_challenge_token(@streak + 1, @total_stars + 2, @tier)
    @next_token_1star = next_challenge_token(@streak + 1, @total_stars + 1, @tier)

    ahoy.track "challenge_started", mode: logged_in? ? "ranked" : "practice", tier: @tier || "all"
  end

  def save_result
    unless logged_in?
      return render json: { error: "Login required" }, status: :unauthorized
    end

    # Verify the signed challenge token
    token_data = begin
      challenge_verifier.verify(params[:challenge_token], purpose: :challenge_progress).with_indifferent_access
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      return render json: { error: "Invalid challenge token" }, status: :unprocessable_entity
    end

    # Reject expired tokens (10 minutes max)
    if Time.current.to_i - token_data[:issued_at].to_i > 600
      return render json: { error: "Challenge expired" }, status: :unprocessable_entity
    end

    # Bind token to user (anonymous tokens have user_id: nil; save_result requires login)
    if token_data[:user_id].to_i != current_user.id
      return render json: { error: "Token user mismatch" }, status: :forbidden
    end

    token_digest = Digest::SHA256.hexdigest(params[:challenge_token].to_s)

    # Use server-verified values for streak and address; idempotent by token digest
    result = current_user.challenge_results.create!(
      account_address: token_data[:address],
      target_field: token_data[:target_field],
      time_seconds: params[:time_seconds].to_f,
      attempts: [ params[:attempts].to_i, 1 ].max,
      total_stars: [ params[:total_stars].to_i, 600 ].min,
      streak: [ token_data[:streak].to_i, 0 ].max,
      challenge_token_digest: token_digest
    )

    render json: {
      id: result.id,
      streak: result.streak,
      total_stars: result.total_stars,
      best_streak: current_user.best_streak
    }
  rescue ActiveRecord::RecordNotUnique
    existing = current_user.challenge_results.find_by(challenge_token_digest: token_digest)
    render json: {
      id: existing&.id,
      streak: existing&.streak,
      total_stars: existing&.total_stars,
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
      Arel.sql("SUM(total_stars)")
    )

    {
      best_streak: best_streak || 0,
      total_challenges: total_challenges || 0,
      total_stars: total_stars || 0
    }
  end

  def next_challenge_token(streak, total_stars, tier = nil)
    token = challenge_verifier.generate(
      { streak: streak, total_stars: total_stars, user_id: current_user&.id, issued_at: Time.current.to_i },
      purpose: :challenge_progress
    )
    challenge_path(token: token, tier: tier)
  end

  def resolved_tier
    candidate = (params[:tier] || session[:challenge_tier]).to_s
    TIERS.key?(candidate) ? candidate : nil
  end

  def challenge_pool(tier)
    return CHALLENGE_ACCOUNTS if tier.nil?
    CHALLENGE_ACCOUNTS.select { |a| a[:tier].to_s == tier }
  end

  def challenge_verifier
    @challenge_verifier ||= Rails.application.message_verifier("challenge")
  end

  # Verify and memoize the signed token data passed via query params (from previous correct answer).
  # Returns a hash with streak/total_stars/user_id, or nil if missing/invalid/expired.
  def verified_token_data
    return @verified_token_data if defined?(@verified_token_data)

    @verified_token_data = begin
      if params[:token].blank?
        nil
      else
        data = challenge_verifier.verify(params[:token], purpose: :challenge_progress).with_indifferent_access
        if Time.current.to_i - data[:issued_at].to_i > 600
          nil
        else
          data
        end
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
  end

  def verified_streak
    [ verified_token_data&.dig(:streak).to_i, 0 ].max
  end

  def verified_total_stars
    [ verified_token_data&.dig(:total_stars).to_i, 0 ].max
  end
end
