class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.string :player_1_token, null: false
      t.string :player_2_token, null: false
      t.integer :status, default: 0, null: false
      t.integer :current_turn, default: 1, null: false
      t.integer :winner
      t.json :board_state, null: false
      t.timestamps
    end

    add_index :games, :player_1_token, unique: true
    add_index :games, :player_2_token, unique: true
  end
end
