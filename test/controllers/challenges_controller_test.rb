require "test_helper"

class ChallengesControllerTest < ActionDispatch::IntegrationTest
  def challenge_verifier
    Rails.application.message_verifier("challenge")
  end

  def valid_token(overrides = {})
    challenge_verifier.generate({
      address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
      target_field: "Supply",
      streak: 3,
      total_stars: 7,
      issued_at: Time.current.to_i
    }.merge(overrides))
  end

  def next_challenge_token(streak: 1, total_stars: 3)
    challenge_verifier.generate({
      streak: streak,
      total_stars: total_stars,
      issued_at: Time.current.to_i
    })
  end

  # --- Token Verification Tests ---

  test "challenge verifier round-trips data correctly" do
    data = { address: "test", streak: 5, issued_at: Time.current.to_i }
    token = challenge_verifier.generate(data)
    result = challenge_verifier.verify(token)

    assert_equal "test", result["address"]
    assert_equal 5, result["streak"]
  end

  test "tampered token raises InvalidSignature" do
    token = valid_token
    tampered = token.reverse

    assert_raises(ActiveSupport::MessageVerifier::InvalidSignature) do
      challenge_verifier.verify(tampered)
    end
  end

  test "next challenge token carries streak forward" do
    token = next_challenge_token(streak: 5, total_stars: 12)
    data = challenge_verifier.verify(token)

    assert_equal 5, data["streak"]
    assert_equal 12, data["total_stars"]
  end

  # --- Model Validation Tests ---

  test "ChallengeResult rejects invalid star values" do
    result = ChallengeResult.new(
      account_address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
      target_field: "Supply",
      time_seconds: 10.0,
      attempts: 2,
      stars: 5,
      streak: 1
    )

    assert_not result.valid?
    assert result.errors[:stars].any?
  end

  test "ChallengeResult rejects negative streak" do
    result = ChallengeResult.new(
      account_address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
      target_field: "Supply",
      time_seconds: 10.0,
      attempts: 2,
      stars: 2,
      streak: -1
    )

    assert_not result.valid?
    assert result.errors[:streak].any?
  end

  test "ChallengeResult rejects streak over 200" do
    result = ChallengeResult.new(
      account_address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
      target_field: "Supply",
      time_seconds: 10.0,
      attempts: 2,
      stars: 2,
      streak: 999
    )

    assert_not result.valid?
    assert result.errors[:streak].any?
  end

  test "ChallengeResult rejects invalid base58 address" do
    result = ChallengeResult.new(
      account_address: "<script>alert(1)</script>",
      target_field: "Supply",
      time_seconds: 10.0,
      attempts: 2,
      stars: 2,
      streak: 1
    )

    assert_not result.valid?
    assert result.errors[:account_address].any?
  end

  test "ChallengeResult accepts valid data" do
    result = ChallengeResult.new(
      account_address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
      target_field: "Supply",
      time_seconds: 10.5,
      attempts: 2,
      stars: 3,
      streak: 5,
      user_id: 1 # won't save without a real user, but validates other fields
    )

    # Only user validation should fail (no fixture), other fields should be valid
    result.valid?
    assert_empty result.errors[:account_address]
    assert_empty result.errors[:stars]
    assert_empty result.errors[:streak]
    assert_empty result.errors[:attempts]
    assert_empty result.errors[:time_seconds]
  end

  test "ChallengeResult rejects zero attempts" do
    result = ChallengeResult.new(
      account_address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
      target_field: "Supply",
      time_seconds: 10.0,
      attempts: 0,
      stars: 2,
      streak: 1
    )

    assert_not result.valid?
    assert result.errors[:attempts].any?
  end

  # --- Difficulty Tier Tests ---

  test "challenge_pool returns only easy accounts for tier=easy" do
    controller = ChallengesController.new
    pool = controller.send(:challenge_pool, "easy")

    assert pool.any?
    assert pool.all? { |a| a[:tier] == :easy }
    assert_equal 4, pool.length  # 4 Mints
  end

  test "challenge_pool returns only medium accounts for tier=medium" do
    controller = ChallengesController.new
    pool = controller.send(:challenge_pool, "medium")

    assert pool.all? { |a| a[:tier] == :medium }
    assert_equal 4, pool.length  # 4 Token Accounts
  end

  test "challenge_pool returns only hard accounts for tier=hard" do
    controller = ChallengesController.new
    pool = controller.send(:challenge_pool, "hard")

    assert pool.all? { |a| a[:tier] == :hard }
    assert_equal 3, pool.length  # 2 Stake + 1 Vote
  end

  test "challenge_pool returns all accounts when tier is nil" do
    controller = ChallengesController.new
    pool = controller.send(:challenge_pool, nil)

    assert_equal ChallengesController::CHALLENGE_ACCOUNTS.length, pool.length
  end

  test "every CHALLENGE_ACCOUNTS entry has a valid tier" do
    ChallengesController::CHALLENGE_ACCOUNTS.each do |entry|
      assert_includes %i[easy medium hard], entry[:tier], "Invalid tier for #{entry[:address]}"
    end
  end

  test "TIERS constant has expected keys" do
    assert_equal %w[easy medium hard], ChallengesController::TIERS.keys
  end

  test "GET /challenges renders tier selector with all four buttons" do
    get "/challenges"
    assert_response :success
    %w[All Easy Medium Hard].each do |label|
      assert_includes response.body, ">#{label}<"
    end
  end

  test "GET /challenges?tier=easy marks easy button as active" do
    get "/challenges?tier=easy"
    assert_response :success
    # Active buttons have purple border class
    assert_match %r{border-purple-500[^"]*"[^>]*>\s*Easy}, response.body
  end
end
