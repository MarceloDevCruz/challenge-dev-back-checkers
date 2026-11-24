class Piece
  def initialize(player:, type: "man")
    @player = player
    @type = type
  end

  def self.king
    "king"
  end

  def promote
    Piece.new(player: @player, type: "king")
  end
end
