require "../pdmodel"
require "../contentstream/pdf_stream_engine"

module Pdfbox::Rendering
  # Minimal PDFRenderer parity surface for the upstream tests which assert that
  # rendering a page completes without crashing or hanging.
  class PDFRenderer
    class NullRenderEngine < Pdfbox::Contentstream::PDFStreamEngine
    end

    def initialize(@document : Pdfbox::Pdmodel::Document)
    end

    def render_image(page_index : Int32)
      page = @document.get_page(page_index)
      NullRenderEngine.new.process_page(page)
      ::IO::Memory.new
    end
  end
end
