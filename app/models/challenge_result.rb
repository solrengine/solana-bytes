class ChallengeResult < ApplicationRecord
  belongs_to :user

  validates :account_address, :target_field, :time_seconds, :attempts, :stars, :streak, presence: true
  validates :account_address, format: { with: /\A[1-9A-HJ-NP-Za-km-z]{32,44}\z/, message: "must be a valid base58 address" }
  validates :stars, inclusion: { in: 0..3 }
  validates :streak, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 200 }
  validates :attempts, numericality: { greater_than: 0, less_than_or_equal_to: 50 }
  validates :time_seconds, numericality: { greater_than_or_equal_to: 0 }

  scope :leaderboard, -> { order(streak: :desc, time_seconds: :asc).limit(50) }
  scope :recent, -> { order(created_at: :desc).limit(20) }
end
