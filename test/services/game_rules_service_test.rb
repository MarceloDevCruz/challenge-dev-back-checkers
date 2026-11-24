require "test_helper"

class GameRulesServiceTest < ActiveSupport::TestCase
  def setup
    @rules = GameRulesService.new
    @board = Board.from_json(@rules.build_grid)
  end

  test "build_grid returns initial board state" do
    grid = @rules.build_grid
    assert_equal 8, grid.size
    assert_equal 8, grid.first.size
  end

  # Player 1 pieces at top (rows 0-2, ranks 8-6): a8, c8, e8, g8, b7, d7, f7, h7, a6, c6, e6, g6
  # Player 2 pieces at bottom (rows 5-7, ranks 3-1): b6, d6, f6, h6, a5, c5, e5, g5, b4, d4, f4, h4
  # Wait: row 0=rank 8, row 1=rank 7, row 2=rank 6, row 3=rank 5, row 4=rank 4, row 5=rank 3, row 6=rank 2, row 7=rank 1

  # Player 1 (dark) at rows 0,1,2 (ranks 8,7,6) - moves DOWN (+row)
  # Player 2 (light) at rows 5,6,7 (ranks 3,2,1) - moves UP (-row)

  test "valid_moves returns empty for opponent piece" do
    # a6 is player 1's piece (row 2, col 0)
    # Check player 2's moves from a6 - should be empty since it's player 1's piece
    moves = @rules.valid_moves(@board, "a6", 2)
    assert_empty moves
  end

  test "valid_moves returns empty for empty square" do
    # a5 is empty (row 3, col 0) - (3+0)=3 odd but row 3 is middle
    moves = @rules.valid_moves(@board, "a5", 1)
    assert_empty moves
  end

  test "valid_moves returns forward moves for player 1 man" do
    # Player 1 at a6 (row 2, col 0) moves down to b5 (row 3, col 1)
    moves = @rules.valid_moves(@board, "a6", 1)
    assert_includes moves.map { |m| m[:to] }, "b5"
  end

  test "valid_moves returns forward moves for player 2 man" do
    # Player 2 at b4 (row 6, col 1) moves up to a3 (row 5, col 0) or c3 (row 5, col 2)
    moves = @rules.valid_moves(@board, "b4", 2)
    assert_includes moves.map { |m| m[:to] }, "a3"
    assert_includes moves.map { |m| m[:to] }, "c3"
  end

  test "valid_moves does not return backward moves for man" do
    board = Board.from_json(@rules.build_grid)
    # Move player 1 piece to middle: from a6 (row 2) to a4 (row 4)
    board.set_piece(4, 0, { "player" => 1, "type" => "man" })
    board.remove_piece(2, 0)

    # Player 1 man at a4 (row 4) can only move down to row 5 (b3), not up to row 3 (b5)
    moves = @rules.valid_moves(board, "a4", 1)
    refute_includes moves.map { |m| m[:to] }, "b5"  # backward
    assert_includes moves.map { |m| m[:to] }, "b3"   # forward
  end

  test "valid_moves returns both directions for king" do
    board = Board.from_json(@rules.build_grid)
    board.set_piece(4, 0, { "player" => 1, "type" => "king" })
    board.remove_piece(2, 0)

    moves = @rules.valid_moves(board, "a4", 1)
    assert_includes moves.map { |m| m[:to] }, "b5"  # backward (up)
    assert_includes moves.map { |m| m[:to] }, "b3"  # forward (down)
  end

  test "valid_moves returns captures when available" do
    board = Board.from_json(@rules.build_grid)
    # Setup: player 1 at a6 (row 2, col 0), player 2 at b5 (row 3, col 1), empty at c4 (row 4, col 2)
    board.set_piece(3, 1, { "player" => 2, "type" => "man" }) # b5
    board.remove_piece(4, 2) # c4 empty

    moves = @rules.valid_moves(board, "a6", 1)
    capture_moves = moves.select { |m| m[:captures].any? }
    assert capture_moves.any?
    assert_equal "c4", capture_moves.first[:to]
    assert_equal 1, capture_moves.first[:captures].size
    assert_equal 3, capture_moves.first[:captures].first[:row]
    assert_equal 1, capture_moves.first[:captures].first[:col]
  end

  test "make_move executes simple move" do
    # Player 1 moves a6 -> b5
    result = @rules.make_move(@board, "a6", "b5", 1)
    assert result[:success]
    assert_equal 1, result[:board][3][1]["player"] # b5 is row 3, col 1
    assert_nil result[:board][2][0] # a6 should be empty
    assert_equal 2, result[:current_turn]
  end

  test "make_move executes capture" do
    board = Board.from_json(@rules.build_grid)
    # Setup capture: player 1 at a6 (row 2, col 0), player 2 at b5 (row 3, col 1), empty at c4 (row 4, col 2)
    board.set_piece(3, 1, { "player" => 2, "type" => "man" })
    board.remove_piece(4, 2)

    result = @rules.make_move(board, "a6", "c4", 1)
    assert result[:success]
    assert_equal 1, result[:captures].size
    assert_equal 3, result[:captures].first[:row] # captured piece at row 3 (b5)
    assert_equal 1, result[:captures].first[:col] # captured piece at col 1 (b5)
    assert_nil result[:board][3][1] # captured piece removed
    assert_equal 1, result[:board][4][2]["player"] # piece at c4
  end

  test "make_move promotes man to king on last row" do
    board = Board.from_json(@rules.build_grid)
    # Put player 1 man on row 6 (one before promotion row 7)
    board.set_piece(6, 0, { "player" => 1, "type" => "man" })
    board.remove_piece(5, 0)

    # Move from a2 (row 6) to a1 (row 7) - promotion
    result = @rules.make_move(board, "a2", "a1", 1)
    assert result[:success]
    assert_equal "king", result[:board][7][0]["type"]
  end

  test "make_move returns error for invalid move" do
    # a6 to c4 is not a valid simple move (it's a capture move, but no piece to capture)
    result = @rules.make_move(@board, "a6", "c4", 1)
    refute result[:success]
    assert_equal "Invalid move", result[:error]
  end

  test "check_winner returns nil for ongoing game" do
    assert_nil @rules.check_winner(@board)
  end

  test "check_winner returns player 2 when player 1 has no pieces" do
    board = Board.from_json(@rules.build_grid)
    # Remove all player 1 pieces
    (0..7).each do |row|
      (0..7).each do |col|
        piece = board.piece_at(row, col)
        board.remove_piece(row, col) if piece && piece["player"] == 1
      end
    end
    assert_equal 2, @rules.check_winner(board)
  end

  test "check_winner returns player 1 when player 2 has no pieces" do
    board = Board.from_json(@rules.build_grid)
    (0..7).each do |row|
      (0..7).each do |col|
        piece = board.piece_at(row, col)
        board.remove_piece(row, col) if piece && piece["player"] == 2
      end
    end
    assert_equal 1, @rules.check_winner(board)
  end

  test "multiple captures returns longest sequence" do
    board = Board.from_json(@rules.build_grid)
    # Setup double capture scenario for player 1
    # Player 1 at a6 (2,0), player 2 at b5 (3,1) and d3 (4,3), empty at c4 (4,2) and e2 (5,4)
    board.set_piece(3, 1, { "player" => 2, "type" => "man" }) # b5
    board.set_piece(4, 3, { "player" => 2, "type" => "man" }) # d4
    board.remove_piece(4, 2) # c4 empty
    board.remove_piece(5, 4) # e3 empty

    moves = @rules.valid_moves(board, "a6", 1)
    capture_moves = moves.select { |m| m[:captures].any? }
    assert capture_moves.any?
    # Should find multi-capture path
    max_captures = capture_moves.max_by { |m| m[:captures].size }
    assert max_captures[:captures].size >= 1
  end
end