class Move
  attr_reader :piece, :board

  def initialize(board, piece)
    @piece = piece
    @board = board
  end

  def legal?
    new_pos = self.execute
    legal = !board.self_in_check?(new_pos)
    self.reverse
    return legal
  end

  def execute; end
  def reverse; end
end

class SimpleMove < Move; end

class ComplexMove < Move
  private attr_accessor :moves

  def initialize(board, piece, *moves)
    super(board, piece)
    @moves = moves
  end

  def execute
    @moves.each { |move| move.execute }
  end

  def reverse
    @moves.reverse_each { |move| move.reverse }
  end
end

class StandardMove < SimpleMove
  private attr_accessor :start, :end

  def initialize(board, piece, endp)
    super(board, piece)
    @end = endp.clone
  end

  def execute
    @start = @piece.position.clone
    @board.overwrite(@end, @piece)
    @board.overwrite(@start,nil)
    @piece.num_moves += 1
    return @end.clone
  end

  def reverse
    @board.overwrite(@start, @piece)
    @board.overwrite(@end,nil)
    @piece.num_moves -= 1
    return @start
  end
end

class CapturingMove < SimpleMove
  private attr_accessor :target, :start, :end

  def initialize (board, piece, target)
    super(board, piece)
    @target = target
    @start = piece.position.clone
    @end = target.position.clone
  end

  def execute
    @board.delete_piece(@target.position)
    @board.overwrite(@start, nil)
    @board.overwrite(@end, @piece)
    @piece.num_moves += 1
    return @end.clone
  end

  def legal?
    return true if @target.class == King
    super
  end

  def reverse
    @board.overwrite(@start, @piece)
    @piece.num_moves -= 1
    @board.new_piece(@end, @target)
    return @start
  end
end

class PromotingMove < SimpleMove
  private attr_accessor :new_queen
  def initialize(board, pawn)
    super(board, pawn)
  end

  def execute
    new_queen = Queen.new(board, @piece.color, @piece.position.clone)
    @board.delete_piece(@piece.position)
    @board.new_piece(@piece.position, new_queen)
    return @piece.position.clone
  end

  def reverse
    @board.delete_piece(@piece.position)
    @board.new_piece(@piece.position, @piece)
    return @piece.position
  end
end

class EnPassantIndicate < SimpleMove
  def initialize(pawn)
    super(nil, pawn)
  end

  def execute
    @piece.en_passant_capturable = true
    return @piece.position.clone
  end

  def reverse
    @piece.en_passant_capturable = false
    return @piece.position
  end
end

class CastlingMove < ComplexMove
  def initialize(board, rook, king)
    if rook.position.col < king.position.col
      king_end = Coordinate.new(king.position.col - 2, king.position.row)
      rook_end = Coordinate.new(king.position.col - 1, king.position.row) 
    else
      king_end = Coordinate.new(king.position.col + 2, king.position.row)
      rook_end = Coordinate.new(king.position.col + 1, king.position.row) 
    end

    move_rook = StandardMove.new(board, rook, rook_end)
    move_king = StandardMove.new(board, king, king_end)

    super(board, rook, move_rook, move_king)
  end
end

class EnPassantMove < ComplexMove
  def initialize(board, pawn)
    upwards = pawn.color == :black ? -2 : 2

    move_pawn = StandardMove.new(board, pawn, Coordinate.new(pawn.position.col, pawn.position.row + upwards))
    indicate_pawn = EnPassantIndicate.new(pawn)

    super(board, pawn, move_pawn, indicate_pawn)
  end
end

class EnPassantCapture < ComplexMove
  def initialize(board, pawn, target_pawn)
    upwards = pawn.color == :black ? -1 : 1

    capture_target = CapturingMove.new(board, pawn, target_pawn)
    move_up = StandardMove.new(board, pawn, Coordinate.new(target_pawn.position.col, target_pawn.position.row + upwards))

    super(board, pawn, capture_target, move_up)
  end
end

class CaptureAndPromote < ComplexMove
  def initialize(board, pawn, target)
    end_row = pawn.color == :black ? 0 : 7
    capture_target = CapturingMove.new(board, pawn, target)
    promote = PromotingMove.new(board, pawn)

    super(board, pawn, capture_target, promote)
  end
end

class MoveAndPromote < ComplexMove
  def initialize(board, pawn, endp)
    end_row = pawn.color == :black ? 0 : 7
    move = StandardMove.new(board, pawn, endp)
    promote = PromotingMove.new(board, pawn)

    super(board, pawn, move, promote)
  end
end
