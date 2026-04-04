class StatsController < ApplicationController
  def show
    @stats = Rails.cache.fetch("stats:public", expires_in: 5.minutes) do
      {
        # Visit stats
        total_visits: Ahoy::Visit.count,
        visits_today: Ahoy::Visit.where(started_at: Time.current.all_day).count,
        visits_week: Ahoy::Visit.where(started_at: 1.week.ago..).count,

        # Pageview stats
        total_pageviews: Ahoy::Event.where(name: "pageview").count,
        pageviews_today: Ahoy::Event.where(name: "pageview", time: Time.current.all_day).count,
        pageviews_week: Ahoy::Event.where(name: "pageview", time: 1.week.ago..).count,

        # Top pages
        top_pages: Ahoy::Event.where(name: "pageview")
                              .group("json_extract(properties, '$.page')")
                              .order(Arel.sql("count(*) DESC"))
                              .limit(10)
                              .count,

        # Challenge stats
        total_games: ChallengeResult.count,
        total_players: ChallengeResult.distinct.count(:user_id),
        total_stars: ChallengeResult.sum(:stars),
        highest_streak: ChallengeResult.maximum(:streak) || 0,
        avg_streak: ChallengeResult.average(:streak)&.round(1) || 0,
        games_today: ChallengeResult.where(created_at: Time.current.all_day).count,
        games_week: ChallengeResult.where(created_at: 1.week.ago..).count,

        # Top players
        top_players: ChallengeResult.select("user_id, MAX(streak) as best_streak, COUNT(*) as games, SUM(stars) as total_stars")
                                     .group(:user_id)
                                     .order(Arel.sql("MAX(streak) DESC"))
                                     .limit(5)
                                     .includes(:user),

        # Most targeted fields
        top_fields: ChallengeResult.group(:target_field)
                                    .order(Arel.sql("count(*) DESC"))
                                    .limit(10)
                                    .count,

        # Account usage
        top_accounts: ChallengeResult.group(:account_address)
                                      .order(Arel.sql("count(*) DESC"))
                                      .limit(8)
                                      .count,
      }
    end
  end
end
