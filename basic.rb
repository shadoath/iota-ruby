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
    Config::DEFAULT_WILD_CARDS.times do
      cards << Card.new(:nil, :nil, :nil, true)
    end

    5.times do
      cards.shuffle!
    end
    return cards
  end

  def add_player(name)
    player = Player.new(name)
    @players << player
    player
  end

  
  # Draws up to 4 cards for the player
  def draw_cards(player)
    player.hand << @cards.pop until player.hand.length == 4
  end

  def start_game()
    @current_player = @players.first
    @players.each do |player|
      draw_cards(player)
    end
    # Draw first card, return card and redraw if wild
    first_card = @cards.pop
    while first_card.wild
      @cards.push(first_card)
      @cards.shuffle!
      first_card = @cards.pop
    end
    puts "First card: #{first_card}"
    @board.add_card(0, 0, first_card, "")
  end

  def play(player, moves)
    puts "#{player.name} plays #{moves}"
    moves.each do |move|
      @board.add_card(move[:row], move[:column], move[:card], player.name)
    end
    if @board.valid?()
      # Update player score
      score = @board.get_score(moves)
      player.score += score
    else
      puts "Invalid move"
      moves.each do |move|
        @board.remove_card(move[:row], move[:column])
      end
      # undo move
    end
  end

end

class Lot
  attr_reader :cards

  def initialize(cards = [])
    @cards = cards
  end

  # Validate that the cards form a valid line
  def validate
    return true unless cards.length < 2
    validate_lot(cards)
  end

  # Validate two intersecting lots
  def validate_intersection(other_lot)
    # Find the intersecting card
    intersecting_card = (cards & other_lot.cards).first

    # If no intersection or multiple intersections, it's invalid
    return true unless intersecting_card

    # Temporarily assign values to wild cards based on this lot's rules
    define_wild_cards!

    # Validate both lines independently, ensuring the intersecting card satisfies both
    result = validate_lot(cards) && validate_lot(other_lot.cards)

    # Reset wild cards after validation to allow for future flexibility
    reset_wild_cards!

    result
  end

  private

  # Check if a line of cards follows the rules
  def validate_lot(cards)
    [:color, :shape, :number].all? { |property| same_or_different?(cards, property) }
  end

  # Check if the property is either all the same or all different
  def same_or_different?(cards, property)
    values = cards.map do |card|
      if card.wild && card.instance_variable_get("@#{property}").nil?
        :any
      else
        card.send(property)
      end
    end
    non_wild_values = values.reject { |value| value == :any }

    # Wild cards can fit into any rule
    non_wild_values.uniq.size == 1 || non_wild_values.uniq.size == non_wild_values.size
  end

  # Define wild card properties based on known cards in the lot
  def define_wild_cards!
    [:color, :shape, :number].each do |property|
      known_values = cards.reject(&:wild).map { |card| card.send(property) }.uniq

      # If exactly one value is required to satisfy "all same," assign it
      if known_values.size == 1
        cards.select(&:wild).each { |card| card.define_property(property, known_values.first) }
      end
    end
  end

  # Reset wild cards to be undefined
  def reset_wild_cards!
    cards.select(&:wild).each(&:reset_properties)
  end
end

class Card
  attr_accessor :color, :shape, :number, :wild

  def initialize(color, shape, number, wild = false)
    @color = color
    @shape = shape
    @number = number
    @wild = wild
    @defined_properties = {}
  end

  # Dynamically define a property for the wild card
  def define_property(property, value)
    return unless wild
    @defined_properties[property] = value
    instance_variable_set("@#{property}", value)
  end

  # Reset all properties to undefined
  def reset_properties
    return unless wild
    @defined_properties.each_key do |property|
      instance_variable_set("@#{property}", nil)
    end
    @defined_properties.clear
  end

  def to_s
    if @wild
      "WILD"
    else
      "#{@color} #{@shape} #{@number}"
    end
  end
end

