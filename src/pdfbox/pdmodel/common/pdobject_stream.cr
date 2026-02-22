# PDObjectStream represents an object stream in a PDF document.
# Object streams contain multiple compressed PDF objects.
module Pdfbox::Pdmodel::Common
  class PDObjectStream < PDStream
    # Constructor wrapping a COSStream
    def initialize(stream : Cos::Stream)
      super(stream)
    end

    # Get the type of this object, should always return "ObjStm"
    def type : String?
      @stream[Cos::Name::TYPE].as?(Cos::Name).try(&.value)
    end

    # Get the number of compressed objects
    def number_of_objects : Int32
      @stream.get_int(Cos::Name.new("N"), 0).to_i32
    end

    # Set the number of objects
    def number_of_objects=(n : Int32)
      @stream.set_int(Cos::Name.new("N"), n)
    end

    # The byte offset (in the decoded stream) of the first compressed object
    def first_byte_offset : Int32
      @stream.get_int(Cos::Name.new("First"), 0).to_i32
    end

    # Set the byte offset to the first object
    def first_byte_offset=(n : Int32)
      @stream.set_int(Cos::Name.new("First"), n)
    end

    # A reference to an object stream, of which the current object stream is
    # considered an extension
    def extends : PDObjectStream?
      extends_stream = @stream[Cos::Name.new("Extends")]
      return unless extends_stream.is_a?(Cos::Stream)
      PDObjectStream.new(extends_stream)
    end

    # Set the object stream extension
    def extends=(stream : PDObjectStream)
      @stream[Cos::Name.new("Extends")] = stream.cos_object
    end
  end
end
