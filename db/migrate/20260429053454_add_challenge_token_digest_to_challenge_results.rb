class AddChallengeTokenDigestToChallengeResults < ActiveRecord::Migration[8.1]
  def change
    add_column :challenge_results, :challenge_token_digest, :string
    add_index :challenge_results, :challenge_token_digest, unique: true
  end
end
