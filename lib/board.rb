require_relative './coordinate.rb'
require_relative "./piece.rb"
require_relative "./move.rb"
require 'set'

class Board
  protected attr_accessor :black_team, :white_team

  public
  def initialize
    reset_board
  end

  def reset_board
    @grid = Array.new(8) { Array.new (8) }
    @black_team = Set[]
    @white_team = Set[]

    bk_pos = Coordinate.new(4,7)
    wk_pos = Coordinate.new(4,0)
    @black_king = King.new(:black, bk_pos)
    @white_king = King.new(:white, wk_pos)
    new_piece(bk_pos, @black_king)
    new_piece(wk_pos, @white_king)

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

  def index_cartesian(pos)
    raise IndexError unless pos.valid?
    @grid[pos.row][pos.col]
  end

  def overwrite(position, piece)
    @grid[position.row][position.col] = piece
    piece.position.col = position.col
    piece.position.row = position.row
  end

  def new_piece(position, piece)
    overwrite(position, piece)
    @black_team << piece if piece.color == :black
    @white_team << piece if piece.color == :white
  end

  class PieceFactory
    def initialize(board)
      @board = board
    end

    def create_piece(piece, position); end
  end

  class PawnFactory < PieceFactory
    def create_piece(color, position)
      piece = Pawn.new(color)
      @board.new_piece(position, piece)
    end
  end
  
  class RookFactory < PieceFactory
    def create_piece(color, position)
      piece = Rook.new(color)
      @board.new_piece(position, piece)
    end
  end
  
  class KnightFactory < PieceFactory
    def create_piece(color, position)
      piece = Knight.new(color)
      @board.new_piece(position, piece)
    end
  end
  
  class BishopFactory < PieceFactory
    def create_piece(color, position)
      piece = Bishop.new(color)
      @board.new_piece(position, piece)
    end
  end
  
  class QueenFactory < PieceFactory
    def create_piece(color, position)
      piece = Queen.new(color)
      @board.new_piece(position, piece)
    end
  end
end
