module Pdfbox::Pdfwriter::Compress
  # Port of Apache PDFBox CompressParameters.
  class CompressParameters
    DEFAULT_OBJECT_STREAM_SIZE = 200

    DEFAULT_COMPRESSION = new
    NO_COMPRESSION      = new(0)

    getter object_stream_size

    def initialize(@object_stream_size : Int32 = DEFAULT_OBJECT_STREAM_SIZE)
      if object_stream_size < 0
        raise ArgumentError.new("Object stream size can't be a negative value")
      end
    end

    def compress? : Bool
      @object_stream_size > 0
    end
  end
end
