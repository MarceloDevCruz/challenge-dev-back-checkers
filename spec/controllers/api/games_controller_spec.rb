require "rails_helper"

# Testes de integração: passam pela API de verdade (rotas, autenticação, serviços e banco), sem stubs.
RSpec.describe Api::V1::GamesController, type: :request do
  def json
    JSON.parse(response.body)
  end

  def attributes
    json.dig("data", "attributes")
  end

  def auth(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def build_board(pieces = {})
    Array.new(Board::SIZE) do |row|
      Array.new(Board::SIZE) { |col| pieces[[ row, col ]] }
    end
  end

  def piece(player, type = "man")
    { "player" => player, "type" => type }
  end

  def create_game_via_api
    post "/api/v1/games"
    attributes
  end

  let(:game) { create(:game) }
  let(:player_1_headers) { auth(game.player_1_token) }
  let(:player_2_headers) { auth(game.player_2_token) }

  describe "fluxo completo de uma partida" do
    it "cria, entra, consulta, move e acompanha o status" do
      created = create_game_via_api
      game_id = created["id"]
      player_1 = auth(created["player_1_token"])
      player_2 = auth(created["player_2_token"])

      get "/api/v1/games/#{game_id}/status", headers: player_1
      expect(attributes["status"]).to eq("waiting for opponent")

      post "/api/v1/games/#{game_id}/join", headers: player_2
      expect(response).to have_http_status(:ok)
      expect(attributes["status"]).to eq("in_progress")

      get "/api/v1/games/#{game_id}/status", headers: player_2
      expect(attributes["status"]).to eq("player_1 turn")

      get "/api/v1/games/#{game_id}/valid_moves", params: { from: { row: 2, col: 1 } }, headers: player_1
      expect(response).to have_http_status(:ok)
      expect(json.dig("data", "type")).to eq("valid_moves")
      expect(attributes["from"]).to eq("row" => 2, "col" => 1)
      expect(attributes["valid_moves"]).to contain_exactly(
        { "to" => { "row" => 3, "col" => 0 }, "capture" => false },
        { "to" => { "row" => 3, "col" => 2 }, "capture" => false }
      )

      post "/api/v1/games/#{game_id}/move", params: { from: { row: 2, col: 1 }, to: { row: 3, col: 2 } }, headers: player_1
      expect(response).to have_http_status(:ok)
      expect(attributes["current_turn"]).to eq("player_2")

      get "/api/v1/games/#{game_id}/status", headers: player_1
      expect(attributes["status"]).to eq("player_2 turn")

      get "/api/v1/games/#{game_id}/board", headers: player_1
      expect(response).to have_http_status(:ok)
      expect(attributes["board_view"][5]).to start_with("3 | __ | __ | p1 |")
    end

    it "termina a partida quando o adversário fica sem peças" do
      game.update!(board_state: build_board([ 2, 1 ] => piece(1), [ 3, 2 ] => piece(2)))

      post "/api/v1/games/#{game.id}/move", params: { from: { row: 2, col: 1 }, to: { row: 4, col: 3 } }, headers: player_1_headers
      expect(response).to have_http_status(:ok)
      expect(attributes["status"]).to eq("finished")

      get "/api/v1/games/#{game.id}/status", headers: player_2_headers
      expect(attributes["status"]).to eq("player_1_wins")

      get "/api/v1/games/#{game.id}/board", headers: player_2_headers
      expect(attributes["winner"]).to eq("player_1_wins")
    end
  end

  describe "POST /api/v1/games" do
    it "cria a partida aguardando o oponente e devolve os tokens dos dois jogadores" do
      post "/api/v1/games"

      expect(response).to have_http_status(:created)
      expect(attributes["status"]).to eq("waiting_for_player")
      expect(attributes["player_1_token"]).to be_present
      expect(attributes["player_2_token"]).to be_present
      expect(attributes["player_1_token"]).not_to eq(attributes["player_2_token"])
    end
  end

  describe "autenticação" do
    it "retorna 401 quando o header Authorization não é enviado" do
      get "/api/v1/games/#{game.id}/board"

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Token de acesso não informado")
    end

    it "retorna 401 quando o token não pertence à partida" do
      other_game = create(:game, player_1_token: "outro-1", player_2_token: "outro-2")

      get "/api/v1/games/#{game.id}/board", headers: auth(other_game.player_1_token)

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Token de acesso inválido para esta partida")
    end

    it "retorna 404 quando a partida não existe" do
      get "/api/v1/games/0/board", headers: player_1_headers

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Partida não encontrada")
    end
  end

  describe "POST /api/v1/games/:id/join" do
    let(:game) { create(:game, status: :waiting_for_player) }

    it "retorna 403 quando o player 1 tenta entrar como player 2" do
      post "/api/v1/games/#{game.id}/join", headers: player_1_headers

      expect(response).to have_http_status(:forbidden)
      expect(game.reload).to be_waiting_for_player
    end

    it "retorna 422 quando a partida já começou" do
      game.start!

      post "/api/v1/games/#{game.id}/join", headers: player_2_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("A partida não está disponível para entrar")
    end
  end

  describe "GET /api/v1/games/:id/valid_moves" do
    it "retorna 422 quando a peça é do adversário" do
      get "/api/v1/games/#{game.id}/valid_moves", params: { from: { row: 5, col: 0 } }, headers: player_1_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("A peça selecionada pertence ao oponente")
    end

    it "retorna 422 quando a coordenada não é enviada" do
      get "/api/v1/games/#{game.id}/valid_moves", headers: player_1_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("A coordenada de origem é obrigatória")
    end
  end

  describe "POST /api/v1/games/:id/move" do
    it "retorna 422 quando não é o turno do jogador" do
      post "/api/v1/games/#{game.id}/move", params: { from: { row: 5, col: 0 }, to: { row: 4, col: 1 } }, headers: player_2_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("Não é o seu turno")
    end

    it "retorna 422 para um movimento que viola as regras" do
      post "/api/v1/games/#{game.id}/move", params: { from: { row: 2, col: 1 }, to: { row: 4, col: 3 } }, headers: player_1_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("Movimento inválido para esta peça")
    end

    it "retorna 422 quando as coordenadas não são enviadas" do
      post "/api/v1/games/#{game.id}/move", headers: player_1_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("As coordenadas de origem e destino são obrigatórias")
    end
  end
end
