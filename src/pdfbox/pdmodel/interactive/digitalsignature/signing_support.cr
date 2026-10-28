module Pdfbox::Pdmodel::Interactive::DigitalSignature
  # Interface for external signature creation scenarios (Java
  # org.apache.pdfbox.pdmodel.interactive.digitalsignature.ExternalSigningSupport):
  # it hands out the PDF bytes to be signed and accepts the created CMS signature.
  abstract class ExternalSigningSupport
    # The PDF content to be signed (Java #getContent, which returns an
    # InputStream; this port returns the bytes).
    abstract def content : Bytes

    # Stores the CMS signature in the PDF (Java #setSignature).
    abstract def set_signature(signature : Bytes) : Nil # ameba:disable Naming/AccessorMethodName
  end

  # Helper used when creating PDF signatures externally (Java SigningSupport): it
  # wraps the writer that prepared the signature and finishes the file once the
  # CMS signature is available.
  class SigningSupport < ExternalSigningSupport
    @writer : Pdfbox::Pdfwriter::Writer?

    def initialize(@writer : Pdfbox::Pdfwriter::Writer)
    end

    # The data to sign (Java SigningSupport#getContent).
    def content : Bytes
      writer = @writer
      raise Pdfbox::Pdmodel::IllegalStateError.new("PDF not prepared for signing") unless writer

      writer.data_to_sign
    end

    # Writes the external CMS signature into the reserved /Contents entry and
    # emits the signed file (Java SigningSupport#setSignature).
    def set_signature(signature : Bytes) : Nil # ameba:disable Naming/AccessorMethodName
      writer = @writer
      raise Pdfbox::Pdmodel::IllegalStateError.new("PDF not prepared for setting signature") unless writer

      writer.write_external_signature(signature)
    end

    # Releases the writer reference (Java SigningSupport#close).
    def close : Nil
      @writer = nil
    end
  end
end
