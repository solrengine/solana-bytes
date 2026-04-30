class TightenChallengeResultsConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :challenge_results, :streak, false, 0
    change_column_null :challenge_results, :total_stars, false, 0
    change_column_null :challenge_results, :attempts, false, 1
    change_column_null :challenge_results, :time_seconds, false, 0
    change_column_null :challenge_results, :account_address, false
    change_column_null :challenge_results, :target_field, false
  end
end
