#!/usr/bin/ruby

require_relative './lib/game.rb'
require_relative './lib/display.rb'
require_relative './lib/board.rb'

if ARGV.length > 0
  game_json_path = ARGV[0]
  ARGV.clear
  game_json_obj = nil
  File.open(game_json_path, "r") do |file|
    game_json_str = file.gets
    game_json_obj = JSON.parse(game_json_str)
  end
  Game.from_json(game_json_obj).start
else
  Game.new.start
end
