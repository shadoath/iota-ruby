module Config
  def default_colors
    [:red, :green, :blue, :yellow]
  end
  def default_shapes
    [:square, :triangle, :circle, :cross]
  end
  def default_numbers
    [1, 2, 3, 4]
    end
end

class Game
  attr_accessor :players, :board, :current_player, :moves
  def initialize(colors = Config.default_colors, shapes = Config.default_shapes, numbers = Config.default_numbers)
    @players = []
    @board = Board.new
    @current_player = nil
    @moves = []
    @cards = create_cards(colors, shapes, numbers)
  end

  def create_cards(colors, shapes, numbers)
    cards = []
    colors.each do |color|
      shapes.each do |shape|
        numbers.each do |number|
          cards << Card.new(color, shape, number)
        end
      end
    end  
    5.times do
      cards.shuffle!
    end
    return cards
  end

  def add_player(name)
    @players << Player.new(name)
  end

  
  # Draws up to 4 cards for the player to play
  def draw_cards(player)
    player.hand << @cards.pop until player.hand.length == 4
  end

  def start_game()
    @current_player = @players.first
    @players.each do |player|
      draw_cards(player)
    end
    @board[0, 0] = {player_id: nil, card: @cards.pop}

  end

  def play(player, moves)
    moves.each do |move|
      play_card(player, move)
    end
  end

  def play_card(player, move)
    @board[move.row, move.column] = {player_id: player.id, card: move.card}
    # TODO: validate move
    # if error remove card from board


  end
end

class Move
  attr_accessor :player_id, :row, :column, :card
  def initialize(player_id, row, column, card)
      @player_id = player_id
      @row = row
      @column = column
      @card = card
  end
end

class Card
  attr_accessor :color, :shape, :number, :wild
  def initialize(color, shape, number, wild = false)
      @color = color
      @shape = shape
      @number = number
      @wild = wild
  end

  def to_s
      "#{@color} #{@shape} #{@number} #{@wild}"
  end
end

class Board
  attr_accessor :board
  def initialize
      @board = {}
  end

  def validate_board
    # TODO
  end

  def validate_move(move)
    # TODO
  end
end

class Player
  attr_accessor :name, :score, :hand
  def initialize(name)
      @name = name
      @score = 0
      @hand = []
  end
end
