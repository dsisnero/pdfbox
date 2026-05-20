# Common functionality for BidiInfo structures (UTF-8 and UTF-16)

module Bidi
  # Common methods for BidiInfo-like structures
  # Only includes methods that are truly common between UTF-8 and UTF-16 implementations
  module BidiInfoCommon
    # Check if text has any RTL (right-to-left) levels
    def has_rtl? : Bool
      @levels.any?(&.rtl?)
    end

    # Check if text has any LTR (left-to-right) levels
    def has_ltr? : Bool
      @levels.any?(&.ltr?)
    end
  end
end
