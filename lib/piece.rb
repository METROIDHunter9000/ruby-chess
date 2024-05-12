require_relative './coordinate.rb'

ANSI_ESCAPE_FOREGROUND_BLACK = "\033[38;5;0m".freeze

class Piece
  attr_reader :color, :icon, :position, :num_moves, :is_captured

  protected
  def initialize(color, position = Coordinate.new)
    @color = color
    @position = position
    @num_moves = 0
    @is_captured = false
  end

  public
  def valid_moves(board, pos); end

  def to_s 
    "#{icon}"
  end
end

class Rook < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♖" if color == :black
    @icon = "♜" if color == :white
  end

  def valid_moves(board, pos)
  end
end 

class Bishop < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♗" if color == :black
    @icon = "♝" if color == :white
  end

  def valid_moves(board, pos)
  end
end 

class Knight < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♞" if color == :black
    @icon = "♘" if color == :white
  end

  def valid_moves(board, pos)
  end
end 

class Pawn < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♟" if color == :black
    @icon = "♙" if color == :white
  end

  def valid_moves(board, pos)
  end
end 

class King < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♚" if color == :black
    @icon = "♔" if color == :white
  end

  def valid_moves(board, pos)
  end
end 

class Queen < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♛" if color == :black
    @icon = "♕" if color == :white
  end

  def valid_moves(board, pos)
  end
end 
