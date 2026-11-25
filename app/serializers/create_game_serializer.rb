class CreateGameSerializer
  include JSONAPI::Serializer

  attributes :id, :player_1_token, :player_2_token, :status
end
