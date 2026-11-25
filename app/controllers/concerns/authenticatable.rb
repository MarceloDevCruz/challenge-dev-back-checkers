module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_player, except: [ :create ]
  end

  def authenticate_player
    token = extract_token
    return render json: { error: I18n.t("errors.auth.missing_token") }, status: :unauthorized unless token

    @current_game = Game.find(params[:id])
    @current_player = @current_game.player_for_token(token)

    render json: { error: I18n.t("errors.auth.invalid_token") }, status: :unauthorized unless @current_player
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
end
