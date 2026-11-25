class Checker::Rules::Preconditions
  def self.call(move)
    new(move).call
  end

  def initialize(move)
    @move = move
  end

  def call
    rules = [
      { valid: on_board?, message: :off_board },
      { valid: @move.diagonal?, message: :not_diagonal },
      { valid: !@move.piece.nil?, message: :no_piece_at_origin },
      { valid: owned_by_player?, message: :opponent_piece },
      { valid: ::Checker::Rules::Geometry.empty?(@move.board, @move.to_row, @move.to_col), message: :destination_not_empty }
    ]

    failed_rule = rules.find { |rule| !rule[:valid] }
    I18n.t(failed_rule[:message], scope: "errors.move") if failed_rule
  end

  private

  def on_board?
    ::Checker::Rules::Geometry.on_board?(@move.from_row, @move.from_col) && ::Checker::Rules::Geometry.on_board?(@move.to_row, @move.to_col)
  end

  # Verifica se o peça pertence ao jogador
  def owned_by_player?
    return false if @move.piece.nil?

    @move.piece["player"] == @move.player
  end
end
