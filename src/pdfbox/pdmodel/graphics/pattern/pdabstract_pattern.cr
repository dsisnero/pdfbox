require "../../../util"
require "../../common/cos_objectable"

module Pdfbox::Pdmodel::Graphics::Pattern
  # Wraps a pattern dictionary. Patterns can be found in resource dictionaries.
  # Corresponds to PDAbstractPattern in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/pattern/PDAbstractPattern.java
  abstract class PDAbstractPattern
    include Pdfbox::Pdmodel::Common::COSObjectable

    TYPE_TILING_PATTERN  = 1
    TYPE_SHADING_PATTERN = 2

    # Java PDAbstractPattern.create: dispatch on /PatternType.
    def self.create(dictionary : Pdfbox::Cos::Dictionary, resource_cache : Pdfbox::Pdmodel::ResourceCache? = nil) : PDAbstractPattern
      pattern_type = dictionary.get_int(Cos::Name.new("PatternType"), 0_i64).to_i32
      case pattern_type
      when TYPE_TILING_PATTERN
        stream = dictionary.as?(Pdfbox::Cos::Stream)
        raise ::IO::Error.new("Tiling pattern is not a stream") unless stream
        PDTilingPattern.new(stream, resource_cache)
      when TYPE_SHADING_PATTERN
        PDShadingPattern.new(dictionary)
      else
        raise ::IO::Error.new("Error: Unknown pattern type #{pattern_type}")
      end
    end

    @pattern_dictionary : Cos::Dictionary

    protected def initialize
      @pattern_dictionary = Cos::Dictionary.new
      @pattern_dictionary.set_name(Cos::Name::TYPE, "Pattern")
    end

    def initialize(@pattern_dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Base
      @pattern_dictionary
    end

    # Java getType.
    def type : String
      "Pattern"
    end

    def paint_type : Int32
      @pattern_dictionary.get_int(Cos::Name.new("PaintType"), 0_i64).to_i32
    end

    def paint_type=(value : Int) : Int32
      int_value = value.to_i32
      @pattern_dictionary.set_int(Cos::Name.new("PaintType"), int_value)
      int_value
    end

    def pattern_type=(value : Int) : Int32
      int_value = value.to_i32
      @pattern_dictionary.set_int(Cos::Name.new("PatternType"), int_value)
      int_value
    end

    abstract def pattern_type : Int32

    # Java getMatrix: the /Matrix entry, or the identity matrix if none.
    def matrix : Pdfbox::Util::Matrix
      base = @pattern_dictionary[Cos::Name.new("Matrix")]?
      return Pdfbox::Util::Matrix.new unless base
      Pdfbox::Util::Matrix.create_matrix(base)
    end

    # Java setMatrix.
    def matrix=(value : Pdfbox::Util::Matrix) : Pdfbox::Util::Matrix
      array = Cos::Array.new
      array.add(Cos::Float.new(value.get_value(0, 0)))
      array.add(Cos::Float.new(value.get_value(0, 1)))
      array.add(Cos::Float.new(value.get_value(1, 0)))
      array.add(Cos::Float.new(value.get_value(1, 1)))
      array.add(Cos::Float.new(value.get_value(2, 0)))
      array.add(Cos::Float.new(value.get_value(2, 1)))
      @pattern_dictionary[Cos::Name.new("Matrix")] = array
      value
    end
  end
end
