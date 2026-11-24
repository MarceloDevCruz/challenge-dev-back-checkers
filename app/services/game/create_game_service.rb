class Game::CreateGameService
  def self.call(board: Board.initial_grid, token_service: Game::CreateTokenService)
    new(board: board, token_service: token_service).call
  end

  def initialize(board: Board.initial_grid, token_service: Game::CreateTokenService)
    @board = board
    @token_service = token_service
  end

  def call
    Game.create!(
      player_1_token: @token_service.call,
      player_2_token: @token_service.call,
      status: :waiting_for_player,
      current_turn: :player_1,
      board_state: @board
    )
  end
end
