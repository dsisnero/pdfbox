module Pdfbox::Pdmodel::Font
  # Utility class for Unicode fallback (Java UniUtil).
  module UniUtil
    # Faster than String.format("uni%04X", codePoint) (Java getUniNameOfCodePoint).
    def self.get_uni_name_of_code_point(code_point : Int32) : String
      hex = code_point.to_s(16).upcase
      case hex.size
      when 1 then "uni000#{hex}"
      when 2 then "uni00#{hex}"
      when 3 then "uni0#{hex}"
      else        "uni#{hex}"
      end
    end
  end
end
