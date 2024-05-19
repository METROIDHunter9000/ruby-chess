require_relative './coordinate.rb'
require 'pry-byebug'

ANSI_ESCAPE_FOREGROUND_BLACK = "\033[38;5;0m".freeze

class Piece
  attr_reader :color, :icon, :position, :board
  attr_accessor :num_moves, :is_captured

  protected
  def initialize(board, color, position = Coordinate.new, uncolored_icon)
    @board = board
    @color = color
    @position = position
    @num_moves = 0
    @is_captured = false
    @icon = "#{ANSI_ESCAPE_FOREGROUND_BLACK}#{uncolored_icon}" if color == :black
    @icon = uncolored_icon if color == :white
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
    super(board, color, position, "♜")
  end

  def valid_moves
    directions = [[1,0],[-1,0],[0,1],[0,-1]]
    valid_moves = Hash.new

    directions.each do |dir|
      delta = dir.clone
      places_traversed = Array.new

      loop do
        coord = Coordinate.new(self.position.col + delta[0], self.position.row + delta[1])
        break unless coord.valid?

        places_traversed << coord
        piece = @board.index(coord)
        if piece
          if piece.color != self.color
            valid_moves[coord.to_algebraic] = CapturingMove.new(@board, self, piece) 
          else
            is_my_king = piece.class == King && piece.color == self.color
            is_our_first_move = piece.num_moves == 0 && 0 == self.num_moves
            if is_our_first_move and is_my_king
              enemy_color = self.color == :black ? :white : :black
              is_move_unsafe = false
              places_traversed[-3..].each do |place|
                is_place_unsafe = @board.piece_attacking?(enemy_color, place)
                is_move_unsafe = is_move_unsafe || is_place_unsafe
              end
              valid_moves[coord.to_algebraic] = CastlingMove.new(@board, self, piece) unless is_move_unsafe
            end
          end
          break
        else
          valid_moves[coord.to_algebraic] = StandardMove.new(@board, self, coord)
          delta[0] += dir[0]
          delta[1] += dir[1]
        end
      end
    end
    return valid_moves
  end
end 

class Bishop < Piece
  public
  def initialize(board, color, position = Coordinate.new)
    super(board, color, position, "♝")
  end

  def valid_moves
    directions = [[1,1],[-1,1],[-1,-1],[1,-1]]
    valid_moves = Hash.new

    directions.each do |dir|
      delta = dir.clone

      loop do
        coord = Coordinate.new(self.position.col + delta[0], self.position.row + delta[1])
        break unless coord.valid?

        piece = @board.index(coord)
        if piece
          valid_moves[coord.to_algebraic] = CapturingMove.new(@board, self, piece) if piece.color != self.color
          break
        else
          valid_moves[coord.to_algebraic] = StandardMove.new(@board, self, coord)
          delta[0] += dir[0]
          delta[1] += dir[1]
        end
      end
    end
    return valid_moves
  end
end 

class Knight < Piece
  public
  def initialize(board, color, position = Coordinate.new)
    super(board, color, position, "♞")
  end

  def valid_moves
    moves_relative = [[1,2],[2,1],[2,-1],[1,-2],[-1,-2],[-2,-1],[-2,1],[-1,2]]
    valid_moves = Hash.new

    moves_relative.each do |move|
      coord = Coordinate.new(self.position.col + move[0], self.position.row + move[1])
      next unless coord.valid?

      piece = @board.index(coord)
      valid_moves[coord.to_algebraic] = StandardMove.new(@board, self, coord) unless piece
      valid_moves[coord.to_algebraic] = CapturingMove.new(@board, self, piece) if piece && piece.color != self.color
    end
    return valid_moves
  end
end 

