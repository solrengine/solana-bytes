class RenameStarsToTotalStars < ActiveRecord::Migration[8.1]
  def change
    rename_column :challenge_results, :stars, :total_stars
  end
end
