require_relative './coordinate.rb'

class BoardDisplay
  def initialize(board)
    @board = board
  end

  def display(*highlights)
    7.downto 0 do |row|
      0.upto 7 do |col|
        is_dark = (row + col) % 2 == 0
        color = is_dark ? "238" : "243"

        coordinate = Coordinate.new(col, row)
        pos = coordinate.to_algebraic()
        highlight = highlights.find {|highlight| highlight.positions.include?(pos)}
        color = is_dark ? "#{highlight.dark_color}" : "#{highlight.light_color}" if highlight

        piece = @board.index_cartesian(coordinate)
        piece_str = piece != nil ? piece.to_s : " "
        print "\033[48;5;#{color}m #{piece_str} \e[0m"
      end
      print "\n"
    end
    print "\n"
  end
end

class Highlight 
  attr_reader :positions, :dark_color, :light_color

  def initialize(positions, dark_color, light_color)
    @positions = positions
    @dark_color = dark_color
    @light_color = light_color
  end
end
