require_relative './board.rb'

class Game
  
  private
  def get_input
    print "> "
    input = gets.chomp
    until input.match("^[a-h][1-8]$")
      puts "#{input} doesn't look right. Try again:"
      print "> "
      input = gets.chomp
    end
    return input
  end

  def select_piece(player)
    piece = nil
    location = get_input
    piece = @board.index(location)
    if piece == nil
      puts "There's no piece at #{location}!"
      return select_piece(player)
    elsif piece.color != player
      puts "You can't select your opponent's piece."
      return select_piece(player)
    elsif piece.legal_moves.length == 0
      puts "There are no legal moves available for that #{piece.class}!"
      return select_piece(player)
    end
    return piece
  end

  def select_destination(piece, moves)
    move = get_input
    unless moves.include? move
      print "#{move} is not a legal move. Try one of the following: "
      moves.each {|pos, move| print "#{pos} "}
      print "\n"
      return select_destination(piece, moves)
    end
    return move
  end

  public
  def initialize
    @board = Board.new_standard
    @display = BoardDisplay.new(@board)
  end

  def start
    players = [:white, :black]
    in_check = {white: false, black: false}
    in_mate = nil
    loop do
      player = players[0]

      #reset en_passant_capturable on all of the player's pawns
      @board.each_piece(player) do |piece|
        piece.en_passant_capturable = false if piece.class == Pawn
      end

      #if player is in check, create board highlights and print warning
      checking = @board.pieces_checking(players[1])
      highlights = Array.new
      in_check[player] = checking.length > 0
      if in_check[player]
        positions = checking.map {|piece| piece.position.to_algebraic}
        positions << @board.get_king(player).position.to_algebraic
        highlights << Highlight.new(positions, "9", "9")
      end

      #display board
      @display.display(flipped: player == :black, highlights: highlights)
      puts "\e[101mWARNING! YOUR KING IS IN CHECK!\e[0m" if in_check[player]

      #if player in mate: end game
      if @board.player_in_mate?(player)
        puts "Mate!"
        in_mate = player
        break
      end

      #input: piece to move
      puts "Player #{player}, choose a piece to move:"
      piece = select_piece(player)
      moves = piece.legal_moves

      #display board w/ legal moves (& still with king in check and by whom)
      move_highlights = Highlight.new(moves.keys, "19", "27")
      selected_highlight = Highlight.new(piece.position.to_algebraic, "28", "28")
      @display.display(flipped: player == :black, highlights: [move_highlights, selected_highlight])

      #input: location to move to (must be in legal moves)
      puts "Choose a move to execute for the piece you selected:"
      destination = select_destination(piece, moves)

      #execute the move
      moves[destination].execute

      #switch players for new turn
      players << players.shift
    end
  end
end
