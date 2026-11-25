require "rails_helper"

# O ChainCapture é chamado pelo MoveService DEPOIS de aplicar a captura,
# então os tabuleiros aqui representam o estado pós-captura:
# a peça já está na casa de destino e a peça capturada já foi removida.
RSpec.describe Checker::Rules::ChainCapture do
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

  def run_chain_capture(piece:, board:, player:, from_row:, from_col:, to_row:, to_col:)
    move = build_move(piece, board, player, from_row, from_col, to_row, to_col)
    described_class.new(move).valid?
  end

  describe "#valid?" do
    context "para peão comum" do
      let(:player1_piece) { piece(1) }
      let(:player2_piece) { piece(2) }

      context "quando há outra captura disponível após pousar" do
        it "retorna true para o jogador 1 continuando para baixo e à direita" do
          # Capturou (3,2) saindo de (2,1) e pousou em (4,3); pode capturar (5,4) pousando em (6,5)
          board = build_board([ 4, 3 ] => player1_piece, [ 5, 4 ] => player2_piece)
          expect(run_chain_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)).to be true
        end

        it "retorna true para o jogador 1 continuando para baixo e à esquerda" do
          board = build_board([ 4, 3 ] => player1_piece, [ 5, 2 ] => player2_piece)
          expect(run_chain_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 5, to_row: 4, to_col: 3)).to be true
        end

        it "retorna true para o jogador 2 continuando para cima e à direita" do
          board = build_board([ 3, 3 ] => player2_piece, [ 2, 4 ] => player1_piece)
          expect(run_chain_capture(piece: player2_piece, board: board, player: 2, from_row: 5, from_col: 1, to_row: 3, to_col: 3)).to be true
        end

        it "retorna true para o jogador 2 continuando para cima e à esquerda" do
          board = build_board([ 3, 3 ] => player2_piece, [ 2, 2 ] => player1_piece)
          expect(run_chain_capture(piece: player2_piece, board: board, player: 2, from_row: 5, from_col: 5, to_row: 3, to_col: 3)).to be true
        end

        it "retorna true quando a próxima captura é para trás" do
          board = build_board([ 4, 3 ] => player1_piece, [ 3, 4 ] => player2_piece)
          expect(run_chain_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)).to be true
        end
      end

      context "quando não há captura disponível após pousar" do
        it "retorna false quando não há adversários ao redor" do
          board = build_board([ 4, 3 ] => player1_piece, [ 7, 0 ] => player2_piece)
          expect(run_chain_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)).to be false
        end

        it "retorna false quando a peça vizinha é do próprio jogador" do
          board = build_board([ 4, 3 ] => player1_piece, [ 5, 4 ] => piece(1))
          expect(run_chain_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)).to be false
        end

        it "retorna false quando a casa de pouso da próxima captura está ocupada" do
          board = build_board(
            [ 4, 3 ] => player1_piece,
            [ 5, 4 ] => player2_piece,
            [ 6, 5 ] => piece(1)
          )
          expect(run_chain_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)).to be false
        end

        it "retorna false quando o adversário está a mais de uma casa de distância" do
          # Peão só captura adversário adjacente; (6,5) está a 2 casas de (4,3)
          board = build_board([ 4, 3 ] => player1_piece, [ 6, 5 ] => player2_piece)
          expect(run_chain_capture(piece: player1_piece, board: board, player: 1, from_row: 2, from_col: 1, to_row: 4, to_col: 3)).to be false
        end
      end
    end

    context "para dama" do
      let(:player1_king) { king_piece(1) }
      let(:player2_piece) { piece(2) }

      context "quando há outra captura disponível a qualquer distância" do
        it "retorna true continuando na mesma direção" do
          # Capturou (2,2) saindo de (0,0) e pousou em (3,3); pode capturar (5,5) pousando em (6,6)
          board = build_board([ 3, 3 ] => player1_king, [ 5, 5 ] => player2_piece)
          expect(run_chain_capture(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)).to be true
        end

        it "retorna true mudando de direção entre as capturas" do
          # Pousou em (3,3); pode capturar (5,1) pousando em (6,0)
          board = build_board([ 3, 3 ] => player1_king, [ 5, 1 ] => player2_piece)
          expect(run_chain_capture(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)).to be true
        end

        it "retorna true para captura distante na direção de onde veio" do
          # Pousou em (2,2) vindo de (5,5); com (3,3) e (4,4) livres, captura (5,5) pousando em (6,6)
          board = build_board([ 2, 2 ] => player1_king, [ 5, 5 ] => player2_piece)
          expect(run_chain_capture(piece: player1_king, board: board, player: 1, from_row: 5, from_col: 5, to_row: 2, to_col: 2)).to be true
        end
      end

      context "quando não há captura disponível após pousar" do
        it "retorna false" do
          board = build_board([ 3, 3 ] => player1_king)
          expect(run_chain_capture(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)).to be false
        end

        it "retorna false quando há duas peças adversárias seguidas na diagonal" do
          board = build_board([ 3, 3 ] => player1_king, [ 5, 5 ] => player2_piece, [ 6, 6 ] => player2_piece)
          expect(run_chain_capture(piece: player1_king, board: board, player: 1, from_row: 0, from_col: 0, to_row: 3, to_col: 3)).to be false
        end
      end
    end
  end
end
