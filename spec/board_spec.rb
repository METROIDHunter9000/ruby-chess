require_relative '../lib/piece.rb'
require_relative '../lib/board.rb'
require 'set'

describe Board do
  describe "#piece_attacking?" do
    before do
      @board = Board.new_blank
      @king = King.new(@board, :white)
      @rookw = Rook.new(@board, :white)
      @rookw.num_moves = 2
      @rookb = Rook.new(@board, :black)
      @board.new_piece(Coordinate.new(4,0), @king)
      @board.new_piece(Coordinate.new(4,1), @rookw)
      @board.new_piece(Coordinate.new(4,7), @rookb)
      @board.new_piece(Coordinate.new(0,3), Pawn.new(@board, :black))
      @board.new_piece(Coordinate.new(0,2), Pawn.new(@board, :black))
      @board.new_piece(Coordinate.new(2,1), Queen.new(@board, :black))
    end
    it "returns true if an enemy piece is currently attacking this location" do
      expect(@board.piece_attacking?(:black, @rookw.position)).to eql true
      expect(@board.piece_attacking?(:black, @king.position)).to eql false
      expect(@board.piece_attacking?(:black, "h1")).to eql false
    end
  end

  describe "#pieces_attacking" do
    before do
      @board = Board.new_blank
      @king = King.new(@board, :white)
      @rookw = Rook.new(@board, :white)
      @rookw.num_moves = 2
      @board.new_piece(Coordinate.new(4,0), @king)
      @board.new_piece(Coordinate.new(0,1), @rookw)
      @board.new_piece(Coordinate.new(0,0), Rook.new(@board, :black))
      @board.new_piece(Coordinate.new(4,6), Rook.new(@board, :black))
      @board.new_piece(Coordinate.new(2,3), Queen.new(@board, :black))
    end
    it "returns a list of all pieces of the given color attacking the given position" do
      expect(@board.pieces_attacking(:black, @rookw.position).length).to eql 2
      expect(@board.pieces_attacking(:black, @king.position).length).to eql 2
      expect(@board.pieces_attacking(:white, "a1").length).to eql 1
    end

    it "returns an empty list when no piece is attacking the position" do
      expect(@board.pieces_attacking(:black, "c4").length).to eql 0
    end

    it "works just the same for empty places on the board" do
      expect(@board.pieces_attacking(:white, "a8").length).to eql 1
      expect(@board.pieces_attacking(:white, "b8").length).to eql 0
    end
  end

  describe "#self_in_check?" do
    context "when you move your king" do
      before do
        @board = Board.new_standard
        @board.delete_piece(Coordinate.new(3,1))
        @board.delete_piece(Coordinate.new(4,1))
        @board.delete_piece(Coordinate.new(3,6))
        @board.delete_piece(Coordinate.new(4,6))
        @king = @board.index_algebraic("e1")
      end

      it "returns true if your king is now in check" do
        @king.valid_moves["d2"].execute
        expect(@board.self_in_check?(@king)).to eql true
      end

      it "returns false if your king is not in check" do
        @king.valid_moves["e2"].execute
        expect(@board.self_in_check?(@king)).to eql false
      end
    end

    context "when you move a piece other than your king" do
      before do
        @board = Board.new_blank
        @king = King.new(@board, :white)
        @rookw = Rook.new(@board, :white)
        @rookw.num_moves = 2
        @rookb = Rook.new(@board, :black)
        @board.new_piece(Coordinate.new(4,0), @king)
        @board.new_piece(Coordinate.new(4,1), @rookw)
        @board.new_piece(Coordinate.new(4,7), @rookb)
        @board.new_piece(Coordinate.new(0,3), Pawn.new(@board, :black))
        @board.new_piece(Coordinate.new(0,2), Pawn.new(@board, :black))
        @board.new_piece(Coordinate.new(2,1), Queen.new(@board, :black))
      end

      it "returns true if you put your king into check" do
        @rookw.valid_moves["d2"].execute
        expect(@board.self_in_check?(@rookw)).to eql true
      end

      it "returns false if your king is not in check" do
        @rookw.valid_moves["e5"].execute
        expect(@board.self_in_check?(@rookw)).to eql false
        @rookw.valid_moves["e8"].execute
        expect(@board.self_in_check?(@rookw)).to eql false
        @rookw.valid_moves["a8"].execute
        expect(@board.self_in_check?(@rookw)).to eql false
      end
    end
  end

  describe "#enemy_in_check" do
    before do
      @board = Board.new_blank
      @king = King.new(@board, :white)
      @rookw = Rook.new(@board, :white)
      @rookw.num_moves = 2
      @board.new_piece(Coordinate.new(4,0), @king)
      @board.new_piece(Coordinate.new(0,1), @rookw)
      @board.new_piece(Coordinate.new(0,0), Rook.new(@board, :black))
      @board.new_piece(Coordinate.new(4,6), Rook.new(@board, :black))
      @board.new_piece(Coordinate.new(2,3), Queen.new(@board, :black))
    end
    it "return a list of all of your pieces that are putting the enemy's king in check" do
      expect(@board.enemy_in_check(:black).length).to eql 2
    end
    it "returns an empty list if you are not checking the enemy's king" do
      @board.delete_piece(Coordinate.new(4,6))
      @board.delete_piece(Coordinate.new(0,0))
      expect(@board.enemy_in_check(:black).length).to eql 0
    end
  end

  describe "#player_in_mate" do
    before do
      @board = Board.new_blank
      @board.new_piece(Coordinate.new(7,7), King.new(@board, :white))
      @board.new_piece(Coordinate.new(7,6), King.new(@board, :black))
      @board.new_piece(Coordinate.new(4,7), Rook.new(@board, :black))
    end
    it "returns true if the specified player cannot perform any legal move" do
      expect(@board.player_in_mate?(:white)).to eql true
    end
    it "returns false if the specified player can still perform at least one legal move" do
      @board.delete_piece(Coordinate.new(4,7))
      expect(@board.player_in_mate?(:white)).to eql false
    end
  end
end
