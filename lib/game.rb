require_relative './board.rb'
require_relative './display.rb'
require 'json'

class Game
  public 
  attr_accessor :players 
  attr_accessor :in_check 
  attr_accessor :num_moves 
  attr_accessor :board
  
  private
  def switch_player
    self.players << self.players.shift
  end

  def get_input
    print "> "
    input = gets.chomp
    until input.match("^[a-h][1-8]$") or input == "save" or input == "quit"
      puts "#{input} doesn't look right. Try again:"
      print "> "
      input = gets.chomp
    end

    if input == "save"
      json_str = JSON.generate(self.to_json)
      File.open("game.json", "w") do |file|
        file.print(json_str)
      end
      puts "Game saved!"
      get_input
    elsif input == "quit"
      puts "Quitting..."
      exit
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
    self.board = Board.new_standard
    self.players = [:white, :black]
    self.in_check = {white: false, black: false}
    self.num_moves = {white: 0, black: 0}
  end

  def to_json
    obj = Hash.new
    obj["board"] = self.board.to_json
    obj["players"] = self.players
    obj["in_check"] = self.in_check
    obj["num_moves"] = self.num_moves
    obj
  end

  def self.from_json(json_obj)
    game = Game.new
    game.board = Board.from_json(json_obj["board"])
    game.players = json_obj["players"].map {|str| str.to_sym}
    game.in_check = json_obj["in_check"].transform_keys {|key| key.to_sym}
    game.num_moves = json_obj["num_moves"].transform_keys {|key| key.to_sym}
    game
  end

  def start
    @display = BoardDisplay.new(self.board)
    in_mate = nil
    loop do
      player = players[0]

      #reset en_passant_capturable on all of the player's pawns
      self.board.each_piece(player) do |piece|
        piece.en_passant_capturable = false if piece.class == Pawn
      end

      #if player is in check, create board highlights and print warning
      checking = self.board.pieces_checking(players[1])
      highlights = Array.new
      self.in_check[player] = checking.length > 0
      if self.in_check[player]
        positions = checking.map {|piece| piece.position.to_algebraic}
        positions << self.board.get_king(player).position.to_algebraic
        highlights << Highlight.new(positions, "9", "9")
      end

      #display board
      @display.display(flipped: player == :black, highlights: highlights)
      puts "\e[101mWARNING! YOUR KING IS IN CHECK!\e[0m" if self.in_check[player]

      #if player in mate: end game
      if @board.player_in_mate?(player)
        puts "\e[91mYou've been mated!\e[0m"
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
      self.num_moves[player] += 1

      #switch player for new turn
      self.switch_player
    end

    if self.in_check[in_mate]
      puts "#{in_mate}, you've been checkmated!"
    else
      puts "#{in_mate} was mated. The game is a draw."
    end
  end
end
