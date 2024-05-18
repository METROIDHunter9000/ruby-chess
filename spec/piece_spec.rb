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
          expect(@moves2["e1"].class).to eql CastlingMove
          expect(@moves["e1"].class).to eql CastlingMove
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

          @board.delete_piece(bpos)
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
          @board.delete_piece(bpos1)
          @board.delete_piece(bpos2)
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
          @board.delete_piece(bpos1)
          @board.delete_piece(bpos2)
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
      before do
        @board = Board.new_blank
        @pawnw = Pawn.new(@board, :white)
        @pawnb = Pawn.new(@board, :black) 
        @rookw = Rook.new(@board, :white)
        @rookb = Rook.new(@board, :black)
        @board.new_piece(Coordinate.new(0,7), @rookb)
        @board.new_piece(Coordinate.new(7,0), @rookw)
      end

      it "finds forward moves" do
        @board.new_piece(Coordinate.new(1,1), @pawnw)
        @board.new_piece(Coordinate.new(6,6), @pawnb)
        expect(@pawnw.valid_moves["b3"].class).to eql StandardMove
        expect(@pawnb.valid_moves["g6"].class).to eql StandardMove
      end

      it "allows moving 2 spaces if it's your first move" do
        @board.new_piece(Coordinate.new(1,1), @pawnw)
        @board.new_piece(Coordinate.new(6,6), @pawnb)
        move2w = @pawnw.valid_moves["b4"]
        move2b = @pawnb.valid_moves["g5"]
        expect(move2w.class).to eql EnPassantMove
        expect(move2b.class).to eql EnPassantMove
        move2w.execute
        move2b.execute
        expect(@pawnw.valid_moves.include?("b6")).to eql false
        expect(@pawnb.valid_moves.include?("g3")).to eql false
      end

      it "finds valid captures" do
        @board.new_piece(Coordinate.new(2,5), @pawnw)
        @board.new_piece(Coordinate.new(5,2), @pawnb)
        @board.new_piece(Coordinate.new(1,6), Knight.new(@board, :black))
        @board.new_piece(Coordinate.new(6,1), Knight.new(@board, :white))
        expect(@pawnw.valid_moves["b7"].class).to eql CapturingMove
        expect(@pawnb.valid_moves["g2"].class).to eql CapturingMove
      end

      it "promotes your pawn at the end of the board" do
        @board.new_piece(Coordinate.new(1,6), @pawnw)
        @board.new_piece(Coordinate.new(6,1), @pawnb)
        expect(@pawnw.valid_moves["a8"].class).to eql CaptureAndPromote
        expect(@pawnb.valid_moves["h1"].class).to eql CaptureAndPromote
      end

      it "can capture a piece at the end of the board and then promote" do
        @board.new_piece(Coordinate.new(1,6), @pawnw)
        @board.new_piece(Coordinate.new(6,1), @pawnb)
        expect(@pawnw.valid_moves["b8"].class).to eql MoveAndPromote
        expect(@pawnb.valid_moves["g1"].class).to eql MoveAndPromote
      end
    end
  end
end
