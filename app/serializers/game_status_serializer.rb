class GameStatusSerializer
  include JSONAPI::Serializer

  attributes :id

  attribute :status do |game|
    game.status_description
  end
end
