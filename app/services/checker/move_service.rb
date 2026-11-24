class Checker::MoveService
  class MoveError < StandardError; end

  LAST_ROW = { 1 => 7, 2 => 0 }.freeze

  def self.call(game, from, to, player, token)
    new(game, from, to, player, token).call
  end

  def initialize(game, from, to, player, token)
    @game = game
    @from = parse_coordinates(from)
    @to = parse_coordinates(to)
    @player = player
    @token = token
  end

  def call
    raise MoveError, "A partida não está em andamento" unless @game.in_progress?
    raise MoveError, "Não é o seu turno" unless @game.turn_for?(@player)

    from_row, from_col = @from
    to_row, to_col = @to

    board = @game.board_state

    # Checa se o a coordenada não vem de uma captura de peão
    validate_chain_origin!(from_row, from_col)
    piece = board[from_row][from_col]

    # Checar a movimentação conforme as regras do jogo
    result = ::Checker::GameRulesService.call(piece, board, @player, from_row, from_col, to_row, to_col)
    raise MoveError, result.error unless result.valid?

    # Durante uma cadeia de capturas, só é permitido continuar capturando
    raise MoveError, "Você deve continuar capturando" if @game.chain_in_progress? && result.captured_at.nil?
    
    new_board = apply_move(board, from_row, from_col, to_row, to_col, result.captured_at)
    if result.captured_at && more_captures?(new_board, new_board[to_row][to_col], to_row, to_col)
      # Ainda há captura disponível: mantém o turno e registra a peça da cadeia
      @game.update!(
        board_state:   new_board,
        capture_chain: { "row" => to_row, "col" => to_col }
      )
    else
      # Fim da jogada: limpa a cadeia e passa o turno
      @game.update!(
        board_state:   new_board,
        capture_chain: nil,
        current_turn:  next_turn(@player)
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
      raise MoveError, "Você deve continuar a captura com a mesma peça"
    end
  end

  def more_captures?(board, piece, row, col)
    ::Checker::GameRulesService.can_continue_capture?(piece, board, @player, row, col)
  end

  def parse_coordinates(coord)
    [coord[:row].to_i, coord[:col].to_i]
  end

  def next_turn(player)
    player == 1 ? :player_2 : :player_1
  end

  def game_not_in_progress(status)
    status.to_s != "in_progress"
  end

  def not_player_turn(current_turn, player)
    current_turn.to_s != "player_#{player}"
  end
end
