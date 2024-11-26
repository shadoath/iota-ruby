module Config
  DEFAULT_COLORS = [:red, :green, :blue, :yellow]
  DEFAULT_SHAPES = [:square, :triangle, :circle, :cross]
  DEFAULT_NUMBERS = [1, 2, 3, 4]
  DEFAULT_WILD_CARDS = 2
end

class Game
  attr_accessor :players, :board, :current_player
  def initialize(colors = Config::DEFAULT_COLORS, shapes = Config::DEFAULT_SHAPES, numbers = Config::DEFAULT_NUMBERS, players = [])
    @players = players
    @board = Board.new
    @current_player = nil
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
    # Add wild cards
    DEFAULT_WILD_CARDS.times do
      cards << Card.new(:any, :any, 0, true)
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
    first_card = @cards.pop
    puts "First card: #{first_card}"
    @board.add_card(0, 0, first_card, nil)

  end

  def play(player, moves)
    moves.each do |move|
      play_card(player, move)
    end
  end

  def play_card(player, move)
    # @board[move.row, move.column] = {player_id: player.id, card: move.card}
    @board.add_card(move.row, move.column, move.card, player.id)
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

# Board: Dictionary of rows and columns with cards and who played them
class Board
  attr_accessor :board, :moves
  def initialize
    @board = {}
    @moves = []
  end

  def add_card(row, column, card, player_id)
    @board[row] ||= {}
    @board[row][column] = {player_id: player_id, card: card}
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

  def to_s
      "#{@name}: #{@score}, cards: #{@hand}"
  end
end

g = Game.new
g.add_player("Player 1")
g.add_player("Player 2")

g.start_game()

puts g.players