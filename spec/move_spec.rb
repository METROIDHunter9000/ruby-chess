require_relative '../lib/piece.rb'
require_relative '../lib/board.rb'
require 'set'

describe Move do
  describe StandardMove do
    before do
      @board = Board.new_blank
      @queen = Queen.new(@board, :white)
      @board.new_piece(Coordinate.new(3,3), @queen)
      @knight = Knight.new(@board, :white)
      @board.new_piece(Coordinate.new(3,6), @knight)
      @move_queen = @queen.valid_moves["g4"]
      @move_knight = @knight.valid_moves["c5"]
      expect(@move_queen.class).to eql StandardMove
      expect(@move_knight.class).to eql StandardMove
    end
    describe "#execute" do
      it "moves any piece to an empty spot on the board" do
        @move_queen.execute
        @move_knight.execute

        expect(@board.index("d4")).to eql nil
        expect(@board.index("d7")).to eql nil
        expect(@board.index("g4")).to eql @queen
        expect(@board.index("c5")).to eql @knight

        expect(@queen.num_moves).to eql 1
        expect(@knight.num_moves).to eql 1
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @move_queen.execute
        @move_knight.execute
        @move_queen.reverse
        @move_knight.reverse

        expect(@board.index("d4")).to eql @queen
        expect(@board.index("d7")).to eql @knight
        expect(@board.index("g4")).to eql nil
        expect(@board.index("c5")).to eql nil

        expect(@queen.num_moves).to eql 0
        expect(@knight.num_moves).to eql 0
      end
    end
  end

  describe CastlingMove do
    before do
      @board = Board.new_blank
      @rook1 = Rook.new(@board, :white)
      @king1 = King.new(@board, :white)
      @rook2 = Rook.new(@board, :black)
      @king2 = King.new(@board, :black)
      @board.new_piece(Coordinate.new(0,0), @rook1)
      @board.new_piece(Coordinate.new(4,0), @king1)
      @board.new_piece(Coordinate.new(7,7), @rook2)
      @board.new_piece(Coordinate.new(4,7), @king2)
      @castle_black = @rook2.valid_moves["e8"]
      @castle_white = @rook1.valid_moves["e1"]
      expect(@castle_black.class).to eql CastlingMove
      expect(@castle_white.class).to eql CastlingMove
    end
    describe "#execute" do
      it "moves the rook up next to the king, and then jumps the king over the rook" do
        @castle_white.execute
        @castle_black.execute

        expect(@board.index("d1")).to eql @rook1
        expect(@board.index("c1")).to eql @king1
        expect(@board.index("f8")).to eql @rook2
        expect(@board.index("g8")).to eql @king2
        expect(@board.index("a1")).to eql nil
        expect(@board.index("e1")).to eql nil
        expect(@board.index("e8")).to eql nil
        expect(@board.index("h8")).to eql nil

        expect(@rook1.num_moves).to eql 1
        expect(@rook2.num_moves).to eql 1
        expect(@king1.num_moves).to eql 1
        expect(@king2.num_moves).to eql 1
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @castle_white.execute
        @castle_black.execute
        @castle_white.reverse
        @castle_black.reverse

        expect(@board.index("d1")).to eql nil
        expect(@board.index("c1")).to eql nil
        expect(@board.index("f8")).to eql nil
        expect(@board.index("g8")).to eql nil
        expect(@board.index("a1")).to eql @rook1
        expect(@board.index("e1")).to eql @king1
        expect(@board.index("e8")).to eql @king2
        expect(@board.index("h8")).to eql @rook2

        expect(@rook1.num_moves).to eql 0
        expect(@rook2.num_moves).to eql 0
        expect(@king1.num_moves).to eql 0
        expect(@king2.num_moves).to eql 0
      end
    end
  end

  describe CapturingMove do
    before do
      @board = Board.new_blank
      @rook = Rook.new(@board, :white)
      @pawn = Pawn.new(@board, :black)
      @board.new_piece(Coordinate.new(0,0), @rook)
      @board.new_piece(Coordinate.new(0,6), @pawn)
      @capture = @rook.valid_moves["a7"]
      expect(@capture.class).to eql CapturingMove 
    end
    describe "#execute" do
      it "moves a piece on top of an enemy piece and captures it" do
        @capture.execute

        expect(@board.index("a7")).to eql @rook
        expect(@board.index("a1")).to eql nil

        expect(@pawn.num_moves).to eql 0
        expect(@pawn.is_captured).to eql true

        expect(@rook.num_moves).to eql 1
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @capture.execute
        @capture.reverse

        expect(@board.index("a7")).to eql @pawn
        expect(@board.index("a1")).to eql @rook

        expect(@pawn.num_moves).to eql 0
        expect(@pawn.is_captured).to eql false

        expect(@rook.num_moves).to eql 0
      end
    end
  end

  describe EnPassantMove do
    before do
      @board = Board.new_blank
      @pawnb = Pawn.new(@board, :black)
      @pawnw = Pawn.new(@board, :white)
      @board.new_piece(Coordinate.new(0,6), @pawnb)
      @board.new_piece(Coordinate.new(0,1), @pawnw)
      @moveb = @pawnb.valid_moves["a5"]
      @movew = @pawnw.valid_moves["a4"]
      expect(@moveb.class).to eql EnPassantMove
      expect(@movew.class).to eql EnPassantMove
    end
    describe "#execute" do
      it "moves a pawn up to spaces and marks it as en_passant_capturable" do
        @moveb.execute
        @movew.execute

        expect(@board.index("a7")).to eql nil
        expect(@board.index("a2")).to eql nil
        expect(@board.index("a4")).to eql @pawnw
        expect(@board.index("a5")).to eql @pawnb
        expect(@pawnb.en_passant_capturable).to eql true
        expect(@pawnw.en_passant_capturable).to eql true
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @moveb.execute
        @movew.execute
        @moveb.reverse
        @movew.reverse
        
        expect(@board.index("a7")).to eql @pawnb
        expect(@board.index("a2")).to eql @pawnw
        expect(@board.index("a4")).to eql nil
        expect(@board.index("a5")).to eql nil
        expect(@pawnb.en_passant_capturable).to eql false
        expect(@pawnw.en_passant_capturable).to eql false
      end
    end
  end

  describe EnPassantCapture do
    before do
      @board = Board.new_blank
      @pawnb = Pawn.new(@board, :black)
      @pawnw = Pawn.new(@board, :white)
      @board.new_piece(Coordinate.new(0,6), @pawnb)
      @board.new_piece(Coordinate.new(1,4), @pawnw)
    end
    describe "#execute" do
      it "captures the target pawn and moves one space ahead of it" do
        @pawnb.valid_moves["a5"].execute
        move_pawnw = @pawnw.valid_moves["a5"]
        move_pawnw.execute

        expect(move_pawnw.class).to eql EnPassantCapture
        expect(@board.index("a7")).to eql nil
        expect(@pawnb.is_captured).to eql true
        expect(@board.index("a6")).to eql @pawnw
        expect(@pawnw.position.col).to eql 0
        expect(@pawnw.position.row).to eql 5
        expect(@board.index("b5")).to eql nil
        expect(@board.index("a5")).to eql nil
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @pawnb.valid_moves["a5"].execute
        move_pawnw = @pawnw.valid_moves["a5"]
        move_pawnw.execute
        move_pawnw.reverse

        expect(move_pawnw.class).to eql EnPassantCapture
        expect(@board.index("a7")).to eql nil
        expect(@pawnb.is_captured).to eql false
        expect(@board.index("a6")).to eql nil
        expect(@pawnw.position.col).to eql 1
        expect(@pawnw.position.row).to eql 4
        expect(@board.index("b5")).to eql @pawnw
        expect(@board.index("a5")).to eql @pawnb
      end
    end
  end

  describe CaptureAndPromote do
    before do
      @board = Board.new_blank
      @pawn = Pawn.new(@board, :black)
      @knight = Knight.new(@board, :white)
      @board.new_piece(Coordinate.new(1,1), @pawn)
      @board.new_piece(Coordinate.new(2,0), @knight)
      @move = @pawn.valid_moves["c1"]
      expect(@move.class).to eql CaptureAndPromote
    end
    describe "#execute" do
      it "moves the pawn over the target to capture it and promotes the pawn" do
        @move.execute
        queen = @board.index("c1")

        expect(queen.class).to eql Queen
        expect(queen.position.row).to eql 0
        expect(queen.position.col).to eql 2
        expect(queen.color).to eql @pawn.color
        expect(@knight.is_captured).to eql true
        expect(@board.index("b2")).to eql nil
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @move.execute
        @move.reverse
        
        expect(@board.index("c1")).to eql @knight
        expect(@knight.is_captured).to eql false
        expect(@board.index("b2")).to eql @pawn
      end
    end
  end
  
  describe MoveAndPromote do
    before do
      @board = Board.new_blank
      @pawn = Pawn.new(@board, :black)
      @board.new_piece(Coordinate.new(1,1), @pawn)
      @move = @pawn.valid_moves["b1"]
      expect(@move.class).to eql MoveAndPromote
    end
    describe "#execute" do
      it "moves the pawn to the end of the board and promotes the pawn" do
        @move.execute
        queen = @board.index("b1")

        expect(queen.class).to eql Queen
        expect(queen.position.row).to eql 0
        expect(queen.position.col).to eql 1
        expect(queen.color).to eql @pawn.color
        expect(@board.index("b2")).to eql nil
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @move.execute
        @move.reverse
        
        expect(@board.index("b1")).to eql nil
        expect(@board.index("b2")).to eql @pawn
      end
    end
  end
end
