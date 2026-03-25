# Identity encoding
# Corresponds to IdentityEncoding in Apache PDFBox.

class Pdfbox::Pdmodel::Font::Encoding::IdentityEncoding < Pdfbox::Pdmodel::Font::Encoding::Encoding
  # Singleton instance for Identity-H (horizontal)
  IDENTITY_H = new("Identity-H", 0)

  # Singleton instance for Identity-V (vertical)
  IDENTITY_V = new("Identity-V", 1)

  # Creates a new IdentityEncoding.
  #
  # @param name The encoding name (Identity-H or Identity-V)
  # @param w_mode The writing mode (0 for horizontal, 1 for vertical)
  def initialize(@name : String, @w_mode : Int32)
  end

  # Returns the writing mode.
  #
  # @return 0 for horizontal (Identity-H), 1 for vertical (Identity-V)
  def w_mode : Int32
    @w_mode
  end

  # Returns the name of this encoding.
  #
  # @return the name of the encoding
  def encoding_name : String
    @name
  end

  # Identity encoding maps CID to CID directly
  def get_name(code : Int32) : String
    # For Identity encoding, the code is the CID
    # Return a name based on the CID
    "uni#{code.to_s(16).upcase.rjust(4, '0')}"
  end

  def get_code(name : String) : Int32
    # For Identity encoding, extract CID from name like "uni0041"
    if name.starts_with?("uni") && name.size == 7
      begin
        return name[3..6].to_i(16)
      rescue
      end
    end
    -1
  end

  # Identity encoding contains all codes
  def contains(code : Int32) : Bool
    true
  end

  def contains(name : String) : Bool
    true
  end

  # Convert this encoding to a COS object.
  #
  # @return The cos object that represents this encoding
  def cos_object : Cos::Base
    Cos::Name.new(@name)
  end
end
