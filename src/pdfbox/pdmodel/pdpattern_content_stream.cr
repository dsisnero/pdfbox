module Pdfbox::Pdmodel
  class PDPatternContentStream < PDFormContentStream
    def initialize(pattern : Graphics::Pattern::PDTilingPattern)
      @stream = pattern.content_stream
      @resources = pattern.resources
      @buffer = ::IO::Memory.new
      @closed = false
    end
  end
end
