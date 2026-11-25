FactoryBot.define do
  factory :game do
    status { :in_progress }
    current_turn { :player_1 }
    player_1_token { "token-player-1" }
    player_2_token { "token-player-2" }
    capture_chain { nil }
    board_state do
      [
        [ nil, { "player" => 1, "type" => "man" }, nil, { "player" => 1, "type" => "man" }, nil, { "player" => 1, "type" => "man" }, nil, { "player" => 1, "type" => "man" } ],
        [ { "player" => 1, "type" => "man" }, nil, { "player" => 1, "type" => "man" }, nil, { "player" => 1, "type" => "man" }, nil, { "player" => 1, "type" => "man" }, nil ],
        [ nil, { "player" => 1, "type" => "man" }, nil, { "player" => 1, "type" => "man" }, nil, { "player" => 1, "type" => "man" }, nil, { "player" => 1, "type" => "man" } ],
        [ nil, nil, nil, nil, nil, nil, nil, nil ],
        [ nil, nil, nil, nil, nil, nil, nil, nil ],
        [ { "player" => 2, "type" => "man" }, nil, { "player" => 2, "type" => "man" }, nil, { "player" => 2, "type" => "man" }, nil, { "player" => 2, "type" => "man" }, nil ],
        [ nil, { "player" => 2, "type" => "man" }, nil, { "player" => 2, "type" => "man" }, nil, { "player" => 2, "type" => "man" }, nil, { "player" => 2, "type" => "man" } ],
        [ { "player" => 2, "type" => "man" }, nil, { "player" => 2, "type" => "man" }, nil, { "player" => 2, "type" => "man" }, nil, { "player" => 2, "type" => "man" }, nil ]
      ]
    end

    trait :waiting_for_player_2 do
      player_2_token { nil }
    end

    trait :in_capture_chain do
      capture_chain { { "row" => 4, "col" => 3 } }
    end

    trait :finished do
      status { :finished }
      winner { 1 }
    end
  end
end
