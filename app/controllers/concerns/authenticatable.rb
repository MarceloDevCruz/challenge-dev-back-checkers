module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_player, except: [ :create ]
  end

  def authenticate_player
    token = extract_token
    return render json: { error: "Você não tem permissão, token está errado!" }, status: :unauthorized unless token

    @current_game = Game.find(params[:id])
    @current_player = @current_game.player_for_token(token)

    render json: { error: "Você não tem permissão, token errado!" }, status: :unauthorized unless @current_player
  end

  def extract_token
    auth_header = request.headers["Authorization"]
    return nil unless auth_header
    auth_header.split(" ").last if auth_header.start_with?("Bearer ")
  end

  def current_game
    @current_game
  end

  def current_player
    @current_player
  end

  def invalid_token(expected_token)
    return true if @token.blank?
    !ActiveSupport::SecurityUtils.secure_compare(@token.to_s, expected_token.to_s)
  end
end
