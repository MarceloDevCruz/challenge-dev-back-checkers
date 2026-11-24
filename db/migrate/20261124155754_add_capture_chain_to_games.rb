class AddCaptureChainToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :capture_chain, :jsonb
  end
end
