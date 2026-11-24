class Game::JoinGameService
  class JoinError < StandardError; end

  def self.call(game_id:, token:)
    new(game_id: game_id, token: token).call
  end

  def initialize(game_id:, token:)
    @game_id = game_id
    @token = token
  end

  def call
    game = Game.find(@game_id)

    unless game.joinable? && game.valid_player_2_token?(@token)
      raise JoinError, "Token invalido ou a partida não está disponível para entrar"
    end

    game.start!
    game
  end
end