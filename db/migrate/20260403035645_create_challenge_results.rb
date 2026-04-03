class CreateChallengeResults < ActiveRecord::Migration[8.1]
  def change
    create_table :challenge_results do |t|
      t.references :user, null: false, foreign_key: true
      t.string :account_address
      t.string :target_field
      t.decimal :time_seconds
      t.integer :attempts
      t.integer :stars
      t.integer :streak

      t.timestamps
    end
  end
end
