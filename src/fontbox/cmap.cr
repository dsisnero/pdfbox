module Fontbox
  module CMap
    def self.to_int(bytes : Bytes | Array(UInt8)) : Int32
      code = 0
      bytes.each do |byte|
        code <<= 8
        code |= (byte & 0xFF)
      end
      code
    end
  end
end

require "./cmap/cid_range"
require "./cmap/codespace_range"
require "./cmap/cmap_class"
require "./cmap/cmap_strings"
require "./cmap/cmap_parser"
