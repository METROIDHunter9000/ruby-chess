require_relative './coordinate.rb'
require_relative "./piece.rb"
require_relative "./move.rb"
require 'set'

class Board
  protected attr_accessor :teams
  private attr_accessor :kings

  private
  def get_team(color)
    return self.teams[color] if color == :white or color == :black
    raise ArgumentError.new("Unrecognized color #{color}")
  end

  def get_enemy_king(color)
    if color == :white
      return self.kings[:black]
    elsif color == :black
      return self.kings[:white]
    else
      raise ArgumentError.new("Unrecognized color #{color}")
    end
  end

  def get_king(color)
    return self.kings[color] if color == :white or color == :black
    raise ArgumentError.new("Unrecognized color #{color}")
  end

  public
  def initialize
    reset_board!
  end

  def self.new_blank
    board = Board.new
    return board
  end

  def self.new_standard
    board = Board.new
    board.populate_board!
    return board
  end

  def reset_board!
    @grid = Array.new(8) { Array.new (8) }
    self.teams = {white: Set[], black: Set[]}
    self.kings = {white: nil, black: nil}
  end

  def populate_board!
    black_king = King.new(self, :black)
    white_king = King.new(self, :white)
    new_piece(Coordinate.new(4,7), black_king)
    new_piece(Coordinate.new(4,0), white_king)

    queen_ftry = QueenFactory.new(self)
    pawn_ftry = PawnFactory.new(self)
    rook_ftry = RookFactory.new(self)
    kn_ftry = KnightFactory.new(self)
    bshp_ftry = BishopFactory.new(self)

    queen_ftry.create_piece(:black, Coordinate.new(3,7))
    queen_ftry.create_piece(:white, Coordinate.new(3,0))
    bshp_ftry.create_piece(:black, Coordinate.new(2,7))
    bshp_ftry.create_piece(:black, Coordinate.new(5,7))
    bshp_ftry.create_piece(:white, Coordinate.new(2,0))
    bshp_ftry.create_piece(:white, Coordinate.new(5,0))
    kn_ftry.create_piece(:black, Coordinate.new(1,7))
    kn_ftry.create_piece(:black, Coordinate.new(6,7))
    kn_ftry.create_piece(:white, Coordinate.new(1,0))
    kn_ftry.create_piece(:white, Coordinate.new(6,0))
    rook_ftry.create_piece(:black, Coordinate.new(0,7))
    rook_ftry.create_piece(:black, Coordinate.new(7,7))
    rook_ftry.create_piece(:white, Coordinate.new(0,0))
    rook_ftry.create_piece(:white, Coordinate.new(7,0))

    0.upto 7 do |col|
      pawn_ftry.create_piece(:white, Coordinate.new(col, 1))
      pawn_ftry.create_piece(:black, Coordinate.new(col, 6))
    end

  end

  def index_algebraic(code)
    index_cartesian(Coordinate.from_algebraic(code))
  end

  def index_cartesian(coord)
    raise IndexError.new("Coordinate provided is out of bounds") unless coord.valid?
    @grid[coord.row][coord.col]
  end

  def overwrite(position, piece)
    @grid[position.row][position.col] = piece
    piece.position.col = position.col if piece
    piece.position.row = position.row if piece
  end

  def new_piece(position, piece)
    piece.is_captured = false
    overwrite(position, piece)
    self.teams[piece.color] << piece

    if piece.class == King
      raise RuntimeError.new "Cannot create a second #{piece.color} King!" if self.kings[piece.color]
      self.kings[piece.color] = piece
    end
  end

  def delete_piece(position)
    piece = index_cartesian(position)
    raise ArgumentError.new("Cannot capture a king!") if piece.class == King

    piece.is_captured = true
    self.teams[piece.color].delete(piece)
    overwrite(position, nil)
  end

  def each_piece(color)
    get_team(color).each { |piece| yield(piece) }
  end

  def pieces_attacking(color, position)
    position_algebraic = position.class == Coordinate ? position.to_algebraic : position
    position = position.class == Coordinate ? position : Coordinate.from_algebraic(position)
    opposite_color = color == :white ? :black : :white
    decoy = Rook.new(self, opposite_color)
    original = index_algebraic(position_algebraic)

    pieces = Array.new
    overwrite(position, decoy)
    each_piece(color) do |piece|
      pieces << piece if piece.valid_moves.include? position_algebraic
    end
    overwrite(position, original)
    return pieces
  end

  def piece_attacking?(color, position)
    position_algebraic = position.class == Coordinate ? position.to_algebraic : position
    position = position.class == Coordinate ? position : Coordinate.from_algebraic(position)
    opposite_color = color == :white ? :black : :white
    decoy = Rook.new(self, opposite_color)
    original = index_algebraic(position_algebraic)
    overwrite(position, decoy)
    each_piece(color) do |piece|
      if piece.valid_moves.include? position_algebraic
        overwrite(position, original)
        return true
      end
    end
    overwrite(position, original)
    return false
  end

  def self_in_check?(position)
    piece = index_cartesian(position)
    king = get_king(piece.color)
    enemy_king = get_enemy_king(piece.color)
    return piece_attacking?(enemy_king.color, king.position)
  end

  def enemy_in_check(color)
    king = get_king(color)
    enemy_king = get_enemy_king(color)
    return pieces_attacking(color, enemy_king.position)
  end

  def player_in_mate?(color)
    each_piece(color) do |piece|
      return false if piece.valid_moves.reject {|pos, move| !move.legal?}.length > 0
    end
    return true 
  end

  class PieceFactory
    def initialize(board)
      @board = board
    end

    def create_piece(piece, position); end
  end

  class PawnFactory < PieceFactory
    def create_piece(color, position)
      piece = Pawn.new(@board, color)
      @board.new_piece(position, piece)
    end
  end
  
  class RookFactory < PieceFactory
    def create_piece(color, position)
      piece = Rook.new(@board, color)
      @board.new_piece(position, piece)
    end
  end
  
  class KnightFactory < PieceFactory
    def create_piece(color, position)
      piece = Knight.new(@board, color)
      @board.new_piece(position, piece)
    end
  end
  
  class BishopFactory < PieceFactory
    def create_piece(color, position)
      piece = Bishop.new(@board, color)
      @board.new_piece(position, piece)
    end
  end
  
  class QueenFactory < PieceFactory
    def create_piece(color, position)
      piece = Queen.new(@board, color)
      @board.new_piece(position, piece)
    end
  end
end
