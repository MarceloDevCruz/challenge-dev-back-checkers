class Api::V1::GamesController < ApplicationController
  include Authenticatable

  # POST /api/v1/games
  def create
    game = ::Game::CreateGameService.call
    render json: ::CreateGameSerializer.new(game).serializable_hash, status: :created
  end

  # POST /api/v1/games/:id/join
  def join
    game = ::Game::JoinGameService.call(game_id: current_game.id, token: extract_token)
    render json: ::JoinGameSerializer.new(game).serializable_hash, status: :ok
  rescue ::Game::JoinGameService::ForbiddenError => e
    render json: { error: e.message }, status: :forbidden
  rescue ::Game::JoinGameService::JoinError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  # GET /api/v1/games/:id/board
  def board
    render json: ::BoardGameSerializer.new(current_game).serializable_hash, status: :ok
  end

  # GET /api/v1/games/:id/status
  def game_status
    render json: ::GameStatusSerializer.new(current_game).serializable_hash, status: :ok
  end

  # GET /api/v1/games/:id/valid_moves?from[row]=2&from[col]=1
  def valid_moves
    moves = ::Checker::ValidMoveService.call(current_game, params[:from], current_player)
    render json: ::ValidMovesSerializer.new(current_game, params: moves).serializable_hash, status: :ok
  rescue ::Checker::ValidMoveService::ValidMoveError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  # POST /api/v1/games/:id/move
  def move
    ::Checker::MoveService.call(current_game, params[:from], params[:to], current_player)
    render json: ::MoveSerializer.new(current_game).serializable_hash, status: :ok
  rescue ::Checker::MoveService::MoveError => e
    render json: { error: e.message }, status: :unprocessable_content
  end
end
