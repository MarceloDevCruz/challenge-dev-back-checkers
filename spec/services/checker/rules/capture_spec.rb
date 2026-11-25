require "rails_helper"

RSpec.describe Checker::Rules::Capture do
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

  def build_move(piece, board, player, from_row, from_col, to_row, to_col)
    Checker::Rules::Move.new(
      piece: piece,
      board: board,
      player: player,
      from_row: from_row,
      from_col: from_col,
      to_row: to_row,
      to_col: to_col
    )
  end

  def run_capture(piece:, board:, player:, from_row:, from_col:, to_row:, to_col:)
    move = build_move(piece, board, player, from_row, from_col, to_row, to_col)
    capture = described_class.new(move)
    {
      valid: capture.valid?,
      captured_square: capture.captured_square
    }
  end

  describe "#valid?" do
    context "para peão comum" do
      let(:player1_piece) { piece(1) }
      let(:player2_piece) { piece(2) }

      context "quando salta 2 casas na diagonal sobre uma peça adversária" do
        it "retorna true para o jogador 1 capturando para baixo e à direita" do
          board = build_board([ 2, 1 ] => player1_piece, [ 3, 2 ] => player2_piece)
          result = run_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)
          expect(result[:valid]).to be true
          expect(result[:captured_square]).to eq([ 3, 2 ])
        end

        it "retorna true para o jogador 1 capturando para baixo e à esquerda" do
          board = build_board([ 2, 3 ] => player1_piece, [ 3, 2 ] => player2_piece)
          result = run_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 3, to_row: 4, to_col: 1)
          expect(result[:valid]).to be true
          expect(result[:captured_square]).to eq([ 3, 2 ])
        end

        it "retorna true para o jogador 2 capturando para cima e à direita" do
          board = build_board([ 5, 1 ] => player2_piece, [ 4, 2 ] => player1_piece)
          result = run_capture(piece: player2_piece, board: board, player: 2, from_row: 5, from_col: 1, to_row: 3, to_col: 3)
          expect(result[:valid]).to be true
          expect(result[:captured_square]).to eq([ 4, 2 ])
        end

        it "retorna true para o jogador 2 capturando para cima e à esquerda" do
          board = build_board([ 5, 3 ] => player2_piece, [ 4, 2 ] => player1_piece)
          result = run_capture(piece: player2_piece, board: board, player: 2, from_row: 5, from_col: 3, to_row: 3, to_col: 1)
          expect(result[:valid]).to be true
          expect(result[:captured_square]).to eq([ 4, 2 ])
        end
      end

      context "quando não salta exatamente 2 casas" do
        it "retorna false para um passo simples" do
          board = build_board([ 2, 1 ] => player1_piece, [ 3, 2 ] => player2_piece)
          result = run_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)
          expect(result[:valid]).to be false
        end

        it "retorna false para mais de 2 casas" do
          board = build_board([ 2, 1 ] => player1_piece, [ 3, 2 ] => player2_piece)
          result = run_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 5, to_col: 4)
          expect(result[:valid]).to be false
        end
      end

      context "quando a casa intermediária está vazia" do
        it "retorna false" do
          board = build_board([ 2, 1 ] => player1_piece)
          result = run_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)
          expect(result[:valid]).to be false
        end
      end

      context "quando a casa intermediária tem uma peça própria" do
        it "retorna false" do
          board = build_board([ 2, 1 ] => player1_piece, [ 3, 2 ] => piece(1))
          result = run_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)
          expect(result[:valid]).to be false
        end
      end

      context "quando captura para trás (permitido pela regra brasileira)" do
        it "retorna true para o jogador 1" do
          board = build_board([ 3, 2 ] => player1_piece, [ 2, 1 ] => player2_piece)
          result = run_capture(piece: player1_piece, board: board, player: 1, from_row: 3, from_col: 2, to_row: 1, to_col: 0)
          expect(result[:valid]).to be true
          expect(result[:captured_square]).to eq([ 2, 1 ])
        end

        it "retorna true para o jogador 2" do
          board = build_board([ 4, 2 ] => player2_piece, [ 5, 1 ] => player1_piece)
          result = run_capture(piece: player2_piece, board: board, player: 2, from_row: 4, from_col: 2, to_row: 6, to_col: 0)
          expect(result[:valid]).to be true
          expect(result[:captured_square]).to eq([ 5, 1 ])
        end
      end
    end

    context "para dama" do
      let(:player1_king) { king_piece(1) }
      let(:player2_piece) { piece(2) }
      let(:player2_king) { king_piece(2) }

      context "quando captura a qualquer distância com exatamente uma peça adversária no caminho" do
        it "retorna true para adversário adjacente com casa livre depois" do
          board = build_board([ 2, 1 ] => player1_king, [ 3, 2 ] => player2_piece)
          result = run_capture(piece: player1_king, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)
          expect(result[:valid]).to be true
          expect(result[:captured_square]).to eq([ 3, 2 ])
        end

        it "retorna true para captura longa com caminho livre antes e depois do adversário" do
          board = build_board([ 0, 0 ] => player1_king, [ 2, 2 ] => player2_piece)
          result = run_capture(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 5, to_col: 5)
          expect(result[:valid]).to be true
          expect(result[:captured_square]).to eq([ 2, 2 ])
        end

        it "retorna true para captura em qualquer direção (dama captura para trás)" do
          board = build_board([ 5, 5 ] => player1_king, [ 3, 3 ] => player2_piece)
          result = run_capture(piece: player1_king, board: board, player: 1, from_row: 5, from_col: 5, to_row: 0, to_col: 0)
          expect(result[:valid]).to be true
          expect(result[:captured_square]).to eq([ 3, 3 ])
        end
      end

      context "quando o caminho não tem peças adversárias" do
        it "retorna false" do
          board = build_board([ 0, 0 ] => player1_king)
          result = run_capture(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)
          expect(result[:valid]).to be false
        end
      end

      context "quando o caminho tem mais de uma peça adversária" do
        it "retorna false" do
          board = build_board([ 0, 0 ] => player1_king, [ 1, 1 ] => player2_piece, [ 2, 2 ] => player2_king)
          result = run_capture(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 5, to_col: 5)
          expect(result[:valid]).to be false
        end
      end

      context "quando o movimento não é diagonal" do
        it "retorna false" do
          board = build_board([ 2, 1 ] => player1_king, [ 2, 3 ] => player2_piece)
          result = run_capture(piece: player1_king, board: board, player: 1, from_row: 2, from_col: 1, to_row: 2, to_col: 3)
          expect(result[:valid]).to be false
        end
      end
    end
  end

  describe "#captured_square" do
    it "retorna as coordenadas da peça capturada numa captura válida" do
      player1_piece = piece(1)
      player2_piece = piece(2)
      board = build_board([ 2, 1 ] => player1_piece, [ 3, 2 ] => player2_piece)

      move = build_move(player1_piece, board, 1, 2, 1, 4, 3)
      capture = described_class.new(move)

      expect(capture.captured_square).to eq([ 3, 2 ])
    end

    it "retorna nil quando não é uma captura válida" do
      player1_piece = piece(1)
      board = build_board([ 2, 1 ] => player1_piece)

      move = build_move(player1_piece, board, 1, 2, 1, 3, 2)
      capture = described_class.new(move)

      expect(capture.captured_square).to be_nil
    end
  end
end
