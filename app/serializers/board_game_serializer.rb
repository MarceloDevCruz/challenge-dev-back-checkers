class BoardGameSerializer
  include JSONAPI::Serializer

  attributes :id, :current_turn, :status, :winner

  attribute :board_view do |game|
    BoardGameDecorator.decorate(game).board_view
  end
end
