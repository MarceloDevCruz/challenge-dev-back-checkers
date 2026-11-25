class JoinGameSerializer
  include JSONAPI::Serializer

  attributes :id, :current_turn, :status
end
