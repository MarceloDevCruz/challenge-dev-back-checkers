class MoveSerializer
  include JSONAPI::Serializer

  attributes :id, :current_turn, :status

  attribute :board_view do |game|
    BoardGameDecorator.decorate(game).board_view
  end
end
