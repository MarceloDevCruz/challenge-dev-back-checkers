require "test_helper"

class PieceTest < ActiveSupport::TestCase
  test "creates a man piece for player 1" do
    piece = Piece.new(player: 1, type: "man")
    assert_equal 1, piece.player
    assert_equal "man", piece.type
    assert piece.man?
    refute piece.king?
  end

  test "creates a king piece for player 2" do
    piece = Piece.new(player: 2, type: "king")
    assert_equal 2, piece.player
    assert_equal "king", piece.type
    assert piece.king?
    refute piece.man?
  end

  test "raises error for invalid player" do
    assert_raises(ArgumentError) { Piece.new(player: 3, type: "man") }
  end

  test "raises error for invalid type" do
    assert_raises(ArgumentError) { Piece.new(player: 1, type: "queen") }
  end

  test "promote creates a king piece" do
    man = Piece.new(player: 1, type: "man")
    king = man.promote
    assert king.king?
    assert_equal 1, king.player
  end

  test "opponent returns other player" do
    assert_equal 2, Piece.new(player: 1).opponent
    assert_equal 1, Piece.new(player: 2).opponent
  end

  test "forward_direction for player 1 is +1" do
    assert_equal 1, Piece.new(player: 1).forward_direction
  end

  test "forward_direction for player 2 is -1" do
    assert_equal -1, Piece.new(player: 2).forward_direction
  end

  test "backward_direction for player 1 is -1" do
    assert_equal -1, Piece.new(player: 1).backward_direction
  end

  test "can_move_backward? false for man" do
    refute Piece.new(player: 1, type: "man").can_move_backward?
  end

  test "can_move_backward? true for king" do
    assert Piece.new(player: 1, type: "king").can_move_backward?
  end

  test "to_h returns hash representation" do
    piece = Piece.new(player: 1, type: "man")
    assert_equal({ "player" => 1, "type" => "man" }, piece.to_h)
  end

  test "from_hash creates piece from hash" do
    piece = Piece.from_hash({ "player" => 2, "type" => "king" })
    assert_equal 2, piece.player
    assert_equal "king", piece.type
  end

  test "from_hash returns nil for nil" do
    assert_nil Piece.from_hash(nil)
  end

  test "equality works correctly" do
    piece1 = Piece.new(player: 1, type: "man")
    piece2 = Piece.new(player: 1, type: "man")
    piece3 = Piece.new(player: 2, type: "man")

    assert_equal piece1, piece2
    refute_equal piece1, piece3
  end
end