require_relative './coordinate.rb'

ANSI_ESCAPE_FOREGROUND_BLACK = "\033[38;5;0m".freeze

class Piece
  attr_reader :color, :icon, :position, :board
  attr_accessor :num_moves, :is_captured

  protected
  def initialize(board, color, position = Coordinate.new)
    @board = board
    @color = color
    @position = position
    @num_moves = 0
    @is_captured = false
  end

  public
  def valid_moves; end

  def to_s 
    "#{icon}"
  end
end

class Rook < Piece
  public
  def initialize(board, color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♜" if color == :black
    @icon = "♜" if color == :white
  end

  def valid_moves
    direction = [[1,0],[-1,0],[0,1],[0,-1]]
    moves = Hash.new
    direction.each do |dir|
      delta = dir.clone
      loop do
        coord = Coordinate.new(self.position.col + delta[0], self.position.row + delta[1])
        break unless coord.valid?

        piece = @board.index_cartesian(coord)
        if piece
          moves[coord.to_algebraic] = CapturingMove.new(self, self.position, coord, piece) if piece.color != self.color

          is_my_king = piece.class == King && piece.color == self.color
          is_our_first_move = piece.num_moves == 0 && 0 == self.num_moves
          moves[coord.to_algebraic] = "castle" if is_our_first_move and is_my_king
          break
        else
          moves[coord.to_algebraic] = StandardMove.new(self, self.position, coord)
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
  def initialize(board, color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♝" if color == :black
    @icon = "♝" if color == :white
  end

  def valid_moves
    direction = [[1,1],[-1,1],[-1,-1],[1,-1]]
    moves = Hash.new
    direction.each do |dir|
      delta = dir.clone
      loop do
        coord = Coordinate.new(self.position.col + delta[0], self.position.row + delta[1])
        break unless coord.valid?

        piece = @board.index_cartesian(coord)
        if piece
          moves[coord.to_algebraic] = CapturingMove.new(self, self.position, coord, piece) if piece.color != self.color
          break
        else
          moves[coord.to_algebraic] = StandardMove.new(self, self.position, coord)
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
  def initialize(board, color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♞" if color == :black
    @icon = "♞" if color == :white
  end

  def valid_moves
    moves_relative = [[1,2],[2,1],[2,-1],[1,-2],[-1,-2],[-2,-1],[-2,1],[-1,2]]
    moves = Hash.new
    moves_relative.each do |move|
      coord = Coordinate.new(self.position.col + move[0], self.position.row + move[1])
      next unless coord.valid?
      piece = @board.index_cartesian(coord)
      moves[coord.to_algebraic] = StandardMove.new(self, self.position, coord) unless piece
      moves[coord.to_algebraic] = CapturingMove.new(self, self.position, coord, piece) if piece && piece.color != self.color
    end
    return moves
  end
end 

class Pawn < Piece
  attr_reader :en_passant_moved

  public
  def initialize(board, color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♟" if color == :black
    @icon = "♟" if color == :white
    @en_passant_moved = false
  end

  def valid_moves
    moves = Hash.new

    up = self.color == :black ? -1 : 1
    row_end = self.color == :black ? 0 : 7

    coord_up1 = Coordinate.new(self.position.col, self.position.row + up)
    if coord_up1.valid? 
      piece_up1 = @board.index_cartesian(coord_up1) 
      moves[coord_up1.to_algebraic] = "promote" if coord_up1.row == row_end
      moves[coord_up1.to_algebraic] = StandardMove.new(self, self.position, coord_up1) if coord_up1.row != row_end && piece_up1 == nil
    end

    coord_up2 = Coordinate.new(self.position.col, self.position.row + up*2)
    moves[coord_up2.to_algebraic] = "en-passant move" if coord_up2.valid? && self.num_moves == 0 && @board.index_cartesian(coord_up2) == nil

    coord_left = Coordinate.new(self.position.col - 1, self.position.row)
    coord_right = Coordinate.new(self.position.col + 1, self.position.row)
    piece_left = @board.index_cartesian(coord_left)
    piece_right = @board.index_cartesian(coord_right)
    if piece_left && piece_left.class == Pawn && piece_left.color != self.color && piece_left.en_passant_moved
      moves[coord_left.to_algebraic] = "en-passant capture"
    end
    if piece_right && piece_right.class == Pawn && piece_right.color != self.color && piece_right.en_passant_moved
      moves[coord_right.to_algebraic] = "en-passant capture"
    end
    
    coord_upleft = Coordinate.new(self.position.col - 1, self.position.row + up)
    coord_upright = Coordinate.new(self.position.col + 1, self.position.row + up)
    piece_upleft = @board.index_cartesian(coord_upleft)
    piece_upright = @board.index_cartesian(coord_upright)
    if coord_upleft.valid? && piece_upleft && piece_upleft.color != self.color
      moves[coord_upleft.to_algebraic] = CapturingMove.new(self, self.position, coord_upleft, piece_upleft) if coord_upleft.row != row_end
      moves[coord_upleft.to_algebraic] = "capture and promote" if coord_upleft.row == row_end
    end
    if coord_upright.valid? && piece_upright && piece_upright.color != self.color
      moves[coord_upright.to_algebraic] = CapturingMove.new(self, self.position, coord_upright, piece_upright) if coord_upright.row != row_end
      moves[coord_upright.to_algebraic] = "capture and promote" if coord_upright.row == row_end
    end
    return moves
  end
end 

class King < Piece
  public
  def initialize(board, color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♚" if color == :black
    @icon = "♚" if color == :white
  end

  def valid_moves
    moves_relative = [[0,1],[-1,0],[1,0],[0,-1],[-1,1],[1,1],[-1,-1],[1,-1]]
    moves = Hash.new
    moves_relative.each do |move|
      coord = Coordinate.new(self.position.col + move[0], self.position.row + move[1])
      next unless coord.valid?
      piece = @board.index_cartesian(coord)
      moves[coord.to_algebraic] = StandardMove.new(self, self.position, coord) unless piece
      moves[coord.to_algebraic] = CapturingMove.new(self, self.position, coord, piece) if piece && piece.color != self.color
    end
    return moves
  end
end 

class Queen < Piece
  public
  def initialize(board, color, position = Coordinate.new)
    super
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}♛" if color == :black
    @icon = "♛" if color == :white
  end

  def valid_moves
    direction = [[1,0],[-1,0],[0,1],[0,-1],[-1,-1],[1,1],[-1,1],[1,-1]]
    moves = Hash.new
    direction.each do |dir|
      delta = dir.clone
      loop do
        coord = Coordinate.new(self.position.col + delta[0], self.position.row + delta[1])
        break unless coord.valid?

        piece = @board.index_cartesian(coord)
        if piece
          moves[coord.to_algebraic] = CapturingMove.new(self, self.position, coord, piece) if piece.color != self.color
          break
        else
          moves[coord.to_algebraic] = StandardMove.new(self, self.position, coord)
          delta[0] += dir[0]
          delta[1] += dir[1]
        end
      end
    end
    return moves
  end
end 
