require_relative '../lib/piece.rb'
require_relative '../lib/board.rb'
require 'set'

describe Piece do
  describe "#valid_moves" do
    context "for a Knight" do
      before do
        @board = Board.new_blank
        @knight = Knight.new(@board, :white)
        @board.new_piece(Coordinate.new(2,1), @knight)
        @expected_moves = Set['a1','a3','b4','d4','e1','e3']
      end

      it "finds valid moves" do
        moves = @knight.valid_moves
        expect(moves.keys.to_set).to eql @expected_moves
        moves.values.each {|move| expect(move.class).to eql StandardMove}
      end

      it "finds valid captures" do
        @board.new_piece(Coordinate.new(0,0), Rook.new(@board, :black))
        @board.new_piece(Coordinate.new(0,2), Rook.new(@board, :black))
        @board.new_piece(Coordinate.new(1,3), Rook.new(@board, :black))
        @board.new_piece(Coordinate.new(3,3), Rook.new(@board, :black))
        @board.new_piece(Coordinate.new(4,0), Rook.new(@board, :black))
        @board.new_piece(Coordinate.new(4,2), Rook.new(@board, :black))
        
        moves = @knight.valid_moves
        expect(moves.keys.to_set).to eql @expected_moves
        moves.values.each {|move| expect(move.class).to eql CapturingMove}
      end
    end

    context "for a Bishop" do
      before do
        @board = Board.new_blank
        @bishop = Bishop.new(@board, :white)
        @board.new_piece(Coordinate.new(3,3), @bishop)
        @board.new_piece(Coordinate.new(2,2), Bishop.new(@board, :white))
        @board.new_piece(Coordinate.new(4,4), Bishop.new(@board, :black))
        @board.new_piece(Coordinate.new(5,1), Bishop.new(@board, :white))
        @moves = @bishop.valid_moves
      end

      it "finds valid moves" do
        expect(@moves["e3"].class).to eql StandardMove
        expect(@moves["c5"].class).to eql StandardMove
        expect(@moves["b6"].class).to eql StandardMove
        expect(@moves["a7"].class).to eql StandardMove
      end

      it "finds valid captures" do
        expect(@moves["e5"].class).to eql CapturingMove
      end

      it "cannot move past any piece" do
        expect(@moves.include?("g1")).to eql false
        expect(@moves.include?("b1")).to eql false
        expect(@moves.include?("f6")).to eql false
      end
    end

    context "for a Rook" do
      before do
        @board = Board.new_blank
        @king = King.new(@board, :white)
        @rook = Rook.new(@board, :white)
        @rook2 = Rook.new(@board, :white)

        @board.new_piece(Coordinate.new(4,0), @king)
        @board.new_piece(Coordinate.new(0,0), @rook)
        @board.new_piece(Coordinate.new(7,0), @rook2)
        @board.new_piece(Coordinate.new(0,3), Pawn.new(@board, :black))
        @board.new_piece(Coordinate.new(7,3), Pawn.new(@board, :white))
        @moves = @rook.valid_moves
        @moves2 = @rook2.valid_moves
      end

      it "finds valid moves" do
        expect(@moves["a2"].class).to eql StandardMove
        expect(@moves["a3"].class).to eql StandardMove
        expect(@moves["b1"].class).to eql StandardMove
        expect(@moves["c1"].class).to eql StandardMove
        expect(@moves["d1"].class).to eql StandardMove
        expect(@moves2["g1"].class).to eql StandardMove
        expect(@moves2["f1"].class).to eql StandardMove
        expect(@moves2["h2"].class).to eql StandardMove
        expect(@moves2["h3"].class).to eql StandardMove
      end

      it "finds valid captures" do
        expect(@moves["a4"].class).to eql CapturingMove
      end

      it "cannot move past any piece" do
        expect(@moves2.include?("h5")).to eql false
        expect(@moves2.include?("h6")).to eql false
        expect(@moves2.include?("h7")).to eql false
        expect(@moves2.include?("h8")).to eql false
        expect(@moves2.include?("d1")).to eql false
        expect(@moves2.include?("c1")).to eql false
        expect(@moves2.include?("b1")).to eql false
        expect(@moves2.include?("a1")).to eql false
        expect(@moves.include?("f1")).to eql false
        expect(@moves.include?("g1")).to eql false
        expect(@moves.include?("h1")).to eql false
        expect(@moves.include?("a5")).to eql false
        expect(@moves.include?("a6")).to eql false
        expect(@moves.include?("a7")).to eql false
        expect(@moves.include?("a8")).to eql false
      end

      context "castling with a king" do
        it "can castle if neither of them have moved" do
          expect(@moves["e1"].class).to eql CastlingMove
          expect(@moves2["e1"].class).to eql CastlingMove
        end

        it "cannot castle if either of them have moved" do
          @rook2.num_moves = 1
          @moves2 = @rook2.valid_moves
          expect(@moves2.include?("e1")).to eql false

          @king.num_moves = 1
          @moves = @rook.valid_moves
          expect(@moves.include?("e1")).to eql false

          @rook2.num_moves = 0
          @king.num_moves = 0
        end

        it "cannot castle if the king is in check" do
          bpos = Coordinate.new(5,1)
          bishop = Bishop.new(@board, :black)
          @board.new_piece(bpos, bishop)

          @moves = @rook.valid_moves
          expect(@moves.include?("e1")).to eql false

          @moves2 = @rook2.valid_moves
          expect(@moves2.include?("e1")).to eql false

          @board.overwrite(bpos, nil)
          bishop.is_captured = true
        end

        it "cannot castle if the king will be in check" do
          bpos1 = Coordinate.new(2,2)
          bpos2 = Coordinate.new(6,2)
          rook1 = Rook.new(@board, :black)
          rook2 = Rook.new(@board, :black)
          @board.new_piece(bpos1, rook1)
          @board.new_piece(bpos2, rook2)
          @moves = @rook.valid_moves
          @moves2 = @rook2.valid_moves
          expect(@moves.include?("e1")).to eql false
          expect(@moves2.include?("e1")).to eql false
          @board.overwrite(bpos1, nil)
          @board.overwrite(bpos2, nil)
          rook1.is_captured = true
          rook2.is_captured = true
        end

        it "cannot castle if any enemy piece is attacking a position traversed by the king during castling" do 
          bpos1 = Coordinate.new(3,2)
          bpos2 = Coordinate.new(5,2)
          rook1 = Rook.new(@board, :black)
          rook2 = Rook.new(@board, :black)
          @board.new_piece(bpos1, rook1)
          @board.new_piece(bpos2, rook2)
          @moves = @rook.valid_moves
          @moves2 = @rook2.valid_moves
          expect(@moves.include?("e1")).to eql false
          expect(@moves2.include?("e1")).to eql false
          @board.overwrite(bpos1, nil)
          @board.overwrite(bpos2, nil)
          rook1.is_captured = true
          rook2.is_captured = true
        end
      end

    end

    context "for a King" do
      before do
        @board = Board.new_blank
        @king = King.new(@board, :white)

        @board.new_piece(Coordinate.new(1,1), @king)
        @board.new_piece(Coordinate.new(0,2), Queen.new(@board, :black))
        @board.new_piece(Coordinate.new(0,1), Queen.new(@board, :black))
        @board.new_piece(Coordinate.new(2,2), Queen.new(@board, :white))
        @moves = @king.valid_moves
      end

      it "finds valid moves" do
        expect(@moves["b3"].class).to eql StandardMove
        expect(@moves["c2"].class).to eql StandardMove
        expect(@moves["a1"].class).to eql StandardMove
        expect(@moves["b1"].class).to eql StandardMove
        expect(@moves["c1"].class).to eql StandardMove
      end

      it "finds valid captures" do
        expect(@moves["a2"].class).to eql CapturingMove
        expect(@moves["a3"].class).to eql CapturingMove
      end

      it "cannot move onto any friendly piece" do
        expect(@moves.include?("c3")).to eql false
      end
    end

    context "for a Queen" do
      before do
        @board = Board.new_blank
        @queen = Queen.new(@board, :white)
        @board.new_piece(Coordinate.new(3,3), @queen)
        @board.new_piece(Coordinate.new(2,2), Queen.new(@board, :white))
        @board.new_piece(Coordinate.new(4,4), Queen.new(@board, :black))
        @board.new_piece(Coordinate.new(5,1), Queen.new(@board, :white))

        @board.new_piece(Coordinate.new(3,4), Queen.new(@board, :white))
        @board.new_piece(Coordinate.new(3,2), Queen.new(@board, :black))
        @board.new_piece(Coordinate.new(5,3), Queen.new(@board, :white))
        @moves = @queen.valid_moves
      end

      it "finds valid moves" do
        expect(@moves["e3"].class).to eql StandardMove
        expect(@moves["c5"].class).to eql StandardMove
        expect(@moves["b6"].class).to eql StandardMove
        expect(@moves["a7"].class).to eql StandardMove

        expect(@moves["e4"].class).to eql StandardMove
        expect(@moves["a4"].class).to eql StandardMove
        expect(@moves["b4"].class).to eql StandardMove
        expect(@moves["c4"].class).to eql StandardMove
      end

      it "finds valid captures" do
        expect(@moves["e5"].class).to eql CapturingMove
        expect(@moves["d3"].class).to eql CapturingMove
      end

      it "cannot move past any piece" do
        expect(@moves.include?("g1")).to eql false
        expect(@moves.include?("b1")).to eql false
        expect(@moves.include?("f6")).to eql false

        expect(@moves.include?("h4")).to eql false
        expect(@moves.include?("d6")).to eql false
        expect(@moves.include?("d2")).to eql false
      end
    end

    context "for a Pawn" do
      pending
    end
  end
