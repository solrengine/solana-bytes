class LeaderboardController < ApplicationController
  def index
    @top_streaks = ChallengeResult.includes(:user)
                                   .leaderboard
                                   .limit(50)
    @recent_games = ChallengeResult.includes(:user)
                                    .recent
  end
end
