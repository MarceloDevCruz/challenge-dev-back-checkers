class Checker::GameRulesService
  Result = Struct.new(:valid?, :error, :captured_at, keyword_init: true)

  def self.call(piece, board, player, from_row, from_col, to_row, to_col)
    new(piece, board, player, from_row, from_col, to_row, to_col).call
  end

  def initialize(piece, board, player, from_row, from_col, to_row, to_col)
    @piece = piece
    @board = board
    @player = player
    @from_row = from_row
    @from_col = from_col
    @to_row = to_row
    @to_col = to_col
    @type = piece&.dig("type")
    @row_diff = diff(@from_row, @to_row)
    @col_diff = diff(@from_col, @to_col)
  end

  def call
    rules = [
      { valid: on_board?(@from_row, @from_col) && on_board?(@to_row, @to_col), message: "Coordenadas fora do tabuleiro" },
      { valid: diagonal_movement?, message: "O movimento deve ser diagonal" },
      { valid: !@piece.nil?, message: "Não há peça na posição de origem"},
      { valid: owned_by_player?, message: "A peça selecionada pertence ao oponente"},
      { valid: destination_empty?, message: "A casa de destino precisa estar vazia" },
      { valid: simple_move? || capture?, message: "Movimento inválido para esta peça" }
    ]

    error = rules.find { |rule| !rule[:valid] }

    if error
      return Result.new(valid?: false, error: error[:message], captured_at: nil)
    end

    Result.new(valid?: true, error: nil, captured_at: captured_square)
  end

  def self.can_continue_capture?(piece, board, player, row, col)
    new(piece, board, player, row, col, row, col).can_continue_capture?
  end

  # Verifica se pode continuar capturando outra vez a partir da casa de destino
  def can_continue_capture?
    Board::DIAGONALS.any? do |row_step, col_step|
      (2...Board::SIZE).any? do |distance|
        next false if !king? && distance != 2
        new_row = @to_row + row_step * distance
        new_col = @to_col + col_step * distance
        next false unless on_board?(new_row, new_col)
        self.class.new(@piece, @board, @player, @to_row, @to_col, new_row, new_col)
        .then { |rules| rules.capture? && rules.destination_empty? }
      end
    end
  end

  # Verifica a captura da peça, pulando + de 1 casa diagonal
  def capture?
    return false unless on_board?(@to_row, @to_col)
    return false unless diagonal_movement?

    if king?
      occupied = path_squares.reject { |row, col| empty?(row, col) }
      occupied.size == 1 && opponent?(*occupied.first)
    else
      return false unless @row_diff.abs == 2
      row, col = path_squares.first
      !empty?(row, col) && opponent?(row, col)
    end
  end

  # Verifica se o caminho está livre
  def destination_empty?
    empty?(@to_row, @to_col)
  end

  private

  def king?
    @type == Piece.king
  end

  # fazer a diferença entre cordenada de onde o peão vai ir e de onde ele saiu
  def diff(from, to)
    to - from
  end

  # Verifica se o movimento é diagonal
  def diagonal_movement?
    @row_diff != 0 && @row_diff.abs == @col_diff.abs
  end

  # Verifica se o peça pertence ao jogador
  def owned_by_player?
    return false if @piece.nil?

    @piece["player"] == @player
  end

  # Verifica se os jogadores estão seguindo o sentido de ataque, no caso apenas peões
  def forward_for_player?
    return true if king?

    case @player
    when 1 then @row_diff.positive?
    when 2 then @row_diff.negative?
    end
  end

  # Verifica se está pulando casa de 1 em 1
  # Peão: exatamente 1 casa. Dama: qualquer distância com o caminho livre.
  def single_step?
    return @row_diff.abs == 1 unless king?
    path_squares.all? { |row, col| empty?(row, col) }
  end

  # Movimento simples = 1 casa para frente (peão) ou caminho livre (dama)
  def simple_move?
    single_step? && forward_for_player? && destination_empty?
  end

  # Casas entre origem e destino (sem incluir origem e destino)
  def path_squares
    # Tamanho do salto que deu
    steps = @row_diff.abs
    # Verificação se continuo na mesma linha, se foi para cima ou para baixo do tabuleiro
    row_step = @row_diff <=> 0
    col_step = @col_diff <=> 0

    # exclusão do ultimo valor final
    (1...steps).map do |i|
      [ @from_row + row_step * i, @from_col + col_step * i ]
    end
  end

  # Verifica se uma casa está vazia
  def empty?(row, col)
    on_board?(row, col) && @board[row][col].nil?
  end

  # Verificação se a determinada coordenada está dentro do tabuleiro
  def on_board?(row, col)
    row.between?(0, Board::SIZE - 1) && col.between?(0, Board::SIZE - 1)
  end

  # Verifica se é um peão do oponente
  def opponent?(row, col)
    piece = @board[row][col]
    !piece.nil? && piece["player"] != @player
  end

  def captured_square
    return nil unless capture?
    path_squares.find { |row, col| !empty?(row, col) }
  end
end
