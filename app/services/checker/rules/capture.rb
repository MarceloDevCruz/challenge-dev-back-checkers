class Checker::Rules::Capture
  def initialize(move)
    @move = move
  end

  def valid?
    capture?
  end

  def captured_square
    return nil unless capture?

    @move.path_squares.find { |row, col| !::Checker::Rules::Geometry.empty?(@move.board, row, col) }
  end

  private

  def capture?
    return false unless ::Checker::Rules::Geometry.on_board?(@move.to_row, @move.to_col)
    return false unless @move.diagonal?

    if @move.king?
      occupied = @move.path_squares.reject { |row, col| ::Checker::Rules::Geometry.empty?(@move.board, row, col) }
      occupied.size == 1 && opponent?(*occupied.first)
    else
      return false unless @move.row_diff.abs == 2

      row, col = @move.path_squares.first
      !::Checker::Rules::Geometry.empty?(@move.board, row, col) && opponent?(row, col)
    end
  end

  def opponent?(row, col)
    ::Checker::Rules::Geometry.opponent?(@move.board, row, col, @move.player)
  end
end
