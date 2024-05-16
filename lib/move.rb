class Move
  attr_reader :piece, :board

  def initialize(board, piece)
    @piece = piece
    @board = board
  end

  def legal?
    new_pos = self.execute
    legal = !board.self_in_check(new_pos)
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
    raise ArgumentError.new("Cannot move to position occupied by another piece") if board.index_cartesian(endp)

    super(board, piece)
    @start = piece.position.clone
    @end = endp.clone
  end

  def execute
    @board.overwrite(@end, @piece)
    @board.overwrite(@start,nil)
    @piece.num_moves += 1
  end

  def reverse
    @board.overwrite(@start, @piece)
    @board.overwrite(@end,nil)
    @piece.num_moves -= 1
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
    @board.overwrite(@start, nil)
    @target.is_captured = true
    @board.overwrite(@end, @piece)
    @piece.num_moves += 1
  end

  def reverse
    @board.overwrite(@start, @piece)
    @piece.num_moves -= 1
    @target.is_captured = false
    @board.overwrite(@end, @target)
  end
end

class PromotingMove < SimpleMove

end

class EnPassantIndicate < SimpleMove

end

class CastlingMove < ComplexMove
  def initialize(board, rook, king)
    raise ArgumentError.new("King and Rook must be on same row (rank) for a castling move") if king.position.row != rook.position.row
    raise ArgumentError.new("King and Rook cannot castle if either piece has moved") if king.num_moves > 0 || rook.num_moves > 0

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

end

class EnPassantCapture < ComplexMove

end

class CaptureAndPromote < ComplexMove

end
