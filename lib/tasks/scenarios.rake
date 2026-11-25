namespace :scenarios do
  desc "Lista os cenários de jogo disponíveis"
  task list: :environment do
    width = GameScenarios.names.map(&:size).max
    GameScenarios::SCENARIOS.each do |name, scenario|
      puts "#{name.ljust(width)}  #{scenario[:description]}"
    end
  end

  desc "Injeta um cenário numa partida existente, sem executar jogadas. Ex: bin/rails \"scenarios:load[1,cadeia_dama]\""
  task :load, [ :game_id, :name ] => :environment do |_task, args|
    if args[:game_id].blank? || args[:name].blank?
      abort "Uso: bin/rails \"scenarios:load[ID_DA_PARTIDA,CENARIO]\"  (veja bin/rails scenarios:list)"
    end

    scenario = GameScenarios.fetch(args[:name])
    game = GameScenarios.load(Game.find(args[:game_id]), args[:name])

    puts "== Partida #{game.id} agora está no cenário '#{args[:name]}'"
    puts scenario[:description]
    puts
    puts "token jogador 1: #{game.player_1_token}"
    puts "token jogador 2: #{game.player_2_token}"
    puts GameScenarios.state_line(game)
    puts
    puts GameScenarios.board_lines(game)

    scenario[:steps].each_with_index do |step, index|
      expected = step[:error] ? "Esperado: erro \"#{step[:error]}\"" : "Esperado: movimento aceito"
      puts
      puts "Passo #{index + 1} - #{step[:note]}"
      puts "  #{expected}"
      puts "  Authorization: Bearer #{GameScenarios.token_for(game, step[:player])}   (jogador #{step[:player]})"
      puts "  GET  /api/v1/games/#{game.id}/valid_moves?#{GameScenarios.valid_moves_query(step)}"
      puts "  POST /api/v1/games/#{game.id}/move   body: #{GameScenarios.move_body(step)}"
    end
  end

  desc "Cria uma partida para cada cenário, executa os passos e confere se o resultado foi o esperado"
  task play_all: :environment do
    failures = 0

    GameScenarios.names.each do |name|
      game = GameScenarios.build(name)
      results = GameScenarios.fetch(name)[:steps].map { |step| GameScenarios.play_step(game, step) }
      failed = results.reject(&:first)
      failures += failed.size
      game.destroy!

      puts "#{failed.empty? ? 'OK    ' : 'FALHOU'} #{name}"
      failed.each { |_ok, message| puts "         #{message}" }
    end

    abort "\n#{failures} passo(s) com resultado inesperado" if failures.positive?
  end
end
