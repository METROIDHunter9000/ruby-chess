require_relative './lib/game.rb'
require_relative './lib/display.rb'
require_relative './lib/board.rb'

board = Board.new_standard
display = BoardDisplay.new(board)
display.display()