end

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

        expect(@board.index_algebraic("d4")).to eql nil
        expect(@board.index_algebraic("d7")).to eql nil
        expect(@board.index_algebraic("g4")).to eql @queen
        expect(@board.index_algebraic("c5")).to eql @knight

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

        expect(@board.index_algebraic("d4")).to eql @queen
        expect(@board.index_algebraic("d7")).to eql @knight
        expect(@board.index_algebraic("g4")).to eql nil
        expect(@board.index_algebraic("c5")).to eql nil

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

        expect(@board.index_algebraic("d1")).to eql @rook1
        expect(@board.index_algebraic("c1")).to eql @king1
        expect(@board.index_algebraic("f8")).to eql @rook2
        expect(@board.index_algebraic("g8")).to eql @king2
        expect(@board.index_algebraic("a1")).to eql nil
        expect(@board.index_algebraic("e1")).to eql nil
        expect(@board.index_algebraic("e8")).to eql nil
        expect(@board.index_algebraic("h8")).to eql nil

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

        expect(@board.index_algebraic("d1")).to eql nil
        expect(@board.index_algebraic("c1")).to eql nil
        expect(@board.index_algebraic("f8")).to eql nil
        expect(@board.index_algebraic("g8")).to eql nil
        expect(@board.index_algebraic("a1")).to eql @rook1
        expect(@board.index_algebraic("e1")).to eql @king1
        expect(@board.index_algebraic("e8")).to eql @king2
        expect(@board.index_algebraic("h8")).to eql @rook2

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

        expect(@board.index_algebraic("a7")).to eql @rook
        expect(@board.index_algebraic("a1")).to eql nil

        expect(@pawn.num_moves).to eql 0
        expect(@pawn.is_captured).to eql true

        expect(@rook.num_moves).to eql 1
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @capture.execute
        @capture.reverse

        expect(@board.index_algebraic("a7")).to eql @pawn
        expect(@board.index_algebraic("a1")).to eql @rook

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

        expect(@board.index_algebraic("a7")).to eql nil
        expect(@board.index_algebraic("a2")).to eql nil
        expect(@board.index_algebraic("a4")).to eql @pawnw
        expect(@board.index_algebraic("a5")).to eql @pawnb
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
        
        expect(@board.index_algebraic("a7")).to eql @pawnb
        expect(@board.index_algebraic("a2")).to eql @pawnw
        expect(@board.index_algebraic("a4")).to eql nil
        expect(@board.index_algebraic("a5")).to eql nil
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
        expect(@board.index_algebraic("a7")).to eql nil
        expect(@pawnb.is_captured).to eql true
        expect(@board.index_algebraic("a6")).to eql @pawnw
        expect(@pawnw.position.col).to eql 0
        expect(@pawnw.position.row).to eql 5
        expect(@board.index_algebraic("b5")).to eql nil
        expect(@board.index_algebraic("a5")).to eql nil
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @pawnb.valid_moves["a5"].execute
        move_pawnw = @pawnw.valid_moves["a5"]
        move_pawnw.execute
        move_pawnw.reverse

        expect(move_pawnw.class).to eql EnPassantCapture
        expect(@board.index_algebraic("a7")).to eql nil
        expect(@pawnb.is_captured).to eql false
        expect(@board.index_algebraic("a6")).to eql nil
        expect(@pawnw.position.col).to eql 1
        expect(@pawnw.position.row).to eql 4
        expect(@board.index_algebraic("b5")).to eql @pawnw
        expect(@board.index_algebraic("a5")).to eql @pawnb
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
        queen = @board.index_algebraic("c1")

        expect(queen.class).to eql Queen
        expect(queen.position.row).to eql 0
        expect(queen.position.col).to eql 2
        expect(queen.color).to eql @pawn.color
        expect(@knight.is_captured).to eql true
        expect(@board.index_algebraic("b2")).to eql nil
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @move.execute
        @move.reverse
        
        expect(@board.index_algebraic("c1")).to eql @knight
        expect(@knight.is_captured).to eql false
        expect(@board.index_algebraic("b2")).to eql @pawn
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
        queen = @board.index_algebraic("b1")

        expect(queen.class).to eql Queen
        expect(queen.position.row).to eql 0
        expect(queen.position.col).to eql 1
        expect(queen.color).to eql @pawn.color
        expect(@board.index_algebraic("b2")).to eql nil
      end
    end
    describe "#reverse" do
      it "reverses the move" do
        @move.execute
        @move.reverse
        
        expect(@board.index_algebraic("b1")).to eql nil
        expect(@board.index_algebraic("b2")).to eql @pawn
      end
    end
  end
end
