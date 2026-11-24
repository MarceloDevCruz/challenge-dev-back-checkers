class Checker::ValidMoveService
  def self.call(board, player, from, to)
    new(board, player, from, to).call
  end

  def initialize(board, player, from, to)
    @board = board
    @player = player
    @from = from
    @to = to
  end

  def call
    from_row, from_col = parse_coordenates_to_integer(from)
    to_row, to_col = parse_coordenates_to_integer(to)

    piece = @board[from_row][from_col]
    rules = ::Check::GameRulesService.new(piece, @board, @player, from_row, from_col, to_row, to_col)
  end

  private

  def parse_coordenates_to_integer(coord)
    [coord[:row].to_i, coord[:col].to_i]
  end
end
