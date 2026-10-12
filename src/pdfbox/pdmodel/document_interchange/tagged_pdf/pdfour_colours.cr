# The colours of the four edges of a border (before, after, start, end).
# Corresponds to PDFourColours in Apache PDFBox.
#
# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/taggedpdf/PDFourColours.java
module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  class PDFourColours
    @array : Cos::Array

    def initialize
      @array = Cos::Array.new
      4.times { @array.add(Cos::Null::INSTANCE) }
    end

    def initialize(@array : Cos::Array)
      # Java ensures that the array has 4 items (mirrors PDFourColours(COSArray)).
      if @array.size < 4
        i = @array.size - 1
        while i < 4
          @array.add(Cos::Null::INSTANCE)
          i += 1
        end
      end
    end

    def cos_object : Cos::Base
      @array
    end

    # Gets the colour for the before edge.
    def before_colour : Pdfbox::Pdmodel::Graphics::Color::PDGamma?
      colour_by_index(0)
    end

    # Sets the colour for the before edge.
    def before_colour=(colour : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      set_colour_by_index(0, colour)
    end

    # Gets the colour for the after edge.
    def after_colour : Pdfbox::Pdmodel::Graphics::Color::PDGamma?
      colour_by_index(1)
    end

    # Sets the colour for the after edge.
    def after_colour=(colour : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      set_colour_by_index(1, colour)
    end

    # Gets the colour for the start edge.
    def start_colour : Pdfbox::Pdmodel::Graphics::Color::PDGamma?
      colour_by_index(2)
    end

    # Sets the colour for the start edge.
    def start_colour=(colour : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      set_colour_by_index(2, colour)
    end

    # Gets the colour for the end edge.
    def end_colour : Pdfbox::Pdmodel::Graphics::Color::PDGamma?
      colour_by_index(3)
    end

    # Sets the colour for the end edge.
    def end_colour=(colour : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      set_colour_by_index(3, colour)
    end

    private def colour_by_index(index : Int32) : Pdfbox::Pdmodel::Graphics::Color::PDGamma?
      item = @array[index]
      item = item.object if item.is_a?(Cos::Object)
      item.is_a?(Cos::Array) ? Pdfbox::Pdmodel::Graphics::Color::PDGamma.new(item) : nil
    end

    private def set_colour_by_index(index : Int32, colour : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      @array[index] = colour ? colour.cos_array : Cos::Null::INSTANCE
    end
  end
end
