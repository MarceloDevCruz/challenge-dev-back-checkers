require "rails_helper"

RSpec.describe Checker::Rules::Geometry do
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

  describe ".on_board?" do
    context "quando as coordenadas estão dentro do tabuleiro" do
      it "retorna true para (0, 0)" do
        expect(described_class.on_board?(0, 0)).to be true
      end

      it "retorna true para (7, 7)" do
        expect(described_class.on_board?(7, 7)).to be true
      end

      it "retorna true para (3, 4)" do
        expect(described_class.on_board?(3, 4)).to be true
      end
    end

    context "quando as coordenadas estão fora do tabuleiro" do
      it "retorna false para linha negativa" do
        expect(described_class.on_board?(-1, 0)).to be false
      end

      it "retorna false para coluna negativa" do
        expect(described_class.on_board?(0, -1)).to be false
      end

      it "retorna false para linha >= tamanho" do
        expect(described_class.on_board?(8, 0)).to be false
      end

      it "retorna false para coluna >= tamanho" do
        expect(described_class.on_board?(0, 8)).to be false
      end
    end
  end

  describe ".diff" do
    it "retorna diferença positiva quando destino > origem" do
      expect(described_class.diff(2, 5)).to eq(3)
    end

    it "retorna diferença negativa quando destino < origem" do
      expect(described_class.diff(5, 2)).to eq(-3)
    end

    it "retorna zero quando são iguais" do
      expect(described_class.diff(3, 3)).to eq(0)
    end
  end

  describe ".diagonal_movement?" do
    context "quando o movimento é diagonal" do
      it "retorna true para uma casa para baixo e à direita" do
        expect(described_class.diagonal_movement?(2, 1, 3, 2)).to be true
      end

      it "retorna true para uma casa para baixo e à esquerda" do
        expect(described_class.diagonal_movement?(2, 2, 3, 1)).to be true
      end

      it "retorna true para uma casa para cima e à direita" do
        expect(described_class.diagonal_movement?(5, 1, 4, 2)).to be true
      end

      it "retorna true para uma casa para cima e à esquerda" do
        expect(described_class.diagonal_movement?(5, 2, 4, 1)).to be true
      end

      it "retorna true para diagonal de várias casas" do
        expect(described_class.diagonal_movement?(0, 0, 3, 3)).to be true
        expect(described_class.diagonal_movement?(0, 3, 3, 0)).to be true
      end
    end

    context "quando o movimento não é diagonal" do
      it "retorna false para movimento horizontal" do
        expect(described_class.diagonal_movement?(2, 1, 2, 3)).to be false
      end

      it "retorna false para movimento vertical" do
        expect(described_class.diagonal_movement?(2, 1, 4, 1)).to be false
      end

      it "retorna false quando não há movimento" do
        expect(described_class.diagonal_movement?(2, 1, 2, 1)).to be false
      end

      it "retorna false para movimento em L" do
        expect(described_class.diagonal_movement?(2, 1, 4, 2)).to be false
      end
    end
  end

  describe ".path_squares" do
    it "retorna array vazio para uma casa" do
      expect(described_class.path_squares(2, 1, 3, 2)).to eq([])
    end

    it "retorna as casas intermediárias para diagonal de várias casas" do
      expect(described_class.path_squares(0, 0, 3, 3)).to eq([ [ 1, 1 ], [ 2, 2 ] ])
    end

    it "retorna as casas intermediárias para diagonal para cima e à esquerda" do
      expect(described_class.path_squares(5, 5, 2, 2)).to eq([ [ 4, 4 ], [ 3, 3 ] ])
    end

    it "retorna as casas intermediárias para diagonal para baixo e à esquerda" do
      expect(described_class.path_squares(2, 5, 5, 2)).to eq([ [ 3, 4 ], [ 4, 3 ] ])
    end

    it "retorna as casas intermediárias para diagonal para cima e à direita" do
      expect(described_class.path_squares(5, 2, 2, 5)).to eq([ [ 4, 3 ], [ 3, 4 ] ])
    end
  end

  describe ".empty?" do
    let(:board) { build_board }

    context "quando a casa está no tabuleiro e vazia (nil)" do
      it "retorna true" do
        expect(described_class.empty?(board, 0, 0)).to be true
        expect(described_class.empty?(board, 3, 4)).to be true
      end
    end

    context "quando a casa tem uma peça" do
      it "retorna false" do
        board_with_piece = build_board([ 2, 1 ] => piece(1))
        expect(described_class.empty?(board_with_piece, 2, 1)).to be false
      end
    end

    context "quando a casa está fora do tabuleiro" do
      it "retorna false para coordenadas negativas" do
        expect(described_class.empty?(board, -1, 0)).to be false
        expect(described_class.empty?(board, 0, -1)).to be false
      end

      it "retorna false para coordenadas além do tabuleiro" do
        expect(described_class.empty?(board, 8, 0)).to be false
        expect(described_class.empty?(board, 0, 8)).to be false
      end
    end
  end

  describe ".opponent?" do
    let(:board) { build_board([ 3, 2 ] => piece(2)) }

    context "quando a casa tem peça adversária" do
      it "retorna true para o jogador 1 contra peça do jogador 2" do
        expect(described_class.opponent?(board, 3, 2, 1)).to be true
      end

      it "retorna true para o jogador 2 contra peça do jogador 1" do
        board_p1 = build_board([ 3, 2 ] => piece(1))
        expect(described_class.opponent?(board_p1, 3, 2, 2)).to be true
      end
    end

    context "quando a casa tem peça própria" do
      it "retorna false" do
        expect(described_class.opponent?(board, 3, 2, 2)).to be false
      end
    end

    context "quando a casa está vazia" do
      it "retorna false" do
        expect(described_class.opponent?(board, 0, 0, 1)).to be false
      end
    end

    context "quando a casa está fora do tabuleiro" do
      it "retorna false" do
        expect(described_class.opponent?(board, -1, 0, 1)).to be false
        expect(described_class.opponent?(board, 8, 0, 1)).to be false
      end
    end
  end
end
