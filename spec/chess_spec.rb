require_relative '../lib/piece.rb'
require_relative '../lib/board.rb'
require 'set'

describe Piece do
  describe "#valid_moves" do
    context "for a Knight" do
      before do
        @board = Board.new_blank
        @knight = Knight.new :white
        @board.new_piece(Coordinate.new(2,1), @knight)
        @expected_moves = Set['a1','a3','b4','d4','e1','e3']
      end

      it "finds valid moves" do
        moves = @knight.valid_moves(@board)
        expect(moves.keys.to_set).to eql @expected_moves
        moves.values.each {|move| expect(move.class).to eql StandardMove}
      end

      it "finds valid captures" do
        @board.new_piece(Coordinate.new(0,0), Rook.new(:black))
        @board.new_piece(Coordinate.new(0,2), Rook.new(:black))
        @board.new_piece(Coordinate.new(1,3), Rook.new(:black))
        @board.new_piece(Coordinate.new(3,3), Rook.new(:black))
        @board.new_piece(Coordinate.new(4,0), Rook.new(:black))
        @board.new_piece(Coordinate.new(4,2), Rook.new(:black))
        
        moves = @knight.valid_moves(@board)
        expect(moves.keys.to_set).to eql @expected_moves
        moves.values.each {|move| expect(move.class).to eql CapturingMove}
      end
    end

    context "for a Bishop" do
      before do
        @board = Board.new_blank
        @bishop = Bishop.new :white
        @board.new_piece(Coordinate.new(3,3), @bishop)
        @board.new_piece(Coordinate.new(2,2), Bishop.new(:white))
        @board.new_piece(Coordinate.new(4,4), Bishop.new(:black))
        @board.new_piece(Coordinate.new(5,1), Bishop.new(:white))
        @moves = @bishop.valid_moves(@board)
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
        @king = King.new :white
        @rook = Rook.new :white
        @rook2 = Rook.new :white

        @board.new_piece(Coordinate.new(4,0), @king)
        @board.new_piece(Coordinate.new(0,0), @rook)
        @board.new_piece(Coordinate.new(7,0), @rook2)
        @board.new_piece(Coordinate.new(0,3), Pawn.new(:black))
        @board.new_piece(Coordinate.new(7,3), Pawn.new(:white))
        @moves = @rook.valid_moves(@board)
        @moves2 = @rook2.valid_moves(@board)
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
          @moves2 = @rook2.valid_moves(@board)
          expect(@moves2.include?("e1")).to eql false

          @king.num_moves = 1
          @moves = @rook.valid_moves(@board)
          expect(@moves.include?("e1")).to eql false

          @rook2.num_moves = 0
          @king.num_moves = 0
        end

        it "cannot castle if the king is in check" do
          bpos = Coordinate.new(5,1)
          bishop = Bishop.new("black")
          @board.new_piece(bpos, bishop)

          @moves = @rook.valid_moves(@board)
          expect(@moves.include?("e1")).to eql false

          @moves2 = @rook2.valid_moves(@board)
          expect(@moves2.include?("e1")).to eql false

          @board.overwrite(bpos, nil)
          bishop.is_captured = true
        end

        it "cannot castle if the king will be in check" do
          bpos1 = Coordinate.new(2,2)
          bpos2 = Coordinate.new(6,2)
          rook1 = Rook.new("black")
          rook2 = Rook.new("black")
          @board.new_piece(bpos1, rook1)
          @board.new_piece(bpos2, rook2)
          @moves = @rook.valid_moves(@board)
          @moves2 = @rook2.valid_moves(@board)
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
          rook1 = Rook.new("black")
          rook2 = Rook.new("black")
          @board.new_piece(bpos1, rook1)
          @board.new_piece(bpos2, rook2)
          @moves = @rook.valid_moves(@board)
          @moves2 = @rook2.valid_moves(@board)
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
        @king = King.new :white

        @board.new_piece(Coordinate.new(1,1), @king)
        @board.new_piece(Coordinate.new(0,2), Queen.new(:black))
        @board.new_piece(Coordinate.new(0,1), Queen.new(:black))
        @board.new_piece(Coordinate.new(2,2), Queen.new(:white))
        @moves = @king.valid_moves(@board)
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
        @queen = Queen.new :white
        @board.new_piece(Coordinate.new(3,3), @queen)
        @board.new_piece(Coordinate.new(2,2), Queen.new(:white))
        @board.new_piece(Coordinate.new(4,4), Queen.new(:black))
        @board.new_piece(Coordinate.new(5,1), Queen.new(:white))

        @board.new_piece(Coordinate.new(3,4), Queen.new(:white))
        @board.new_piece(Coordinate.new(3,2), Queen.new(:black))
        @board.new_piece(Coordinate.new(5,3), Queen.new(:white))
        @moves = @queen.valid_moves(@board)
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
