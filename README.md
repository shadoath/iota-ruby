# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

- Ruby version

- System dependencies

- Configuration

- Database creation

- Database initialization

- How to run the test suite

- Services (job queues, cache servers, search engines, etc.)

- Deployment instructions

- ...

Cards (66)

- Numbers: 1, 2, 3, 4
- Colors: Red, Green, Blue, Yellow
- Shapes: Square, Triangle, Circle, Cross
- Plus two Wild cards

Game:

- Players[]
  - Name
  - Score
  - CurrentCards[]
  - Hand[]
- Board (Dictionary)
  - Key [Row, Column]
  - Value [Card | nil]
- Cards[]
- Current Player
- Moves[]
  - Player
  - Moves[]

Board:

- Dictionary
  - Key [Row, Column]
  - Value [Card | nil]

API:

- /cards

  - GET

- ## /game
  - /play
    - POST
    - Body
      - Player
      - Moves[]
        - row
        - column
        - card
          - color
          - shape
          - number
          - wild?
  - /draw-cards
    - GET
    - Body
      - player
  - /load-board
    - GET
    - Body
      - player
  - /
- /board
