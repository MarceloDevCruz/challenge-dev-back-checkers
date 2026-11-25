module Checker
  module Rules
    Move = Struct.new(:piece, :board, :player, :from_row, :from_col, :to_row, :to_col, keyword_init: true) do
      def row_diff
        ::Checker::Rules::Geometry.diff(from_row, to_row)
      end

      def col_diff
        ::Checker::Rules::Geometry.diff(from_col, to_col)
      end

      def diagonal?
        ::Checker::Rules::Geometry.diagonal_movement?(from_row, from_col, to_row, to_col)
      end

      def path_squares
        ::Checker::Rules::Geometry.path_squares(from_row, from_col, to_row, to_col)
      end

      def king?
        piece&.dig("type") == Piece.king
      end
    end
  end
end
