class Game::JoinGameService
  class JoinError < StandardError; end
  class ForbiddenError < JoinError; end

  def self.call(game_id:, token:)
    new(game_id: game_id, token: token).call
  end

  def initialize(game_id:, token:)
    @game_id = game_id
    @token = token
  end

  def call
    game = Game.find(@game_id)

    raise ForbiddenError, I18n.t("errors.game.join_forbidden") unless game.valid_player_2_token?(@token)
    raise JoinError, I18n.t("errors.game.not_joinable") unless game.joinable?

    game.start!
    game
  end
end
