class Piece
  def initialize(player:, type: "man")
    @player = player
    @type = type
  end

  def self.king
    "king"
  end
end
