require "rails_helper"

RSpec.describe Checker::Rules::End do
  def build_board(pieces = {})
    Array.new(Board::SIZE) do |row|
      Array.new(Board::SIZE) { |col| pieces[[ row, col ]] }
    end
  end

  def piece(player, type = "man")
    { "player" => player, "type" => type }
  end

  describe ".call" do
    context "quando os dois jogadores ainda têm peças" do
      it "retorna nil" do
        board = build_board([ 0, 1 ] => piece(1), [ 7, 0 ] => piece(2))

        expect(described_class.call(board, 1)).to be_nil
      end
    end

    context "quando o jogador 2 não tem mais peças" do
      it "retorna player_1_wins" do
        board = build_board([ 0, 1 ] => piece(1), [ 3, 2 ] => piece(1, "king"))

        expect(described_class.call(board, 1)).to eq(:player_1_wins)
      end
    end

    context "quando o jogador 1 não tem mais peças" do
      it "retorna player_2_wins" do
        board = build_board([ 7, 0 ] => piece(2))

        expect(described_class.call(board, 2)).to eq(:player_2_wins)
      end
    end

    context "quando o jogador atual é quem ficou sem peças" do
      it "retorna o adversário como vencedor" do
        board = build_board([ 7, 0 ] => piece(2))

        expect(described_class.call(board, 1)).to eq(:player_2_wins)
      end
    end
  end
end
