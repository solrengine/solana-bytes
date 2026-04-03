class User < ApplicationRecord
  include Solrengine::Auth::Concerns::Authenticatable

  has_many :challenge_results, dependent: :destroy

  def short_address
    "#{wallet_address[0..3]}...#{wallet_address[-4..]}"
  end

  def best_streak
    challenge_results.maximum(:streak) || 0
  end

  def total_challenges
    challenge_results.count
  end
end
