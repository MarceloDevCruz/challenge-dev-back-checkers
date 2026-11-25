require "rails_helper"

RSpec.describe Checker::Rules::Preconditions do
  def build_board(pieces = {})
    Array.new(Board::SIZE) do |row|
      Array.new(Board::SIZE) { |col| pieces[[ row, col ]] }
    end
  end

  def piece(player, type = "man")
    { "player" => player, "type" => type }
  end

  def run_preconditions(board:, player:, from:, to:)
    move = Checker::Rules::Move.new(
      piece: board.dig(*from),
      board: board,
      player: player,
      from_row: from[0],
      from_col: from[1],
      to_row: to[0],
      to_col: to[1]
    )
    described_class.call(move)
  end

  describe ".call" do
    it "retorna nil quando todas as pré-condições são atendidas" do
      board = build_board([ 2, 1 ] => piece(1))
      expect(run_preconditions(board: board, player: 1, from: [ 2, 1 ], to: [ 3, 2 ])).to be_nil
    end

    it "retorna erro quando a origem está fora do tabuleiro" do
      board = build_board
      expect(run_preconditions(board: board, player: 1, from: [ 8, 1 ], to: [ 7, 2 ])).to eq("Coordenadas fora do tabuleiro")
    end

    it "retorna erro quando o destino está fora do tabuleiro" do
      board = build_board([ 7, 0 ] => piece(1))
      expect(run_preconditions(board: board, player: 1, from: [ 7, 0 ], to: [ 8, 1 ])).to eq("Coordenadas fora do tabuleiro")
    end

    it "retorna erro quando o movimento não é diagonal" do
      board = build_board([ 2, 1 ] => piece(1))
      expect(run_preconditions(board: board, player: 1, from: [ 2, 1 ], to: [ 3, 1 ])).to eq("O movimento deve ser diagonal")
    end

    it "retorna erro quando não há peça na origem" do
      board = build_board
      expect(run_preconditions(board: board, player: 1, from: [ 2, 1 ], to: [ 3, 2 ])).to eq("Não há peça na posição de origem")
    end

    it "retorna erro quando a peça é do adversário" do
      board = build_board([ 5, 0 ] => piece(2))
      expect(run_preconditions(board: board, player: 1, from: [ 5, 0 ], to: [ 4, 1 ])).to eq("A peça selecionada pertence ao oponente")
    end

    it "retorna erro quando o destino está ocupado" do
      board = build_board([ 2, 1 ] => piece(1), [ 3, 2 ] => piece(2))
      expect(run_preconditions(board: board, player: 1, from: [ 2, 1 ], to: [ 3, 2 ])).to eq("A casa de destino precisa estar vazia")
    end
  end
end
