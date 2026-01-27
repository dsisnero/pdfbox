# ICOSParser interface for lazy object resolution
# Corresponds to ICOSParser in Apache PDFBox
module Pdfbox::Cos
  # Interface for parser that can dereference objects lazily
  abstract class ICOSParser
    # Dereference the COS object which is referenced by the given Object
    abstract def dereference_object(obj : Object) : Base

    # Creates a random access read view starting at the given position with the given length
    abstract def create_random_access_read_view(start_position : Int64, stream_length : Int64) : Pdfbox::IO::RandomAccessRead
  end
end
