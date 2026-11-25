require "rails_helper"

RSpec.describe Checker::MoveService do
  def build_board(pieces = {})
    Array.new(Board::SIZE) do |row|
      Array.new(Board::SIZE) { |col| pieces[[ row, col ]] }
    end
  end

  def piece(player, type = "man")
    { "player" => player, "type" => type }
  end

  def coord(row, col)
    { row: row, col: col }
  end

  context "quando uma captura remove a última peça do adversário" do
    let(:game) do
      create(:game, board_state: build_board(
        [ 2, 1 ] => piece(1),
        [ 3, 2 ] => piece(2)
      ))
    end

    it "finaliza a partida com o jogador 1 como vencedor" do
      described_class.call(game, coord(2, 1), coord(4, 3), 1)
      game.reload

      expect(game).to be_finished
      expect(game.winner).to eq("player_1_wins")
      expect(game.capture_chain).to be_nil
      expect(game.board_state[3][2]).to be_nil
      expect(game.board_state[4][3]).to eq(piece(1))
    end

    it "recusa novos movimentos" do
      described_class.call(game, coord(2, 1), coord(4, 3), 1)

      expect {
        described_class.call(game.reload, coord(4, 3), coord(5, 4), 1)
      }.to raise_error(described_class::MoveError, "A partida não está em andamento")
    end
  end

  context "quando o jogador 2 captura a última peça do jogador 1" do
    let(:game) do
      create(:game, current_turn: :player_2, board_state: build_board(
        [ 4, 3 ] => piece(1),
        [ 5, 4 ] => piece(2)
      ))
    end

    it "finaliza a partida com o jogador 2 como vencedor" do
      described_class.call(game, coord(5, 4), coord(3, 2), 2)
      game.reload

      expect(game).to be_finished
      expect(game.winner).to eq("player_2_wins")
    end
  end

  context "quando o adversário ainda tem peças após o movimento" do
    let(:game) do
      create(:game, board_state: build_board(
        [ 2, 1 ] => piece(1),
        [ 3, 2 ] => piece(2),
        [ 7, 0 ] => piece(2)
      ))
    end

    it "mantém a partida em andamento e passa o turno" do
      described_class.call(game, coord(2, 1), coord(4, 3), 1)
      game.reload

      expect(game).to be_in_progress
      expect(game.winner).to be_nil
      expect(game.current_turn).to eq("player_2")
    end
  end
end
