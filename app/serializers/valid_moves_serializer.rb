class ValidMovesSerializer
  include JSONAPI::Serializer

  attributes :id

  attribute :from do |_game, params|
    params[:from]
  end

  attribute :valid_moves do |_game, params|
    params[:valid_moves]
  end
end
