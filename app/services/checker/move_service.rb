class Checker::MoveService
  class MoveError < StandardError; end

  LAST_ROW = { 1 => 7, 2 => 0 }.freeze

  def self.call(game, from, to, player)
    new(game, from, to, player).call
  end

  def initialize(game, from, to, player)
    @game = game
    @from = from
    @to = to
    @player = player
  end

  def call
    raise MoveError, I18n.t("errors.move.coordinates_required") if @from.blank? || @to.blank?
    raise MoveError, I18n.t("errors.game.not_in_progress") unless @game.in_progress?
    raise MoveError, I18n.t("errors.game.not_your_turn") unless @game.turn_for?(@player)

    from_row, from_col = parse_coordinates(@from)
    to_row, to_col = parse_coordinates(@to)

    board = @game.board_state

    # Checa se o a coordenada não vem de uma captura de peão
    validate_chain_origin!(from_row, from_col)
    piece = board[from_row][from_col]

    # Checar a movimentação conforme as regras do jogo
    result = ::Checker::GameRulesService.call(piece, board, @player, from_row, from_col, to_row, to_col)
    raise MoveError, result.error unless result.valid?

    # Durante uma cadeia de capturas, só é permitido continuar capturando
    raise MoveError, I18n.t("errors.move.must_continue_capture") if @game.chain_in_progress? && result.captured_at.nil?

    updated_board = apply_move(board, from_row, from_col, to_row, to_col, result.captured_at)

    # Fim de partida: o oponente ficou sem peças
    winner = ::Checker::GameRulesService.check_end(updated_board, @player)
    if winner
      @game.update!(
        board_state: updated_board,
        capture_chain: nil,
        status: :finished,
        winner: winner
      )
    elsif result.captured_at && more_captures?(updated_board, updated_board[to_row][to_col], to_row, to_col)
      # Ainda há captura disponível: mantém o turno e registra a peça da cadeia
      @game.update!(
        board_state: updated_board,
        capture_chain: { "row" => to_row, "col" => to_col }
      )
    else
      # Fim da jogada: limpa a cadeia e passa o turno
      @game.update!(
        board_state: updated_board,
        capture_chain: nil,
        current_turn: next_turn(@player)
      )
    end
  end

  private

  # Aplicação do movimento
  def apply_move(board, from_row, from_col, to_row, to_col, captured_at)
    piece = board[from_row][from_col].dup
    board[from_row][from_col] = nil

    # Remove a peça capturada
    if captured_at
      cap_row, cap_col = captured_at
      board[cap_row][cap_col] = nil
    end

    # Promove a Dama ao chegar na última linha
    piece["type"] = Piece.king if promote?(piece, to_row)
    board[to_row][to_col] = piece
    board
  end

  def promote?(piece, to_row)
    return false if piece.nil?

    piece["type"] != Piece.king && to_row == LAST_ROW[piece["player"]]
  end

  def validate_chain_origin!(from_row, from_col)
    return unless @game.chain_in_progress?

    chain = @game.capture_chain

    unless chain["row"] == from_row && chain["col"] == from_col
      raise MoveError, I18n.t("errors.move.must_capture_with_same_piece")
    end
  end

  def more_captures?(board, piece, row, col)
    ::Checker::GameRulesService.can_continue_capture?(piece, board, @player, row, col)
  end

  def parse_coordinates(coord)
    [ coord[:row].to_i, coord[:col].to_i ]
  end

  def next_turn(player)
    player == 1 ? :player_2 : :player_1
  end
end
