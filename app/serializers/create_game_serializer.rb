class CreateGameSerializer
  include JSONAPI::Serializer

  attributes :id, :player_2_token, :status
end
