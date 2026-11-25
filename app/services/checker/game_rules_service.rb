class Checker::GameRulesService
  Result = Struct.new(:valid?, :error, :captured_at, keyword_init: true)

  def self.call(piece, board, player, from_row, from_col, to_row, to_col)
    new(piece, board, player, from_row, from_col, to_row, to_col).call
  end

  def self.can_continue_capture?(piece, board, player, row, col)
    new(piece, board, player, row, col, row, col).can_continue_capture?
  end

  def self.check_end(board, current_player)
    Checker::Rules::End.call(board, current_player)
  end

  def initialize(piece, board, player, from_row, from_col, to_row, to_col)
    @move = Checker::Rules::Move.new(
      piece: piece,
      board: board,
      player: player,
      from_row: from_row,
      from_col: from_col,
      to_row: to_row,
      to_col: to_col
    )
  end

  def call
    error = Checker::Rules::Preconditions.call(@move)
    return Result.new(valid?: false, error: error, captured_at: nil) if error

    movement = Checker::Rules::Movement.new(@move)
    capture = Checker::Rules::Capture.new(@move)

    unless movement.valid? || capture.valid?
      return Result.new(valid?: false, error: "Movimento inválido para esta peça", captured_at: nil)
    end

    Result.new(valid?: true, error: nil, captured_at: capture.captured_square)
  end

  def can_continue_capture?
    Checker::Rules::ChainCapture.new(@move).valid?
  end
end
