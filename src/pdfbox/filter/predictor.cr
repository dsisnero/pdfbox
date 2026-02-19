module Pdfbox::Filter
  module Predictor
    # Get value from bit interval from a byte-sized integer.
    # Mirrors org.apache.pdfbox.filter.Predictor#getBitSeq.
    def self.get_bit_seq(by : Int, start_bit : Int, bit_size : Int) : Int32
      mask = (1_u32 << bit_size) - 1_u32
      ((by.to_u32 >> start_bit) & mask).to_i32
    end

    # Set value in a bit interval and return the resulting byte-sized integer.
    # Mirrors org.apache.pdfbox.filter.Predictor#calcSetBitSeq.
    def self.calc_set_bit_seq(by : Int, start_bit : Int, bit_size : Int, val : Int) : Int32
      mask = (1_u32 << bit_size) - 1_u32
      truncated_val = val.to_u32 & mask
      clear_mask = ~(mask << start_bit)
      ((by.to_u32 & clear_mask) | (truncated_val << start_bit)).to_i32
    end
  end
end
