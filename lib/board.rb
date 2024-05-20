require_relative './coordinate.rb'
require_relative "./piece.rb"
require_relative "./move.rb"
require 'set'
require 'json'

class Board
  public attr_accessor :teams
  private attr_accessor :kings
  public attr_reader :factories

  private
  def get_team(color)
    return self.teams[color] if color == :white or color == :black
    raise ArgumentError.new("Unrecognized color #{color}")
  end

  public
  def initialize
    @factories = {
      Pawn: PawnFactory.new(self),
      Knight: KnightFactory.new(self),
      Rook: RookFactory.new(self),
      Bishop: BishopFactory.new(self),
      Queen: QueenFactory.new(self),
      King: KingFactory.new(self)
    }
    reset!
  end

  def to_json
    obj = Hash.new
    obj["pieces"] = self.teams[:white].map {|piece| piece.to_json}
    obj["pieces"] += self.teams[:black].map {|piece| piece.to_json}
    return obj
  end

  def self.from_json(json_obj)
    board = Board.new_blank
    json_obj["pieces"].each do |piece_obj|
      piece = board.factories[piece_obj["class"].to_sym].create_piece(piece_obj["color"].to_sym, piece_obj["position"])
      piece.num_moves = piece_obj["num_moves"]
      piece.en_passant_capturable = piece_obj["en_passant_capturable"] if piece.class == Pawn
      board.delete_piece(piece.position) if piece_obj["is_captured"]
    end
    return board
  end

  def self.new_blank
    Board.new
  end

  def self.new_standard
    Board.new.populate
  end

  def reset!
    @grid = Array.new(8) { Array.new (8) }
    self.teams = {white: Set[], black: Set[]}
    self.kings = {white: nil, black: nil}
  end

  def populate!
    black_king = King.new(self, :black)
    white_king = King.new(self, :white)
    new_piece(Coordinate.new(4,7), black_king)
    new_piece(Coordinate.new(4,0), white_king)

    self.factories[:Queen].create_piece(:black, Coordinate.new(3,7))
    self.factories[:Queen].create_piece(:white, Coordinate.new(3,0))
    self.factories[:Bishop].create_piece(:black, Coordinate.new(2,7))
    self.factories[:Bishop].create_piece(:black, Coordinate.new(5,7))
    self.factories[:Bishop].create_piece(:white, Coordinate.new(2,0))
    self.factories[:Bishop].create_piece(:white, Coordinate.new(5,0))
    self.factories[:Knight].create_piece(:black, Coordinate.new(1,7))
    self.factories[:Knight].create_piece(:black, Coordinate.new(6,7))
    self.factories[:Knight].create_piece(:white, Coordinate.new(1,0))
    self.factories[:Knight].create_piece(:white, Coordinate.new(6,0))
    self.factories[:Rook].create_piece(:black, Coordinate.new(0,7))
    self.factories[:Rook].create_piece(:black, Coordinate.new(7,7))
    self.factories[:Rook].create_piece(:white, Coordinate.new(0,0))
    self.factories[:Rook].create_piece(:white, Coordinate.new(7,0))

    0.upto 7 do |col|
      self.factories[:Pawn].create_piece(:white, Coordinate.new(col, 1))
      self.factories[:Pawn].create_piece(:black, Coordinate.new(col, 6))
    end
  end

  def populate
    self.populate!
    self
  end

  def index(pos)
    pos = Coordinate.from_algebraic(pos) if pos.class == String
    raise IndexError.new("Position provided is out of bounds") unless pos.valid?
    @grid[pos.row][pos.col]
  end

  def overwrite(pos, piece)
    pos = Coordinate.from_algebraic(pos) if pos.class == String
    @grid[pos.row][pos.col] = piece
    piece.position.col = pos.col if piece
    piece.position.row = pos.row if piece
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

  def each_piece(color)
    get_team(color).each { |piece| yield(piece) }
  end

  def new_piece(position, piece)
    if piece.class == King
      raise RuntimeError.new "Cannot create a second #{piece.color} King!" if self.kings[piece.color]
      self.kings[piece.color] = piece
    end

    piece.is_captured = false
    overwrite(position, piece)
    self.teams[piece.color] << piece
    return piece
  end

  def delete_piece(position)
    piece = index(position)
    raise ArgumentError.new("Cannot capture a king!") if piece.class == King

    piece.is_captured = true
    self.teams[piece.color].delete(piece)
    overwrite(position, nil)
  end

  def pieces_attacking(color, position)
    position = position.to_algebraic if position.class == Coordinate
    opposite_color = color == :white ? :black : :white
    decoy = Rook.new(self, opposite_color)
    original = index(position)

    pieces = Array.new
    overwrite(position, decoy)
    each_piece(color) do |piece|
      pieces << piece if piece.valid_moves.include? position
    end
    overwrite(position, original)
    return pieces
  end

  def piece_attacking?(color, position)
    position = position.to_algebraic if position.class == Coordinate
    opposite_color = color == :white ? :black : :white
    decoy = Rook.new(self, opposite_color)
    original = index(position)
    overwrite(position, decoy)
    each_piece(color) do |piece|
      if piece.valid_moves.include? position
        overwrite(position, original)
        return true
      end
    end
    overwrite(position, original)
    return false
  end

  def self_in_check?(color)
    king = get_king(color)
    enemy_king = get_enemy_king(color)
    return piece_attacking?(enemy_king.color, king.position)
  end

  def pieces_checking(color)
    king = get_king(color)
    enemy_king = get_enemy_king(color)
    return pieces_attacking(color, enemy_king.position)
  end

  def player_in_mate?(color)
    each_piece(color) do |piece|
      return false if piece.legal_moves.length > 0
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

  class KingFactory < PieceFactory
    def create_piece(color, position)
      piece = King.new(@board, color)
      @board.new_piece(position, piece)
    end
  end
end