# Board: Dictionary of rows and columns with cards and who played them
class Board
  attr_accessor :board, :moves
  def initialize
    @board = {}
    @moves = []
  end

  def get_score(moves)
    total_score = 0
    segments = [] # To track all unique connected segments

    moves.each do |move|
      row_segments = get_connected_segment(move[:row], move[:column], :row)
      col_segments = get_connected_segment(move[:row], move[:column], :column)

      segments += row_segments + col_segments
    end

    # Calculate score for each unique segment
    segments.sum do |move| 
      total_score += move[:card].number || 0
    end

    segments.each do |segment|
      # TODO: allow max segment size to be configurable
      if segment.size == 4
        total_score = total_score * 2
      end
    end


    total_score
  end

  def add_card(row, column, card, player_name)
    @board[row] ||= {}
    @board[row][column] = { player_name: player_name, card: card }
    @moves << { row: row, column: column, player_name: player_name, card: card }
  end

  def remove_card(row, column)
    prior_move = @moves.find_index do |move| 
      move[:row] == row && move[:column] == column
    end

    if prior_move
      moves.delete_at(prior_move)
      @board[row] ||= {}
      @board[row].delete(column)
    else
      puts "Move not found"
    end
  end

  def valid?
    feedback = { rows: {}, columns: {}, intersections: [] }
    all_valid = true

    # Validate all rows
    extract_row_lots.each_with_index do |row_lots, row_index|
      row_lots.each_with_index do |lot, lot_index|
        unless validate_lot(lot)
          all_valid = false
          feedback[:rows][row_index] ||= []
          feedback[:rows][row_index] << { lot_index: lot_index, cards: lot, error: "Invalid lot in row #{row_index}" }
        end
      end
    end

    # Validate all columns
    extract_column_lots.each_with_index do |column_lots, col_index|
      column_lots.each_with_index do |lot, lot_index|
        unless validate_lot(lot)
          all_valid = false
          feedback[:columns][col_index] ||= []
          feedback[:columns][col_index] << { lot_index: lot_index, cards: lot, error: "Invalid lot in column #{col_index}" }
        end
      end
    end

    # Validate intersections
    extract_row_lots.each_with_index do |row_lots, row_index|
      row_lots.each_with_index do |row_lot, row_lot_index|
        extract_column_lots.each_with_index do |col_lots, col_index|
          col_lots.each_with_index do |col_lot, col_lot_index|
            if intersecting_card?(row_lot, col_lot) && !validate_intersection(row_lot, col_lot)
              all_valid = false
              feedback[:intersections] << {
                row: row_index,
                column: col_index,
                row_lot_index: row_lot_index,
                col_lot_index: col_lot_index,
                error: "Invalid intersection at row #{row_index}, column #{col_index}"
              }
            end
          end
        end
      end
    end

    if all_valid
      puts "Board is valid."
    else
      puts "Board is invalid. Detailed feedback:"
      puts feedback
    end

    all_valid
  end

  # Print the board in a table format using | to separate columns and - to separate rows
  def to_s
    @board.map do |row_index, row|
      row.map do |col_index, data|
        "#{data[:card]} #{data[:player_name]}"
      end.join(" | ")
    end
  end

  private

  # Extract all connected row lots (segments without gaps)
  def extract_row_lots
    @board.keys.sort.map do |row_index|
      row = @board[row_index]
      next unless row

      # Split the row into connected segments
      connected_segments(row.keys.sort).map do |segment|
        segment.map { |col_index| row[col_index][:card] }
      end
    end.compact
  end

  # Extract all connected column lots (segments without gaps)
  def extract_column_lots
    # Transpose the board: Collect cards column by column
    column_cards = {}

    @board.each do |row_index, row|
      row.each do |col_index, data|
        column_cards[col_index] ||= {}
        column_cards[col_index][row_index] = data[:card]
      end
    end

    # Sort columns and split into connected segments
    column_cards.keys.sort.map do |col_index|
      column = column_cards[col_index]

      connected_segments(column.keys.sort).map do |segment|
        segment.map { |row_index| column[row_index] }
      end
    end
  end

  # Split a sorted array of indices into connected segments
  def connected_segments(indices)
    segments = []
    current_segment = []

    indices.each_with_index do |index, i|
      if current_segment.empty? || index == current_segment.last + 1
        current_segment << index
      else
        segments << current_segment
        current_segment = [index]
      end
    end

    segments << current_segment unless current_segment.empty?
    segments
  end

  # Validate a single lot (connected segment of cards)
  def validate_lot(cards)
    return true if cards.size <= 2 # One or two cards are always valid
    lot = Lot.new(cards)
    lot.validate
  end

  # Check if two lots intersect
  def intersecting_card?(row_lot, col_lot)
    !(row_lot & col_lot).empty?
  end

  # Validate the intersection of a row lot and a column lot
  def validate_intersection(row_lot, col_lot)
    row_lot_obj = Lot.new(row_lot)

    col_lot_obj = Lot.new(col_lot)
    row_lot_obj.validate_intersection(col_lot_obj)
  end

  # Get all connected cards in a row or column segment
  def get_connected_segment(row, column, direction)
    segment = []
    case direction
    when :row
      # Traverse left
      current_col = column
      while @board[row]&.key?(current_col - 1)
        segment.push({ row: row, column: current_col - 1, card: @board[row][current_col - 1][:card] })
        current_col -= 1
      end

      # Traverse right
      current_col = column
      while @board[row]&.key?(current_col + 1)
        segment.push({ row: row, column: current_col + 1, card: @board[row][current_col + 1][:card] })
        current_col += 1
      end
    when :column
      # Traverse up
      current_row = row
      while @board[current_row - 1]&.key?(column)
        segment.push({ row: current_row - 1, column: column, card: @board[current_row - 1][column][:card] })
        current_row -= 1
      end

      # Traverse down
      current_row = row
      while @board[current_row + 1]&.key?(column)
        segment.push({ row: current_row + 1, column: column, card: @board[current_row + 1][column][:card] })
        current_row += 1
      end
    end

    # Include the current move's card
    segment.push({ row: row, column: column, card: @board[row][column][:card] }) if segment.length > 0 

    segment
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
      "#{@name} score: #{@score}, cards: #{@hand}"
  end
end

g = Game.new
p1 = g.add_player("Player 1")
p2 = g.add_player("Player 2")

g.start_game()

g.play(p1, [{row:1,column:0, card: p1.hand[0]}])
g.play(p2, [{row:0,column:1, card: p2.hand[0]}])
g.play(p1, [{row:1,column:1, card: p2.hand[0]}])
g.play(p1, [{row:1,column:2, card: p2.hand[0]}])
puts g.board
g.play(p1, [{row:1,column:3, card: p2.hand[0]}])
puts g.players