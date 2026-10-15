module Pdfbox::Pdmodel::Graphics
  # A PostScript XObject (Java PDPostScriptXObject). Conforming readers may not
  # be able to interpret the PostScript fragments.
  class PDPostScriptXObject
    @stream : Pdfbox::Cos::Stream

    def initialize(stream : Pdfbox::Cos::Stream)
      @stream = stream
      stream.set_name(Pdfbox::Cos::Name::TYPE, "XObject")
      stream.set_name(Pdfbox::Cos::Name::SUBTYPE, "PS")
    end

    def cos_object : Pdfbox::Cos::Stream
      @stream
    end

    def stream : Pdfbox::Cos::Stream
      @stream
    end
  end

  # The XObject types produced by PDResources#get_xobject.
  alias XObject = Form::PDFormXObject |
                  Form::PDTransparencyGroup |
                  Image::PDImageXObject |
                  PDPostScriptXObject
end
