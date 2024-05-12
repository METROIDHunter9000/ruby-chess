class Coordinate
  attr_accessor :col, :row

  def initialize(col = -1, row = -1)
    self.col = col
    self.row = row
  end

  def valid?()
    self.col.between?(0, 7) and self.row.between?(0, 7)
  end

  def self.from_algebraic(code)
    row = code[1].to_i - 1
    col = code[0].ord - 97
    Coordinate.new(col, row)
  end

  def to_algebraic
    "#{(col+97).chr}#{row+1}"
  end
end
