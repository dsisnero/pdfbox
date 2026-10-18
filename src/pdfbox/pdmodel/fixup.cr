# Document fixup framework.
#
# Ports org.apache.pdfbox.pdmodel.fixup. Java applies the AcroForm default fixup
# whenever the AcroForm is accessed through `PDDocumentCatalog#getAcroForm()`:
# the defaults processor ensures /DA and /DR (with /Helv and /ZaDb), and when
# NeedAppearances is set the orphan-widget processor rebuilds the field tree and
# the appearance processor generates the missing appearance streams
# (PDFBOX-4985, PDFBOX-3732/4393).
require "../cos"

module Pdfbox::Pdmodel::Fixup
  # A fix-up to apply on a document (Java PDDocumentFixup).
  module PDDocumentFixup
    abstract def apply : Nil
  end

  # Base class for fix-ups (Java AbstractFixup).
  abstract class AbstractFixup
    include PDDocumentFixup

    protected getter document : Pdfbox::Pdmodel::Document

    protected def initialize(@document : Pdfbox::Pdmodel::Document)
    end
  end

  # Applies the AcroForm defaults, then (when NeedAppearances is true) rebuilds
  # orphan widgets and generates appearances (Java AcroFormDefaultFixup).
  class AcroFormDefaultFixup < AbstractFixup
    def initialize(document : Pdfbox::Pdmodel::Document)
      super(document)
    end

    def apply : Nil
      Processor::AcroFormDefaultsProcessor.new(document).process

      # `getAcroForm(null)` semantics: the fixup is already running.
      acro_form = document.document_catalog.try(&.acro_form(nil))
      return if acro_form.nil?

      if acro_form.need_appearances?
        # PDFBOX-4985: build the visual appearance as there is none for the widgets.
        if acro_form.fields.empty?
          Interactive::Form::AcroFormOrphanWidgetsProcessor.new(document).process
        end

        Processor::AcroFormGenerateAppearancesProcessor.new(document).process
      end
    end
  end

  # Document processors run by the fix-ups (Java pdmodel.fixup.processor).
  module Processor
    # Java PDDocumentProcessor.
    module PDDocumentProcessor
      abstract def process : Nil
    end

    # Java AbstractProcessor.
    abstract class AbstractProcessor
      include PDDocumentProcessor

      protected getter document : Pdfbox::Pdmodel::Document

      protected def initialize(@document : Pdfbox::Pdmodel::Document)
      end
    end

    # Verifies and creates the AcroForm default entries (Java AcroFormDefaultsProcessor).
    class AcroFormDefaultsProcessor < AbstractProcessor
      def initialize(document : Pdfbox::Pdmodel::Document)
        super(document)
      end

      def process : Nil
        acro_form = document.document_catalog.try(&.acro_form(nil))
        verify_or_create_defaults(acro_form) unless acro_form.nil?
      end

      private def verify_or_create_defaults(acro_form : Pdfbox::Pdmodel::Interactive::Form::PDAcroForm) : Nil
        adobe_default_appearance_string = "/Helv 0 Tf 0 g "

        # DA entry is required
        if acro_form.default_appearance.empty?
          acro_form.default_appearance = adobe_default_appearance_string
          acro_form.cos_object.set_need_to_be_updated(true)
        end

        # DR entry is required
        default_resources = acro_form.default_resources
        if default_resources.nil?
          default_resources = Pdfbox::Pdmodel::PDResources.new
          acro_form.default_resources = default_resources
          acro_form.cos_object.set_need_to_be_updated(true)
        end

        # PDFBOX-3732: Adobe Acrobat uses Helvetica as a default font stored under
        # /Helv; Zapf Dingbats is included as /ZaDb for check boxes and radio buttons.
        # PDFBOX-4393: added by Adobe when signing, so only when absent.
        resources_dict = default_resources.cos_object.as(Pdfbox::Cos::Dictionary)
        font_dict = resources_dict.get_dictionary(Pdfbox::Cos::Name.new("Font"))
        if font_dict.nil?
          font_dict = Pdfbox::Cos::Dictionary.new
          resources_dict[Pdfbox::Cos::Name.new("Font")] = font_dict
        end

        helv = Pdfbox::Cos::Name.new("Helv")
        unless font_dict.has_key?(helv)
          default_resources.put(helv, Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA))
          resources_dict.set_need_to_be_updated(true)
          font_dict.set_need_to_be_updated(true)
        end

        za_db = Pdfbox::Cos::Name.new("ZaDb")
        unless font_dict.has_key?(za_db)
          default_resources.put(za_db, Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::ZAPF_DINGBATS))
          resources_dict.set_need_to_be_updated(true)
          font_dict.set_need_to_be_updated(true)
        end
      end
    end

    # Generates the appearance streams of the fields and clears NeedAppearances
    # (Java AcroFormGenerateAppearancesProcessor).
    class AcroFormGenerateAppearancesProcessor < AbstractProcessor
      Log = ::Log.for(self)

      def initialize(document : Pdfbox::Pdmodel::Document)
        super(document)
      end

      def process : Nil
        acro_form = document.document_catalog.try(&.acro_form(nil))
        return if acro_form.nil?

        begin
          Log.debug { "trying to generate appearance streams for fields as NeedAppearances is true()" }
          acro_form.refresh_appearances
          acro_form.need_appearances = false
        rescue ex
          Log.debug { "couldn't generate appearance stream for some fields - check output" }
          Log.debug { ex.message }
        end
      end
    end
  end
end
