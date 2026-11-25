class Checker::Rules::ChainCapture
  def initialize(move)
    @move = move
  end

  def valid?
    Board::DIAGONALS.any? do |row_step, col_step|
      (2...Board::SIZE).any? do |distance|
        next false if !@move.king? && distance != 2

        new_row = @move.to_row + row_step * distance
        new_col = @move.to_col + col_step * distance
        next false unless ::Checker::Rules::Geometry.on_board?(new_row, new_col)

        next_move = ::Checker::Rules::Move.new(
          **@move.to_h,
          from_row: @move.to_row,
          from_col: @move.to_col,
          to_row: new_row,
          to_col: new_col
        )

        ::Checker::Rules::Capture.new(next_move).valid? && ::Checker::Rules::Geometry.empty?(@move.board, new_row, new_col)
      end
    end
  end
end
