require_relative './lib/game.rb'
require_relative './lib/display.rb'
require_relative './lib/board.rb'

board = Board.new
display = BoardDisplay.new(board)

highlight = Highlight.new(["f3", "f2", "f1"], "11", "1")
display.display(highlight)
