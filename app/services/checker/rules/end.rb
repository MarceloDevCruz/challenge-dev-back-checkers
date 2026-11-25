class Checker::Rules::End
  # Verifica se a partida terminou após a jogada do current_player.
  # Retorna o valor do enum Game#winner (:player_1_wins / :player_2_wins) ou nil se a partida continua.
  WINNER_FOR = { 1 => :player_1_wins, 2 => :player_2_wins }.freeze

  def self.call(board, current_player)
    new(board, current_player).call
  end

  def initialize(board, current_player)
    @board = board
    @current_player = current_player
  end

  def call
    return WINNER_FOR[@current_player] if pieces_count(opponent).zero?
    return WINNER_FOR[opponent] if pieces_count(@current_player).zero?

    nil
  end

  private

  def opponent
    @current_player == 1 ? 2 : 1
  end

  def pieces_count(player)
    @board.flatten.count { |piece| piece && piece["player"] == player }
  end
end
