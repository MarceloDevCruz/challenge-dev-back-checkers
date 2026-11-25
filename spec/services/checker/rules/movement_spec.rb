require "rails_helper"

RSpec.describe Checker::Rules::Movement do
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

  def run_movement(piece:, board:, player:, from_row:, from_col:, to_row:, to_col:)
    move = build_move(piece, board, player, from_row, from_col, to_row, to_col)
    described_class.new(move).valid?
  end

  describe "#valid?" do
    context "para peão comum" do
      let(:player1_piece) { piece(1) }
      let(:player2_piece) { piece(2) }

      context "quando anda uma casa para frente na diagonal para uma casa vazia" do
        it "retorna true para o jogador 1 indo para baixo e à direita" do
          board = build_board([ 2, 1 ] => player1_piece)
          expect(run_movement(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)).to be true
        end

        it "retorna true para o jogador 1 indo para baixo e à esquerda" do
          board = build_board([ 2, 3 ] => player1_piece)
          expect(run_movement(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 3, to_row: 3, to_col: 2)).to be true
        end

        it "retorna true para o jogador 2 indo para cima e à direita" do
          board = build_board([ 5, 1 ] => player2_piece)
          expect(run_movement(piece: player2_piece, board: board, player: 2, from_row: 5, from_col: 1, to_row: 4, to_col: 2)).to be true
        end

        it "retorna true para o jogador 2 indo para cima e à esquerda" do
          board = build_board([ 5, 3 ] => player2_piece)
          expect(run_movement(piece: player2_piece, board: board, player: 2, from_row: 5, from_col: 3, to_row: 4, to_col: 2)).to be true
        end
      end

      context "quando anda para trás" do
        it "retorna false para o jogador 1 indo para cima" do
          board = build_board([ 3, 2 ] => player1_piece)
          expect(run_movement(piece: player1_piece, board: board, player: 1, from_row: 3, from_col: 2, to_row: 2, to_col: 1)).to be false
        end

        it "retorna false para o jogador 2 indo para baixo" do
          board = build_board([ 4, 2 ] => player2_piece)
          expect(run_movement(piece: player2_piece, board: board, player: 2, from_row: 4, from_col: 2, to_row: 5, to_col: 1)).to be false
        end
      end

      context "quando anda mais de uma casa" do
        it "retorna false para o jogador 1 andando duas casas" do
          board = build_board([ 2, 1 ] => player1_piece)
          expect(run_movement(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)).to be false
        end
      end

      context "quando o destino não está vazio" do
        it "retorna false quando o destino tem peça adversária" do
          board = build_board([ 2, 1 ] => player1_piece, [ 3, 2 ] => player2_piece)
          expect(run_movement(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)).to be false
        end

        it "retorna false quando o destino tem peça própria" do
          board = build_board([ 2, 1 ] => player1_piece, [ 3, 2 ] => player1_piece)
          expect(run_movement(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)).to be false
        end
      end

      context "quando o movimento não é diagonal" do
        it "retorna false para movimento horizontal" do
          board = build_board([ 2, 1 ] => player1_piece)
          expect(run_movement(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 2, to_col: 3)).to be false
        end

        it "retorna false para movimento vertical" do
          board = build_board([ 2, 1 ] => player1_piece)
          expect(run_movement(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 1)).to be false
        end
      end
    end

    context "para dama" do
      let(:player1_king) { king_piece(1) }
      let(:player2_piece) { piece(2) }

      context "quando anda qualquer distância na diagonal com caminho livre" do
        it "retorna true para uma casa" do
          board = build_board([ 2, 1 ] => player1_king)
          expect(run_movement(piece: player1_king, board: board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)).to be true
        end

        it "retorna true para várias casas com caminho livre" do
          board = build_board([ 0, 0 ] => player1_king)
          expect(run_movement(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)).to be true
        end

        it "retorna true andando para trás (dama anda em qualquer direção)" do
          board = build_board([ 5, 5 ] => player1_king)
          expect(run_movement(piece: player1_king, board: board, player: 1, from_row: 5, from_col: 5, to_row: 2, to_col: 2)).to be true
        end
      end

      context "quando o caminho está bloqueado" do
        it "retorna false quando a casa intermediária tem peça adversária" do
          board = build_board([ 0, 0 ] => player1_king, [ 1, 1 ] => player2_piece)
          expect(run_movement(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)).to be false
        end

        it "retorna false quando a casa intermediária tem peça própria" do
          board = build_board([ 0, 0 ] => player1_king, [ 1, 1 ] => player1_king)
          expect(run_movement(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)).to be false
        end
      end

      context "quando o destino não está vazio" do
        it "retorna false" do
          board = build_board([ 2, 1 ] => player1_king, [ 3, 2 ] => player2_piece)
          expect(run_movement(piece: player1_king, board: board, player: 1, from_row: 2, from_col: 1, to_row: 3, to_col: 2)).to be false
        end
      end

      context "quando o movimento não é diagonal" do
        it "retorna false para movimento horizontal" do
          board = build_board([ 2, 1 ] => player1_king)
          expect(run_movement(piece: player1_king, board: board, player: 1, from_row: 2, from_col: 1, to_row: 2, to_col: 3)).to be false
        end

        it "retorna false para movimento vertical" do
          board = build_board([ 2, 1 ] => player1_king)
          expect(run_movement(piece: player1_king, board: board, player: 1, from_row: 2, from_col: 1, to_row: 5, to_col: 1)).to be false
        end
      end
    end
  end
end
