# ColumnIndexConverter so that we can use spreadsheet column definitions A.B.C..etc
#
# Usage: see bottom
#
class ColumnIndexConvert
  # make sure the end value of the range is bigger than the highest column
  # you have, or you will get indexoutofbounds errors
  COLS = ('A'..'BB').to_a

  class << self
    # 0-based indexes. Add +1 if you need 1-based indexes
    def convert(item)
      COLS.index(item.to_s)
    end
  end
end
# Expected outputs:
# ColumnIndexConvert.convert(:A)   # => 0
# ColumnIndexConvert.convert(:C)   # => 2
# ColumnIndexConvert.convert(:AA)  # => 26
