class ChallengeResult < ApplicationRecord
  belongs_to :user

  validates :account_address, :target_field, :time_seconds, :attempts, :stars, :streak, presence: true

  scope :leaderboard, -> { order(streak: :desc, time_seconds: :asc).limit(50) }
  scope :recent, -> { order(created_at: :desc).limit(20) }
end
