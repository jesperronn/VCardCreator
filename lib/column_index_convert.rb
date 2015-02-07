# ColumnIndexConverter so that we can use spreadsheet column definitions A.B.C..etc
#
# Usage: see bottom
#
class ColumnIndexConvert
  # make sure the end value of the range is bigger than the highest column
  # you have, or you will get indexoutofbounds errors
  COLS = ('A'..'BB').to_a

  class << self
    def convert(item)
      COLS.index(item.to_s) + 1
    end
  end
end
# Expected outputs:
# ColumnIndexConvert.convert(:A) # => 1
# ColumnIndexConvert.convert(:C) # => 3
# ColumnIndexConvert.convert(:AA)# => 27
