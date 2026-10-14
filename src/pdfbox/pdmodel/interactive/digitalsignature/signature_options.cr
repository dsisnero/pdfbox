module Pdfbox::Pdmodel::Interactive::DigitalSignature
  # Options for a visible signature (Java SignatureOptions): the visual-signature
  # document, the page, and the preferred signature size. The Java
  # setVisualSignature(PDVisibleSigProperties) overload is out of scope until the
  # PDVisibleSig* cluster is ported.
  class SignatureOptions
    DEFAULT_SIGNATURE_SIZE = 0x2500

    @page : Int32
    @preferred_signature_size : Int32
    @visual_signature : Pdfbox::Pdmodel::Document?

    def initialize
      @page = 0
      @preferred_signature_size = 0
      @visual_signature = nil
    end

    # The 0-based page number (Java getPage/setPage).
    def page : Int32
      @page
    end

    def page=(page : Int32) : Int32
      @page = page
    end

    # The preferred signature size in bytes; only positive values are considered
    # (Java getPreferredSignatureSize/setPreferredSignatureSize).
    def preferred_signature_size : Int32
      @preferred_signature_size
    end

    def preferred_signature_size=(size : Int32) : Int32
      @preferred_signature_size = size if size > 0
      @preferred_signature_size
    end

    # The visual-signature document, or nil (Java getVisualSignature).
    def visual_signature : Pdfbox::Pdmodel::Document?
      @visual_signature
    end

    # Reads the visual signature from a byte stream (Java setVisualSignature(InputStream)).
    # ameba:disable Naming/AccessorMethodName
    def set_visual_signature(data : Bytes) : Nil
      @visual_signature = Pdfbox::Loader.load_pdf(data)
    end

    # Reads the visual signature from a file (Java setVisualSignature(File)).
    # ameba:disable Naming/AccessorMethodName
    def set_visual_signature(path : String) : Nil
      @visual_signature = Pdfbox::Loader.load_pdf(path)
    end

    # Closes the visual-signature document, if any (Java close).
    def close : Nil
      @visual_signature.try(&.close)
      @visual_signature = nil
    end
  end
end
