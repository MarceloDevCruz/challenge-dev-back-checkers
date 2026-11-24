class Game < ApplicationRecord
  enum :status, { waiting_for_player: 0, in_progress: 1, finished: 2 }, default: :waiting_for_player
  enum :current_turn, { player_1: 1, player_2: 2 }, default: :player_1
  enum :winner, { player_1_wins: 1, player_2_wins: 2, draw: 3 }, prefix: true

  validates :player_1_token, :player_2_token, presence: true, uniqueness: true
  validates :status, :current_turn, presence: true
  validates :board_state, presence: true

  def valid_player_2_token?(token)
    ActiveSupport::SecurityUtils.secure_compare(token, player_2_token)
  end

  def joinable?
    waiting_for_player?
  end

  def start!
    update!(status: :in_progress)
  end

  def player_for_token(token)
    return 1 if ActiveSupport::SecurityUtils.secure_compare(player_1_token, token)
    return 2 if ActiveSupport::SecurityUtils.secure_compare(player_2_token, token)
  end

  def turn_for?(player)
    current_turn == "player_#{player}"
  end

  def chain_in_progress?
    capture_chain.present?
  end
end
