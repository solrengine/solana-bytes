class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Leaderboard scope: order(streak: :desc, time_seconds: :asc)
    add_index :challenge_results, [ :streak, :time_seconds ], name: "idx_challenge_results_leaderboard"

    # Recent scope: order(created_at: :desc)
    add_index :challenge_results, :created_at, name: "idx_challenge_results_recent"

    # Stats page group queries
    add_index :challenge_results, :target_field, name: "idx_challenge_results_target_field"
    add_index :challenge_results, :account_address, name: "idx_challenge_results_account_address"

    # Country stats
    add_index :ahoy_visits, :country, name: "idx_ahoy_visits_country"
  end
end
