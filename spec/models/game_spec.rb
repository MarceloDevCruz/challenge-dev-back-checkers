require "rails_helper"

RSpec.describe Game do
  describe "#status_description" do
    it "retorna 'waiting for opponent' enquanto o player 2 não entrou" do
      expect(build(:game, status: :waiting_for_player).status_description).to eq("waiting for opponent")
    end

    it "retorna 'player_1 turn' na vez do jogador 1" do
      expect(build(:game, current_turn: :player_1).status_description).to eq("player_1 turn")
    end

    it "retorna 'player_2 turn' na vez do jogador 2" do
      expect(build(:game, current_turn: :player_2).status_description).to eq("player_2 turn")
    end

    it "retorna 'player_1 won' quando o jogador 1 venceu" do
      expect(build(:game, status: :finished, winner: :player_1_wins).status_description).to eq("player_1 won")
    end

    it "retorna 'player_2 won' quando o jogador 2 venceu" do
      expect(build(:game, status: :finished, winner: :player_2_wins).status_description).to eq("player_2 won")
    end
  end
end
