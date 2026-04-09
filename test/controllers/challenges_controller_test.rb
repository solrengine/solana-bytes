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
end
