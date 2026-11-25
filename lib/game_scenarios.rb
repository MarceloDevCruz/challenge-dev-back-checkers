# Cenários de jogo para testar a API (ex: pelo Postman) sem precisar jogar uma partida inteira.
# O cenário só troca o tabuleiro de uma partida existente; nenhuma jogada é executada.
#
#   bin/rails scenarios:list                          # lista os cenários
#   bin/rails "scenarios:load[1,cadeia_dama]"         # injeta o cenário na partida 1 e mostra o que testar
#   bin/rails scenarios:play_all                      # confere se todos os cenários se comportam como descrito
#
# Peças no tabuleiro: "p1"/"p2" = peão do jogador 1/2, "P1"/"P2" = dama (mesma notação do board_view).
# O jogador 1 começa em cima (linhas 0-2) e anda para baixo; o jogador 2 começa embaixo e anda para cima.
module GameScenarios
  SCENARIOS = {
    "inicial" => {
      description: "Tabuleiro inicial com a partida já em andamento (os dois jogadores já entraram).",
      initial_board: true,
      steps: [
        { player: 1, from: [ 2, 1 ], to: [ 3, 2 ], note: "Peão do jogador 1 anda uma casa para frente" },
        { player: 2, from: [ 5, 0 ], to: [ 4, 1 ], note: "Peão do jogador 2 anda uma casa para frente" }
      ]
    },

    "promocao_peao" => {
      description: "Peão do jogador 1 chega na última linha e vira dama.",
      pieces: { [ 6, 1 ] => "p1", [ 3, 6 ] => "p2" },
      steps: [
        { player: 1, from: [ 6, 1 ], to: [ 7, 0 ], note: "Peão chega na linha 7 e vira dama (P1)" }
      ]
    },

    "promocao_por_captura" => {
      description: "Peão do jogador 1 captura e pousa na última linha, virando dama.",
      pieces: { [ 5, 2 ] => "p1", [ 6, 3 ] => "p2", [ 3, 6 ] => "p2" },
      steps: [
        { player: 1, from: [ 5, 2 ], to: [ 7, 4 ], note: "Captura (6,3) e vira dama em (7,4)" }
      ]
    },

    "peao_captura_para_tras" => {
      description: "Peão do jogador 2 captura para trás (regra brasileira).",
      turn: 2,
      pieces: { [ 3, 2 ] => "p2", [ 4, 3 ] => "p1", [ 0, 1 ] => "p1" },
      steps: [
        { player: 2, from: [ 3, 2 ], to: [ 5, 4 ], note: "Peão do jogador 2 captura (4,3) andando para trás" }
      ]
    },

    "dama_captura_para_tras" => {
      description: "Dama do jogador 1 captura para trás à distância.",
      pieces: { [ 4, 3 ] => "P1", [ 2, 1 ] => "p2", [ 7, 6 ] => "p2" },
      steps: [
        { player: 1, from: [ 4, 3 ], to: [ 1, 0 ], note: "Dama captura (2,1) indo para trás e pousa em (1,0)" }
      ]
    },

    "dama_captura_longa" => {
      description: "Dama voadora: atravessa casas vazias, captura e pode pousar em qualquer casa livre depois da peça.",
      pieces: { [ 7, 0 ] => "P1", [ 3, 4 ] => "p2", [ 0, 3 ] => "p2" },
      steps: [
        { player: 1, from: [ 7, 0 ], to: [ 1, 6 ], note: "Captura (3,4); valid_moves mostra (2,5), (1,6) e (0,7) como capturas" }
      ]
    },

    "dama_nao_salta_duas" => {
      description: "Dama não pode capturar duas peças seguidas na mesma diagonal.",
      pieces: { [ 0, 1 ] => "P1", [ 2, 3 ] => "p2", [ 3, 4 ] => "p2" },
      steps: [
        { player: 1, from: [ 0, 1 ], to: [ 4, 5 ], note: "Tenta saltar (2,3) e (3,4) de uma vez", error: "Movimento inválido para esta peça" },
        { player: 1, from: [ 0, 1 ], to: [ 1, 2 ], note: "Movimento simples continua permitido" }
      ]
    },

    "cadeia_peao_frente_tras" => {
      description: "Cadeia de capturas do peão: captura para frente e depois para trás.",
      pieces: { [ 2, 1 ] => "p1", [ 3, 2 ] => "p2", [ 3, 4 ] => "p2", [ 7, 0 ] => "p2" },
      steps: [
        { player: 1, from: [ 2, 1 ], to: [ 4, 3 ], note: "Captura (3,2) para frente; turno continua com o jogador 1 (capture_chain)" },
        { player: 1, from: [ 4, 3 ], to: [ 2, 5 ], note: "Captura (3,4) para trás; cadeia termina e o turno passa" }
      ]
    },

    "cadeia_peao_tripla" => {
      description: "Peão faz três capturas seguidas em zigue-zague (frente, frente, trás).",
      pieces: { [ 2, 1 ] => "p1", [ 3, 2 ] => "p2", [ 5, 4 ] => "p2", [ 5, 6 ] => "p2", [ 7, 0 ] => "p2" },
      steps: [
        { player: 1, from: [ 2, 1 ], to: [ 4, 3 ], note: "1ª captura: (3,2)" },
        { player: 1, from: [ 4, 3 ], to: [ 6, 5 ], note: "2ª captura: (5,4)" },
        { player: 1, from: [ 6, 5 ], to: [ 4, 7 ], note: "3ª captura para trás: (5,6); turno passa" }
      ]
    },

    "cadeia_dama" => {
      description: "Cadeia de capturas da dama mudando de direção.",
      pieces: { [ 0, 1 ] => "P1", [ 2, 3 ] => "p2", [ 5, 2 ] => "p2", [ 7, 6 ] => "p2" },
      steps: [
        { player: 1, from: [ 0, 1 ], to: [ 3, 4 ], note: "Captura (2,3); turno continua com o jogador 1" },
        { player: 1, from: [ 3, 4 ], to: [ 6, 1 ], note: "Muda de direção e captura (5,2); turno passa" }
      ]
    },

    "cadeia_obrigatoria" => {
      description: "Partida no meio de uma cadeia: só a peça da cadeia pode jogar, e só capturando.",
      pieces: { [ 4, 3 ] => "p1", [ 2, 7 ] => "p1", [ 5, 4 ] => "p2", [ 7, 0 ] => "p2" },
      capture_chain: [ 4, 3 ],
      steps: [
        { player: 1, from: [ 2, 7 ], to: [ 3, 6 ], note: "Tenta mover outra peça", error: "Você deve continuar a captura com a mesma peça" },
        { player: 1, from: [ 4, 3 ], to: [ 5, 2 ], note: "Tenta um movimento simples com a peça da cadeia", error: "Você deve continuar capturando" },
        { player: 1, from: [ 4, 3 ], to: [ 6, 5 ], note: "Continua capturando (5,4)" }
      ]
    },

    "fim_de_jogo_peao" => {
      description: "Jogador 1 captura a última peça do jogador 2 e vence.",
      pieces: { [ 2, 1 ] => "p1", [ 3, 2 ] => "p2" },
      steps: [
        { player: 1, from: [ 2, 1 ], to: [ 4, 3 ], note: "Captura a última peça: status finished, winner player_1_wins" },
        { player: 2, from: [ 4, 3 ], to: [ 3, 2 ], note: "Qualquer jogada depois do fim é recusada", error: "A partida não está em andamento" }
      ]
    },

    "fim_de_jogo_cadeia" => {
      description: "A partida termina no fim de uma cadeia de capturas.",
      pieces: { [ 2, 1 ] => "p1", [ 3, 2 ] => "p2", [ 5, 4 ] => "p2" },
      steps: [
        { player: 1, from: [ 2, 1 ], to: [ 4, 3 ], note: "1ª captura; ainda resta uma peça" },
        { player: 1, from: [ 4, 3 ], to: [ 6, 5 ], note: "Captura a última peça: winner player_1_wins" }
      ]
    },

    "fim_de_jogo_dama_jogador_2" => {
      description: "Dama do jogador 2 captura a última peça do jogador 1 e vence.",
      turn: 2,
      pieces: { [ 7, 0 ] => "P2", [ 4, 3 ] => "p1", [ 6, 5 ] => "p2" },
      steps: [
        { player: 2, from: [ 7, 0 ], to: [ 2, 5 ], note: "Dama captura (4,3) à distância: winner player_2_wins" }
      ]
    }
  }.freeze

  PIECE_CODES = {
    "p1" => { "player" => 1, "type" => "man" },
    "p2" => { "player" => 2, "type" => "man" },
    "P1" => { "player" => 1, "type" => "king" },
    "P2" => { "player" => 2, "type" => "king" }
  }.freeze

  module_function

  def names
    SCENARIOS.keys
  end

  def fetch(name)
    SCENARIOS.fetch(name.to_s) do
      raise ArgumentError, "Cenário '#{name}' não existe. Disponíveis: #{names.join(', ')}"
    end
  end

  # Estado da partida no início do cenário: em andamento, sem vencedor, com o tabuleiro e o turno do cenário.
  def attributes(name)
    scenario = fetch(name)
    chain = scenario[:capture_chain]

    {
      status: :in_progress,
      winner: nil,
      current_turn: scenario.fetch(:turn, 1) == 1 ? :player_1 : :player_2,
      capture_chain: chain && { "row" => chain[0], "col" => chain[1] },
      board_state: scenario[:initial_board] ? Board.initial_grid : board_from(scenario[:pieces])
    }
  end

  # Injeta o cenário numa partida existente (os tokens continuam os mesmos).
  def load(game, name)
    game.update!(attributes(name))
    game
  end

  # Cria uma partida nova já com o cenário (usado pelo scenarios:play_all).
  def build(name)
    Game.create!(
      player_1_token: Game::CreateTokenService.call,
      player_2_token: Game::CreateTokenService.call,
      **attributes(name)
    )
  end

  def board_from(pieces)
    Array.new(Board::SIZE) do |row|
      Array.new(Board::SIZE) { |col| PIECE_CODES.fetch(pieces[[ row, col ]]) if pieces[[ row, col ]] }
    end
  end

  def token_for(game, player)
    player == 1 ? game.player_1_token : game.player_2_token
  end

  def coord(pair)
    { row: pair[0], col: pair[1] }
  end

  def board_lines(game)
    BoardGameDecorator.decorate(game).board_view
  end

  def state_line(game)
    chain = game.capture_chain ? "(#{game.capture_chain['row']},#{game.capture_chain['col']})" : "-"
    "status: #{game.status} | turno: #{game.current_turn} | winner: #{game.winner || '-'} | capture_chain: #{chain}"
  end

  def move_body(step)
    { from: coord(step[:from]), to: coord(step[:to]) }.to_json
  end

  def valid_moves_query(step)
    "from[row]=#{step[:from][0]}&from[col]=#{step[:from][1]}"
  end

  # Executa um passo pelo MoveService e diz se o resultado bateu com o esperado.
  # Retorna [ok?, mensagem]
  def play_step(game, step)
    Checker::MoveService.call(game, coord(step[:from]), coord(step[:to]), step[:player])
    game.reload
    return [ false, "esperava o erro \"#{step[:error]}\", mas o movimento foi aceito" ] if step[:error]

    [ true, "movimento aceito" ]
  rescue Checker::MoveService::MoveError => e
    game.reload
    return [ true, "recusado como esperado: #{e.message}" ] if step[:error] == e.message

    [ false, "erro inesperado: #{e.message}" ]
  end
end
