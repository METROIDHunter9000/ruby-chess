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
  def valid_moves(board); end

  def to_s 
    "#{icon}"
  end
end

class Rook < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♜" if color == :black
    @icon = "♜" if color == :white
  end

  def valid_moves(board)
    direction = [[1,0],[-1,0],[0,1],[0,-1]]
    moves = Hash.new
    direction.each do |dir|
      delta = dir.clone
      loop do
        coord = Coordinate.new(self.position.col + delta[0], self.position.row + delta[1])
        break unless coord.valid?

        piece = board.index_cartesian(coord)
        if piece
          moves[coord.to_algebraic] = "capture" if piece.color != self.color
          break
        else
          moves[coord.to_algebraic] = "move"
          delta[0] += dir[0]
          delta[1] += dir[1]
        end
      end
    end
    return moves
  end
end 

class Bishop < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♝" if color == :black
    @icon = "♝" if color == :white
  end

  def valid_moves(board)
    direction = [[1,1],[-1,1],[-1,-1],[1,-1]]
    moves = Hash.new
    direction.each do |dir|
      delta = dir.clone
      loop do
        coord = Coordinate.new(self.position.col + delta[0], self.position.row + delta[1])
        break unless coord.valid?

        piece = board.index_cartesian(coord)
        if piece
          moves[coord.to_algebraic] = "capture" if piece.color != self.color
          break
        else
          moves[coord.to_algebraic] = "move"
          delta[0] += dir[0]
          delta[1] += dir[1]
        end
      end
    end
    return moves
  end
end 

class Knight < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♞" if color == :black
    @icon = "♞" if color == :white
  end

  def valid_moves(board)
    moves_relative = [[1,2],[2,1],[2,-1],[1,-2],[-1,-2],[-2,-1],[-2,1],[-1,2]]
    moves = Hash.new
    moves_relative.each do |move|
      coord = Coordinate.new(self.position.col + move[0], self.position.row + move[1])
      next unless coord.valid?
      piece = board.index_cartesian(coord)
      moves[coord.to_algebraic] = "move" unless piece
      moves[coord.to_algebraic] = "capture" if piece && piece.color != self.color
    end
    return moves
  end
end 

class Pawn < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♟" if color == :black
    @icon = "♟" if color == :white
  end

  def valid_moves(board)
    moves = Hash.new

    up = self.color == :black ? -1 : 1
    coord_up1 = Coordinate.new(self.position.col, self.position.row + up)
    coord_up2 = Coordinate.new(self.position.col, self.position.row + up*2)
    coord_upleft = Coordinate.new(self.position.col - 1, self.position.row + up)
    coord_upright = Coordinate.new(self.position.col + 1, self.position.row + up)
    moves[coord_up1.to_algebraic] = "move" if coord_up1.valid? && board.index_cartesian(coord_up1) == nil
    moves[coord_up2.to_algebraic] = "move" if coord_up2.valid? && self.num_moves == 0 && board.index_cartesian(coord_up2) == nil
    
    piece_upleft = board.index_cartesian(coord_upleft)
    piece_upright = board.index_cartesian(coord_upright)

    moves[coord_upleft.to_algebraic] = "capture" if coord_upleft.valid? && piece_upleft && piece_upleft.color != self.color
    moves[coord_upright.to_algebraic] = "capture" if coord_upright.valid? && piece_upright && piece_upright.color != self.color
    return moves
  end
end 

class King < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♚" if color == :black
    @icon = "♚" if color == :white
  end

  def valid_moves(board)
    moves_relative = [[0,1],[-1,0],[1,0],[0,-1],[-1,1],[1,1],[-1,-1],[1,-1]]
    moves = Hash.new
    moves_relative.each do |move|
      coord = Coordinate.new(self.position.col + move[0], self.position.row + move[1])
      next unless coord.valid?
      piece = board.index_cartesian(coord)
      moves[coord.to_algebraic] = "move" unless piece
      moves[coord.to_algebraic] = "capture" if piece && piece.color != self.color
    end
    return moves
  end
end 

class Queen < Piece
  public
  def initialize(color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♛" if color == :black
    @icon = "♛" if color == :white
  end

  def valid_moves(board)
    direction = [[1,0],[-1,0],[0,1],[0,-1],[-1,-1],[1,1],[-1,1],[1,-1]]
    moves = Hash.new
    direction.each do |dir|
      delta = dir.clone
      loop do
        coord = Coordinate.new(self.position.col + delta[0], self.position.row + delta[1])
        break unless coord.valid?

        piece = board.index_cartesian(coord)
        if piece
          moves[coord.to_algebraic] = "capture" if piece.color != self.color
          break
        else
          moves[coord.to_algebraic] = "move"
          delta[0] += dir[0]
          delta[1] += dir[1]
        end
      end
    end
    return moves
  end
end 
