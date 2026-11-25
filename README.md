# Checkers API

API REST JSON de um jogo de damas para dois jogadores, feita em Ruby on Rails.

## Stack

- Ruby 3.3.0 · Rails 8.0 (modo API) · SQLite
- `jsonapi-serializer` para as respostas, `draper` para a visualização do tabuleiro
- RSpec + FactoryBot para os testes

## Como rodar

```bash
bin/setup --skip-server   # instala as gems e prepara o banco
bin/rails server          # http://localhost:3000
```

## Testes

```bash
bundle exec rspec                                     # suíte completa
bundle exec rspec spec/controllers                    # testes de integração da API
bundle exec rspec spec/services/checker/rules/capture_spec.rb:49   # um teste específico (pela linha)
bin/rubocop                                           # lint
```

- `spec/services` e `spec/models`: testes de unidade das regras e serviços.
- `spec/controllers`: testes de integração que passam pela API de verdade (rotas, autenticação, serviços e banco), sem stubs.

## Endpoints

Todas as rotas ficam em `/api/v1/games`. Com exceção da criação, todas exigem o header
`Authorization: Bearer <token>` com o token de um dos jogadores da partida.

| Método | Rota | Descrição |
|---|---|---|
| `POST` | `/api/v1/games` | Cria a partida (quem cria é o player 1) |
| `POST` | `/api/v1/games/:id/join` | Entra na partida como player 2 |
| `GET` | `/api/v1/games/:id/board` | Estado atual do tabuleiro |
| `GET` | `/api/v1/games/:id/status` | Status da partida |
| `GET` | `/api/v1/games/:id/valid_moves?from[row]=2&from[col]=1` | Movimentos possíveis de uma peça |
| `POST` | `/api/v1/games/:id/move` | Move uma peça |

### Exemplos

**Criar partida:** devolve o `id` e os tokens dos dois jogadores. O player 1 guarda o seu e envia o `player_2_token` para o oponente.

```json
POST /api/v1/games

{ "data": { "id": "1", "type": "create_game", "attributes": {
  "id": 1, "player_1_token": "MT1QMNpc...", "player_2_token": "2anY31hx...", "status": "waiting_for_player" } } }
```

**Entrar na partida:** `POST /api/v1/games/1/join` com o token do player 2.

**Status:** pode ser `waiting for opponent`, `player_1 turn`, `player_2 turn`, `player_1 won` ou `player_2 won`.

```json
GET /api/v1/games/1/status

{ "data": { "id": "1", "type": "game_status", "attributes": { "id": 1, "status": "player_1 turn" } } }
```

**Tabuleiro:** `board_view` desenha o tabuleiro. `p1`/`p2` são peões e `P1`/`P2` são damas.

```json
GET /api/v1/games/1/board

{ "data": { "id": "1", "type": "board_game", "attributes": {
  "id": 1, "current_turn": "player_1", "status": "in_progress", "winner": null,
  "board_view": [
    "    0    1    2    3    4    5    6    7 ",
    "  +----+----+----+----+----+----+----+----+",
    "0 | __ | p1 | __ | p1 | __ | p1 | __ | p1 |",
    "1 | p1 | __ | p1 | __ | p1 | __ | p1 | __ |",
    "2 | __ | p1 | __ | p1 | __ | p1 | __ | p1 |",
    "3 | __ | __ | __ | __ | __ | __ | __ | __ |",
    "4 | __ | __ | __ | __ | __ | __ | __ | __ |",
    "5 | p2 | __ | p2 | __ | p2 | __ | p2 | __ |",
    "6 | __ | p2 | __ | p2 | __ | p2 | __ | p2 |",
    "7 | p2 | __ | p2 | __ | p2 | __ | p2 | __ |",
    "  +----+----+----+----+----+----+----+----+" ] } } }
```

**Movimentos válidos de uma peça**

```json
GET /api/v1/games/1/valid_moves?from[row]=2&from[col]=1

{ "data": { "id": "1", "type": "valid_moves", "attributes": {
  "id": 1, "from": { "row": 2, "col": 1 },
  "valid_moves": [
    { "to": { "row": 3, "col": 0 }, "capture": false },
    { "to": { "row": 3, "col": 2 }, "capture": false } ] } } }
```

**Mover:** responde com o turno, o status e o tabuleiro atualizado.

```json
POST /api/v1/games/1/move
{ "from": { "row": 2, "col": 1 }, "to": { "row": 3, "col": 2 } }
```

### Erros

Os erros são devolvidos como `{ "error": "mensagem" }`.

| Código | Quando |
|---|---|
| `401` | Token ausente ou que não pertence à partida |
| `403` | Tentar entrar na partida com um token que não é o do player 2 |
| `404` | Partida inexistente |
| `422` | Regra do jogo violada (movimento inválido, turno errado, peça do adversário, partida já iniciada...) |

## Regras implementadas

- Tabuleiro 8x8. O player 1 começa nas linhas 0 a 2 e anda para baixo; o player 2 começa nas linhas 5 a 7 e anda para cima. O player 1 começa jogando.
- O peão anda uma casa na diagonal para frente e **captura para frente e para trás** (regra brasileira).
- O peão que chega à última linha vira **dama**. A dama é "voadora": anda e captura a qualquer distância na diagonal, desde que o caminho esteja livre e haja exatamente uma peça adversária a capturar.
- **Captura em cadeia:** se, depois de uma captura, a mesma peça puder capturar de novo, o turno continua com ela. Até a cadeia terminar, só essa peça pode jogar, e só capturando.
- A partida termina quando um jogador fica sem peças. O adversário dele vence.

## Decisões e simplificações

- **Tokens:** gerados com `SecureRandom.urlsafe_base64(32)` e comparados com `secure_compare`, o que os torna difíceis de adivinhar. Não há cadastro nem login, e sem o token não é possível acessar nenhuma informação da partida.
- **Captura não obrigatória:** a regra brasileira obriga a capturar e a escolher a sequência que captura mais peças (lei da maioria). Aqui a captura é opcional.
- **Fim de jogo:** só é detectado quando um jogador fica sem peças. Um jogador sem movimentos possíveis não perde automaticamente, e o empate não é detectado. O valor `draw` foi mantido no enum `winner` para uma evolução futura.
- **Arquitetura:** o controller só autentica e delega. O `Checker::MoveService` aplica a jogada, e o `Checker::GameRulesService` valida o movimento combinando regras pequenas e independentes, em `app/services/checker/rules` (`Preconditions`, `Movement`, `Capture`, `ChainCapture`, `End`). O tabuleiro é guardado em JSON na própria partida.

## Cenários para testes manuais

Para não precisar jogar uma partida inteira até chegar a uma situação específica, existem cenários prontos. Eles substituem o tabuleiro de uma partida existente:

```bash
bin/rails scenarios:list                         # lista os cenários (cadeia_dama, fim_de_jogo_peao, ...)
bin/rails "scenarios:load[1,cadeia_dama]"        # aplica o cenário na partida 1 e mostra o que enviar em cada passo
bin/rails scenarios:play_all                     # confere se todos os cenários se comportam como esperado
```
