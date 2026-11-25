require "rails_helper"

RSpec.describe Checker::Rules::Move do
  let(:board_size) { 8 }

  def build_board(pieces = {})
    Array.new(board_size) do |row|
      Array.new(board_size) do |col|
        pieces[[ row, col ]]
      end
    end
  end

  def piece(player, type = "man")
    { "player" => player, "type" => type }
  end

  def king_piece(player)
    { "player" => player, "type" => "king" }
  end

  describe "#row_diff" do
    it "retorna positivo ao mover para baixo" do
      move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)
      expect(move.row_diff).to eq(2)
    end

    it "retorna negativo ao mover para cima" do
      move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 5, from_col: 1, to_row: 3, to_col: 3)
      expect(move.row_diff).to eq(-2)
    end

    it "retorna zero quando não há movimento vertical" do
      move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 2, to_col: 3)
      expect(move.row_diff).to eq(0)
    end
  end

  describe "#col_diff" do
    it "retorna positivo ao mover para a direita" do
      move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)
      expect(move.col_diff).to eq(2)
    end

    it "retorna negativo ao mover para a esquerda" do
      move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 4, to_row: 4, to_col: 2)
      expect(move.col_diff).to eq(-2)
    end

    it "retorna zero quando não há movimento horizontal" do
      move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 1)
      expect(move.col_diff).to eq(0)
    end
  end

  describe "#diagonal?" do
    context "quando o movimento é diagonal" do
      it "retorna true para baixo e à direita" do
        move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)
        expect(move.diagonal?).to be true
      end

      it "retorna true para baixo e à esquerda" do
        move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 3, to_row: 3, to_col: 2)
        expect(move.diagonal?).to be true
      end

      it "retorna true para cima e à direita" do
        move = described_class.new(piece: piece(2), board: build_board, player: 2, from_row: 5, from_col: 1, to_row: 4, to_col: 2)
        expect(move.diagonal?).to be true
      end

      it "retorna true para cima e à esquerda" do
        move = described_class.new(piece: piece(2), board: build_board, player: 2, from_row: 5, from_col: 3, to_row: 4, to_col: 2)
        expect(move.diagonal?).to be true
      end

      it "retorna true para diagonal de várias casas" do
        move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)
        expect(move.diagonal?).to be true
      end
    end

    context "quando o movimento não é diagonal" do
      it "retorna false para horizontal" do
        move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 2, to_col: 3)
        expect(move.diagonal?).to be false
      end

      it "retorna false para vertical" do
        move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 1)
        expect(move.diagonal?).to be false
      end

      it "retorna false quando não há movimento" do
        move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 2, to_col: 1)
        expect(move.diagonal?).to be false
      end
    end
  end

  describe "#path_squares" do
    it "retorna array vazio para uma casa" do
      move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)
      expect(move.path_squares).to eq([])
    end

    it "retorna as casas intermediárias para várias casas" do
      move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)
      expect(move.path_squares).to eq([ [ 1, 1 ], [ 2, 2 ] ])
    end

    it "retorna as casas intermediárias para cima e à esquerda" do
      move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 5, from_col: 5, to_row: 2, to_col: 2)
      expect(move.path_squares).to eq([ [ 4, 4 ], [ 3, 3 ] ])
    end
  end

  describe "#king?" do
    context "quando a peça é dama" do
      it "retorna true" do
        move = described_class.new(piece: king_piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)
        expect(move.king?).to be true
      end
    end

    context "quando a peça é peão" do
      it "retorna false" do
        move = described_class.new(piece: piece(1), board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)
        expect(move.king?).to be false
      end
    end

    context "quando não há peça (nil)" do
      it "retorna false" do
        move = described_class.new(piece: nil, board: build_board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)
        expect(move.king?).to be false
      end
    end
  end
end
