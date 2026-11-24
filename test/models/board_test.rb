require "test_helper"

class BoardTest < ActiveSupport::TestCase
  test "initial grid has correct dimensions" do
    board = Board.new
    grid = board.initial_grid

    assert_equal 8, grid.size
    assert_equal 8, grid.first.size
  end

  test "initial grid has 12 pieces for player 1" do
    board = Board.new
    grid = board.initial_grid

    player_1_count = grid.flatten.compact.count { |p| p["player"] == 1 }
    assert_equal 12, player_1_count
  end

  test "initial grid has 12 pieces for player 2" do
    board = Board.new
    grid = board.initial_grid

    player_2_count = grid.flatten.compact.count { |p| p["player"] == 2 }
    assert_equal 12, player_2_count
  end

  test "player 1 pieces start in rows 0-2" do
    board = Board.new
    grid = board.initial_grid

    (0..2).each do |row|
      (0...8).each do |col|
        next unless board.playable_square?(row, col)
        piece = grid[row][col]
        assert piece, "Expected piece at #{row},#{col}"
        assert_equal 1, piece["player"]
        assert_equal "man", piece["type"]
      end
    end
  end

  test "player 2 pieces start in rows 5-7" do
    board = Board.new
    grid = board.initial_grid

    (5..7).each do |row|
      (0...8).each do |col|
        next unless board.playable_square?(row, col)
        piece = grid[row][col]
        assert piece, "Expected piece at #{row},#{col}"
        assert_equal 2, piece["player"]
        assert_equal "man", piece["type"]
      end
    end
  end

  test "middle rows are empty" do
    board = Board.new
    grid = board.initial_grid

    [3, 4].each do |row|
      (0...8).each do |col|
        assert_nil grid[row][col], "Expected empty at #{row},#{col}"
      end
    end
  end

  test "playable_square? returns correct values" do
    board = Board.new
    assert board.playable_square?(0, 1)
    assert board.playable_square?(0, 3)
    assert board.playable_square?(0, 5)
    assert board.playable_square?(0, 7)
    refute board.playable_square?(0, 0)
    refute board.playable_square?(0, 2)
  end

  test "piece_at returns piece at position" do
    board = Board.new(Board.initial_grid)
    piece = board.piece_at(0, 1)
    assert piece
    assert_equal 1, piece["player"]
  end

  test "piece_at returns nil for out of bounds" do
    board = Board.new(Board.initial_grid)
    assert_nil board.piece_at(-1, 0)
    assert_nil board.piece_at(8, 0)
    assert_nil board.piece_at(0, 8)
  end

  test "deep_dup creates independent copy" do
    board = Board.new(Board.initial_grid)
    dup_board = board.deep_dup

    dup_board.set_piece(0, 1, nil)

    assert board.piece_at(0, 1)
    assert_nil dup_board.piece_at(0, 1)
  end

  test "to_json returns grid" do
    board = Board.new(Board.initial_grid)
    json = board.to_json
    assert_equal 8, json.size
  end

  test "player_pieces returns only pieces for that player" do
    board = Board.new(Board.initial_grid)
    player_1_pieces = board.player_pieces(1)
    player_2_pieces = board.player_pieces(2)

    assert_equal 12, player_1_pieces.size
    assert_equal 12, player_2_pieces.size
    assert player_1_pieces.all? { |p| p[:piece]["player"] == 1 }
    assert player_2_pieces.all? { |p| p[:piece]["player"] == 2 }
  end
end