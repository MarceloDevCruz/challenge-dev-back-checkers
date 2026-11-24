class Api::V1::GamesController < ApplicationController
  include Authenticatable

  before_action :set_game, only: [ :join, :board, :valid_moves, :move ]

  # POST /api/v1/games
  def create
    game = ::Game::CreateGameService.call
    render json: ::CreateGameSerializer.new(game).serializable_hash, status: :created
  end

  # POST /api/v1/games/:id/join
  def join
    @game = ::Game::JoinGameService.call(game_id: @current_game.id, token: extract_token)
    render json: ::JoinGameSerializer.new(@game).serializable_hash, status: :ok
  rescue ::Game::JoinGameService::JoinError => e
    render json: { error: e.message }, status: :unauthorized
  end

  # GET /api/v1/games/:id/board
  def board
    render json: ::BoardGameSerializer.new(@game).serializable_hash, status: :ok
  end

  # GET /api/v1/games/:id/valid_moves
  def valid_moves
    @game = ::Checker::ValidMoveService.call(game_id: @current_game.id, token: extract_token)
  rescue ::Checker::ValidMoveService::ValidMoveError => e
    render json: { error: e.message }, status: :unauthorized
  end

  # POST /api/v1/games/:id/move
  def move
    ::Checker::MoveService.call(@game, params[:from], params[:to], @current_player, extract_token)
    render json: ::MoveSerializer.new(@game).serializable_hash, status: :ok
  rescue ::Checker::MoveService::MoveError => e
    render json: { error: e.message }, status: :unauthorized
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end
end
