class Checker::Rules::Preconditions
  def self.call(move)
    new(move).call
  end

  def initialize(move)
    @move = move
  end

  def call
    rules = [
      { valid: on_board?, message: "Coordenadas fora do tabuleiro" },
      { valid: @move.diagonal?, message: "O movimento deve ser diagonal" },
      { valid: !@move.piece.nil?, message: "Não há peça na posição de origem" },
      { valid: owned_by_player?, message: "A peça selecionada pertence ao oponente" },
      { valid: ::Checker::Rules::Geometry.empty?(@move.board, @move.to_row, @move.to_col), message: "A casa de destino precisa estar vazia" }
    ]

    rules.find { |rule| !rule[:valid] }&.dig(:message)
  end

  private

  def on_board?
    ::Checker::Rules::Geometry.on_board?(@move.from_row, @move.from_col) && ::Checker::Rules::Geometry.on_board?(@move.to_row, @move.to_col)
  end

  # Verifica se o peça pertence ao jogador
  def owned_by_player?
    return false if @move.piece.nil?

    @move.piece["player"] == @move.player
  end
end
