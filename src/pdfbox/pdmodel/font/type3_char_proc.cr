# Type 3 character procedure
# Corresponds to PDType3CharProc in Apache PDFBox
require "../common/pdrectangle"
require "../common/pdstream"
require "../resources"
require "../../pdf_parser/pdf_stream_parser"
require "../../io"

module Pdfbox::Pdmodel::Font
  class PDType3CharProc
    Log = ::Log.for(self)
    Cos = Pdfbox::Cos

    # Placeholder for PDContentStream interface
    module PDContentStream
      abstract def contents : Pdfbox::IO::RandomAccessInputStream
      abstract def contents_for_random_access : Pdfbox::IO::RandomAccessRead
      abstract def resources : Pdfbox::Pdmodel::PDResources?
      abstract def bounding_box : Common::PDRectangle?
      abstract def matrix : PDFont::Matrix
    end

    # Placeholder for COSObjectable interface
    module COSObjectable
      abstract def cos_object : Pdfbox::Cos::Base
    end

    include PDContentStream
    include COSObjectable

    @font : PDType3Font
    @char_stream : Pdfbox::Cos::Stream

    def initialize(@font : PDType3Font, @char_stream : Pdfbox::Cos::Stream)
    end

    def cos_object : Pdfbox::Cos::Stream
      @char_stream
    end

    def font : PDType3Font
      @font
    end

    def content_stream : Common::PDStream
      Common::PDStream.new(@char_stream)
    end

    def contents : Pdfbox::IO::RandomAccessInputStream
      Pdfbox::IO::RandomAccessInputStream.new(contents_for_random_access)
    end

    def contents_for_random_access : Pdfbox::IO::RandomAccessRead
      Pdfbox::IO::RandomAccessReadBuffer.new(@char_stream.create_input_stream.getb_to_end)
    end

    def resources : Pdfbox::Pdmodel::PDResources?
      if @char_stream.has_key?(Pdfbox::Cos::Name::RESOURCES)
        # PDFBOX-5294
        Log.warn { "Using resources dictionary found in charproc entry" }
        Log.warn { "This should have been in the font or in the page dictionary" }
        dict = @char_stream.get_dictionary(Pdfbox::Cos::Name::RESOURCES)
        dict ? Pdfbox::Pdmodel::PDResources.new(dict) : nil
      else
        @font.resources
      end
    end

    def bounding_box : Common::PDRectangle?
      @font.font_bounding_box
    end

    def matrix : PDFont::Matrix
      @font.font_matrix
    end

    # Calculate the bounding box of this glyph.
    # This will work only if the first operator in the stream is d1.
    def glyph_bounding_box : Common::PDRectangle?
      arguments = [] of Pdfbox::Cos::Base
      parser = Pdfbox::Pdfparser::PDFStreamParser.new(@char_stream.data)
      token = parser.parse_next_token
      while token
        if token.is_a?(Pdfbox::ContentStream::Operator)
          if token.name == "d1" && arguments.size == 6
            6.times do |index|
              return nil unless arguments[index].is_a?(Pdfbox::Cos::Number)
            end

            x = to_float32(arguments[2])
            y = to_float32(arguments[3])
            return Common::PDRectangle.new(
              x,
              y,
              to_float32(arguments[4]) - x,
              to_float32(arguments[5]) - y
            )
          end
          return nil
        else
          arguments << token.as(Pdfbox::Cos::Base)
        end
        token = parser.parse_next_token
      end
      nil
    end

    # Get the width from a type3 charproc stream.
    def width : Float32
      arguments = [] of Pdfbox::Cos::Base
      parser = Pdfbox::Pdfparser::PDFStreamParser.new(@char_stream.data)
      token = parser.parse_next_token
      while token
        if token.is_a?(Pdfbox::ContentStream::Operator)
          return parse_width(token, arguments)
        else
          arguments << token.as(Pdfbox::Cos::Base)
        end
        token = parser.parse_next_token
      end
      raise ::IO::Error.new("Unexpected end of stream")
    end

    private def parse_width(operator : Pdfbox::ContentStream::Operator, arguments : Array(Pdfbox::Cos::Base)) : Float32
      if operator.name == "d0" || operator.name == "d1"
        obj = arguments[0]? || raise ::IO::Error.new("Unexpected end of stream")
        return to_float32(obj) if obj.is_a?(Pdfbox::Cos::Number)
        raise ::IO::Error.new("Unexpected argument type: #{obj.class.name}")
      end
      raise ::IO::Error.new("First operator must be d0 or d1")
    end

    private def to_float32(number : Pdfbox::Cos::Base) : Float32
      case number
      when Pdfbox::Cos::Integer
        number.value.to_f32
      when Pdfbox::Cos::Float
        number.value.to_f32
      else
        raise ::IO::Error.new("Unexpected argument type: #{number.class.name}")
      end
    end
  end
end
