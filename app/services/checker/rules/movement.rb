class Checker::Rules::Movement
  def initialize(move)
    @move = move
  end

  def valid?
    @move.diagonal? && single_step? && forward_for_player? && ::Checker::Rules::Geometry.empty?(@move.board, @move.to_row, @move.to_col)
  end

  private

  # Verifica se está pulando casa de 1 em 1
  # Peão: exatamente 1 casa. Dama: qualquer distância com o caminho livre.
  def single_step?
    return @move.row_diff.abs == 1 unless @move.king?

    @move.path_squares.all? { |row, col| ::Checker::Rules::Geometry.empty?(@move.board, row, col) }
  end

  # Verifica se os jogadores estão seguindo o sentido de ataque, no caso apenas peões
  def forward_for_player?
    return true if @move.king?

    case @move.player
    when 1 then @move.row_diff.positive?
    when 2 then @move.row_diff.negative?
    end
  end
end
