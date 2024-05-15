class Move
  attr_reader :piece, :start, :end

  def initialize(piece, start, endp, board)
    @piece = piece
    @start = start.clone
    @end = endp.clone
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

class StandardMove < Move
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

class CapturingMove < Move
  attr_reader :target
  def initialize (piece, start, endp, target, board)
    super(piece, start, endp, board)
    @target = target
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

class CastlingMove < Move
  attr_reader :king
  def initialize(rook, start, king, board)
    # TODO this is causing error
    raise ArgumentError.new("King and Rook must be on same row (rank) for a castling move") if king.position.row != rook.position.row
    raise ArgumentError.new("King and Rook cannot castle if either piece has moved") if king.num_moves > 0 || rook.num_moves > 0

    endp = Coordinate.new(king.position.col - 1, king.position.row) if rook.position.col < king.position.col
    endp = Coordinate.new(king.position.col + 1, king.position.row) if rook.position.col > king.position.col

    super(rook, start, endp, board)
    @king = king
    @start_king = king.position.clone
  end

  def legal?(board)
    # Override #legal?() because this move presents as only moving the rook
    # but it actually moves rook and king
    self.execute
    legal = !board.self_in_check(@king.position)
    self.reverse
    return legal
  end

  def execute
    @board.overwrite(@start, nil)
    @board.overwrite(@start_king, nil)
    @piece.num_moves += 1
    @king.num_moves += 1
    if @piece.position.col < @king.position.col
      @board.overwrite(Coordinate.new(@king.position.col-1, @king.position.row), @piece)
      @board.overwrite(Coordinate.new(@king.position.col-2, @king.position.row), @king)
    else
      @board.overwrite(Coordinate.new(@king.position.col+1, @king.position.row), @piece)
      @board.overwrite(Coordinate.new(@king.position.col+2, @king.position.row), @king)
    end
  end

  def reverse
    @board.overwrite(@piece.position, nil)
    @board.overwrite(@king.position, nil)
    @board.overwrite(@start, @piece)
    @board.overwrite(@start_king, @king)
    @piece.num_moves -= 1
    @king.num_moves -= 1
  end
end

class PromotingMove < Move

end

