require "rails_helper"

RSpec.describe Checker::ValidMoveService do
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

  def valid_moves_for(game, from, player)
    described_class.call(game, from, player)[:valid_moves]
  end

  def action(row, col, capture: false)
    { to: { row: row, col: col }, capture: capture }
  end

  describe ".call" do
    context "com o tabuleiro inicial" do
      let(:game) { create(:game) }

      it "retorna os dois movimentos para frente de um peão da linha de frente" do
        expect(valid_moves_for(game, coord(2, 1), 1)).to contain_exactly(action(3, 0), action(3, 2))
      end

      it "retorna a coordenada de origem convertida para inteiros" do
        result = described_class.call(game, ActionController::Parameters.new("row" => "2", "col" => "1"), 1)

        expect(result[:from]).to eq(row: 2, col: 1)
      end

      it "retorna lista vazia para um peão bloqueado" do
        expect(valid_moves_for(game, coord(1, 0), 1)).to eq([])
      end

      it "aceita a coordenada com chaves e valores em string (como vem dos params)" do
        expect(valid_moves_for(game, ActionController::Parameters.new("row" => "2", "col" => "7"), 1))
          .to contain_exactly(action(3, 6))
      end
    end

    context "quando a peça pode capturar" do
      let(:game) do
        create(:game, board_state: build_board([ 2, 1 ] => piece(1), [ 3, 2 ] => piece(2)))
      end

      it "inclui a captura marcada como capture: true" do
        expect(valid_moves_for(game, coord(2, 1), 1)).to contain_exactly(
          action(3, 0),
          action(4, 3, capture: true)
        )
      end
    end

    context "quando o peão pode capturar para trás" do
      let(:game) do
        create(:game, board_state: build_board([ 4, 3 ] => piece(1), [ 3, 2 ] => piece(2)))
      end

      it "inclui a captura para trás" do
        expect(valid_moves_for(game, coord(4, 3), 1)).to contain_exactly(
          action(5, 2),
          action(5, 4),
          action(2, 1, capture: true)
        )
      end
    end

    context "para dama" do
      let(:game) do
        create(:game, board_state: build_board([ 0, 1 ] => piece(1, "king"), [ 7, 0 ] => piece(2)))
      end

      it "retorna movimentos a qualquer distância na diagonal" do
        expect(valid_moves_for(game, coord(0, 1), 1)).to contain_exactly(
          action(1, 0),
          *(1..6).map { |d| action(d, 1 + d) }
        )
      end
    end

    context "durante uma cadeia de capturas" do
      let(:game) do
        create(:game, :in_capture_chain, board_state: build_board(
          [ 4, 3 ] => piece(1),
          [ 5, 4 ] => piece(2),
          [ 2, 1 ] => piece(1)
        ))
      end

      it "retorna apenas as capturas da peça da cadeia" do
        expect(valid_moves_for(game, coord(4, 3), 1)).to contain_exactly(action(6, 5, capture: true))
      end

      it "lança ValidMoveError para outra peça" do
        expect { described_class.call(game, coord(2, 1), 1) }
          .to raise_error(described_class::ValidMoveError, "Você deve continuar a captura com a mesma peça")
      end
    end

    context "quando a coordenada é inválida" do
      let(:game) { create(:game) }

      it "lança ValidMoveError quando a coordenada não é enviada" do
        expect { described_class.call(game, nil, 1) }
          .to raise_error(described_class::ValidMoveError, "A coordenada de origem é obrigatória")
      end

      it "lança ValidMoveError quando a coordenada está fora do tabuleiro" do
        expect { described_class.call(game, coord(8, 1), 1) }
          .to raise_error(described_class::ValidMoveError, "Coordenadas fora do tabuleiro")
      end

      it "lança ValidMoveError quando não há peça na origem" do
        expect { described_class.call(game, coord(3, 0), 1) }
          .to raise_error(described_class::ValidMoveError, "Não há peça na posição de origem")
      end

      it "lança ValidMoveError quando a peça é do adversário" do
        expect { described_class.call(game, coord(5, 0), 1) }
          .to raise_error(described_class::ValidMoveError, "A peça selecionada pertence ao oponente")
      end
    end

    context "quando a partida não está em andamento" do
      let(:game) { create(:game, :finished) }

      it "lança ValidMoveError" do
        expect { described_class.call(game, coord(2, 1), 1) }
          .to raise_error(described_class::ValidMoveError, "A partida não está em andamento")
      end
    end

    context "quando não é o turno do jogador" do
      let(:game) { create(:game) }

      it "lança ValidMoveError" do
        expect { described_class.call(game, coord(5, 0), 2) }
          .to raise_error(described_class::ValidMoveError, "Não é o seu turno")
      end
    end
  end
end
