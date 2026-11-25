class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Partida não encontrada" }, status: :not_found
  end
end