class Pawn < Piece
  attr_accessor :en_passant_capturable

  public
  def initialize(board, color, position = Coordinate.new)
    super(board, color, position, "♟")
    self.en_passant_capturable = false
  end

  def valid_moves
    valid_moves = Hash.new

    up = self.color == :black ? -1 : 1
    row_end = self.color == :black ? 0 : 7

    coord_up1 = Coordinate.new(self.position.col, self.position.row + up)
    if coord_up1.valid? 
      piece_up1 = @board.index(coord_up1) 
      valid_moves[coord_up1.to_algebraic] = MoveAndPromote.new(@board, self, coord_up1) if coord_up1.row == row_end
      valid_moves[coord_up1.to_algebraic] = StandardMove.new(@board, self, coord_up1) if coord_up1.row != row_end && piece_up1 == nil
    end

    coord_up2 = Coordinate.new(self.position.col, self.position.row + up*2)
    valid_moves[coord_up2.to_algebraic] = EnPassantMove.new(@board, self) if coord_up2.valid? && self.num_moves == 0 && @board.index(coord_up2) == nil

    coord_left = Coordinate.new(self.position.col - 1, self.position.row)
    coord_right = Coordinate.new(self.position.col + 1, self.position.row)
    piece_left = @board.index(coord_left) if coord_left.valid?
    piece_right = @board.index(coord_right) if coord_right.valid?
    if piece_left && piece_left.class == Pawn && piece_left.color != self.color && piece_left.en_passant_capturable
      valid_moves[coord_left.to_algebraic] = EnPassantCapture.new(@board, self, piece_left)
    end
    if piece_right && piece_right.class == Pawn && piece_right.color != self.color && piece_right.en_passant_capturable
      valid_moves[coord_right.to_algebraic] = EnPassantCapture.new(@board, self, piece_right)
    end
    
    coord_upleft = Coordinate.new(self.position.col - 1, self.position.row + up)
    coord_upright = Coordinate.new(self.position.col + 1, self.position.row + up)
    piece_upleft = @board.index(coord_upleft) if coord_left.valid?
    piece_upright = @board.index(coord_upright) if coord_right.valid?
    if coord_upleft.valid? && piece_upleft && piece_upleft.color != self.color
      valid_moves[coord_upleft.to_algebraic] = CapturingMove.new(@board, self, piece_upleft) if coord_upleft.row != row_end
      valid_moves[coord_upleft.to_algebraic] = CaptureAndPromote.new(@board, self, piece_upleft) if coord_upleft.row == row_end
    end
    if coord_upright.valid? && piece_upright && piece_upright.color != self.color
      valid_moves[coord_upright.to_algebraic] = CapturingMove.new(@board, self, piece_upright) if coord_upright.row != row_end
      valid_moves[coord_upright.to_algebraic] = CaptureAndPromote.new(@board, self, piece_upright) if coord_upright.row == row_end
    end
    return valid_moves
  end
end 

class King < Piece
  public
  def initialize(board, color, position = Coordinate.new)
    super(board, color, position, "♚")
  end

  def valid_moves
    moves_relative = [[0,1],[-1,0],[1,0],[0,-1],[-1,1],[1,1],[-1,-1],[1,-1]]
    valid_moves = Hash.new

    moves_relative.each do |move|
      coord = Coordinate.new(self.position.col + move[0], self.position.row + move[1])
      next unless coord.valid?

      piece = @board.index(coord)
      valid_moves[coord.to_algebraic] = StandardMove.new(@board, self, coord) unless piece
      valid_moves[coord.to_algebraic] = CapturingMove.new(@board, self, piece) if piece && piece.color != self.color
    end
    return valid_moves
  end
end 

class Queen < Piece
  public
  def initialize(board, color, position = Coordinate.new)
    super(board, color, position, "♛")
  end

  def valid_moves
    directions = [[1,0],[-1,0],[0,1],[0,-1],[-1,-1],[1,1],[-1,1],[1,-1]]
    valid_moves = Hash.new

    directions.each do |dir|
      delta = dir.clone

      loop do
        coord = Coordinate.new(self.position.col + delta[0], self.position.row + delta[1])
        break unless coord.valid?

        piece = @board.index(coord)
        if piece
          valid_moves[coord.to_algebraic] = CapturingMove.new(@board, self, piece) if piece.color != self.color
          break
        else
          valid_moves[coord.to_algebraic] = StandardMove.new(@board, self, coord)
          delta[0] += dir[0]
          delta[1] += dir[1]
        end
      end
    end
    return valid_moves
  end
end 
