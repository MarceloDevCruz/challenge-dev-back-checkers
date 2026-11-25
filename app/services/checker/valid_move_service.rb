class Checker::ValidMoveService
  class ValidMoveError < StandardError; end

  def self.call(game, from, player)
    new(game, from, player).call
  end

  def initialize(game, from, player)
    @game = game
    @from = from
    @player = player
  end

  # Retorna a origem (já convertida) e as ações possíveis da peça nessa coordenada:
  # { from: { row:, col: }, valid_moves: [ { to: { row:, col: }, capture: true|false }, ... ] }
  def call
    raise ValidMoveError, I18n.t("errors.move.origin_required") if @from.blank?
    raise ValidMoveError, I18n.t("errors.game.not_in_progress") unless @game.in_progress?
    raise ValidMoveError, I18n.t("errors.game.not_your_turn") unless @game.turn_for?(@player)

    from_row, from_col = parse_coordinates(@from)
    board = @game.board_state

    validate_origin!(board, from_row, from_col)
    validate_chain_origin!(from_row, from_col)

    piece = board[from_row][from_col]
    moves = diagonal_destinations(from_row, from_col).filter_map do |to_row, to_col|
      result = ::Checker::GameRulesService.call(piece, board, @player, from_row, from_col, to_row, to_col)
      next unless result.valid?

      { to: { row: to_row, col: to_col }, capture: !result.captured_at.nil? }
    end

    # Durante uma cadeia de capturas, só é permitido continuar capturando
    moves = moves.select { |move| move[:capture] } if @game.chain_in_progress?

    { from: { row: from_row, col: from_col }, valid_moves: moves }
  end

  private

  def validate_origin!(board, row, col)
    raise ValidMoveError, I18n.t("errors.move.off_board") unless ::Checker::Rules::Geometry.on_board?(row, col)

    piece = board[row][col]
    raise ValidMoveError, I18n.t("errors.move.no_piece_at_origin") if piece.nil?
    raise ValidMoveError, I18n.t("errors.move.opponent_piece") unless piece["player"] == @player
  end

  def validate_chain_origin!(row, col)
    return unless @game.chain_in_progress?

    chain = @game.capture_chain

    unless chain["row"] == row && chain["col"] == col
      raise ValidMoveError, I18n.t("errors.move.must_capture_with_same_piece")
    end
  end

  # Todas as casas nas 4 diagonais a partir da origem; as regras decidem quais são válidas
  def diagonal_destinations(row, col)
    Board::DIAGONALS.flat_map do |row_step, col_step|
      (1...Board::SIZE).map { |distance| [ row + row_step * distance, col + col_step * distance ] }.select { |r, c| ::Checker::Rules::Geometry.on_board?(r, c) }
    end
  end

  def parse_coordinates(coord)
    [ coord[:row].to_i, coord[:col].to_i ]
  end
end
