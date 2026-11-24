class Board
  SIZE = 8.freeze
  PLAYER_1_ROWS = (0..2).freeze
  PLAYER_2_ROWS = (5..7).freeze
  DIAGONALS = [ [ 1, 1 ], [ 1, -1 ], [ -1, 1 ], [ -1, -1 ] ].freeze

  def self.initial_grid
    new.initial_grid
  end

  def initial_grid
    grid = Array.new(SIZE) { Array.new(SIZE, nil) }
    organize_piece_positions(grid)
  end

  def organize_piece_positions(grid)
    place_player_piece(grid, player: 1, rows: PLAYER_1_ROWS)
    place_player_piece(grid, player: 2, rows: PLAYER_2_ROWS)
    grid
  end

  def place_player_piece(grid, player:, rows:)
    rows.each do |row|
      (0...SIZE).each do |col|
        next unless playable_square?(row, col)

        grid[row][col] = Piece.new(player: player, type: "man")
      end
    end
  end

  private

  # Pular quadrados que não são jogaveis
  def playable_square?(row, col)
    (row + col).odd?
  end
end
