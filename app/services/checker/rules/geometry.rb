module Checker
  module Rules
    module Geometry
      module_function

      # Verifica se a coordenada está dentro do tabuleiro
      def on_board?(row, col)
        row.between?(0, Board::SIZE - 1) && col.between?(0, Board::SIZE - 1)
      end

      # fazer a diferença entre cordenada de onde o peão vai ir e de onde ele saiu
      def diff(from, to)
        to - from
      end

      # Verifica se o movimento é diagonal
      def diagonal_movement?(from_row, from_col, to_row, to_col)
        row_diff = diff(from_row, to_row)
        col_diff = diff(from_col, to_col)
        row_diff != 0 && row_diff.abs == col_diff.abs
      end

      # Casas entre origem e destino (sem incluir origem e destino)
      def path_squares(from_row, from_col, to_row, to_col)
        row_diff = diff(from_row, to_row)
        col_diff = diff(from_col, to_col)

        # Tamanho do salto que deu
        steps = row_diff.abs
        # Verificação se continuo na mesma linha, se foi para cima ou para baixo do tabuleiro
        row_step = row_diff <=> 0
        col_step = col_diff <=> 0

        # exclusão do ultimo valor final
        (1...steps).map do |i|
          [from_row + row_step * i, from_col + col_step * i]
        end
      end

      # Verifica se uma casa está vazia
      def empty?(board, row, col)
        on_board?(row, col) && board[row][col].nil?
      end

      # Verifica se é um peão do oponente
      def opponent?(board, row, col, player)
        piece = board[row][col]
        !piece.nil? && piece["player"] != player
      end
    end
  end
end
