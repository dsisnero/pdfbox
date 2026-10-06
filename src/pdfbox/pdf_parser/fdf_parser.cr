require "./parser"
require "../pdmodel/fdf"

module Pdfbox::Pdfparser
  class FDFParser < Parser
    def initialize(source : Pdfbox::IO::RandomAccessRead)
      super(source)
    end

    def parse : Pdfbox::Pdmodel::Fdf::FDFDocument
      source.rewind
      header = read_line
      unless header.starts_with?("%FDF-")
        raise ::IO::Error.new("Error: Header doesn't contain versioninfo")
      end

      # Populate the underlying COS document so get_document().objects_by_type
      # works (Java FDFParser does a full COS parse via retrieveTrailer()).
      cos_document = parse_cos_document

      fdf = build_model_from_cos(cos_document) || build_model_from_text
      fdf.cos_document = cos_document
      fdf
    end

    # Builds the lightweight FDFDocument model from the parsed COS catalog if a
    # proper trailer /Root chain exists; otherwise returns nil.
    private def build_model_from_cos(cos_document : Pdfbox::Cos::Document) : Pdfbox::Pdmodel::Fdf::FDFDocument?
      trailer = @trailer
      return unless trailer

      root_ref = trailer[Pdfbox::Cos::Name.new("Root")]
      return unless root_ref.is_a?(Pdfbox::Cos::Object)

      root_obj = root_ref.object
      return unless root_obj.is_a?(Pdfbox::Cos::Dictionary)

      fdf_dict_value = root_obj[Pdfbox::Cos::Name.new("FDF")]
      fdf_dict_value = fdf_dict_value.object if fdf_dict_value.is_a?(Pdfbox::Cos::Object)
      return unless fdf_dict_value.is_a?(Pdfbox::Cos::Dictionary)

      Pdfbox::Pdmodel::Fdf::FDFDocument.from_cos_dictionary(fdf_dict_value)
    end

    # Fallback: build the model from the raw file text using the lightweight
    # FDFSyntaxParser. Handles simple FDF files (e.g. single-object, no xref).
    private def build_model_from_text : Pdfbox::Pdmodel::Fdf::FDFDocument
      source.rewind
      content = String.new(source.read_all)
      begin
        Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(content)
      rescue ex
        Log.warn { "FDF text model build failed, using empty model: #{ex.message}" }
        Pdfbox::Pdmodel::Fdf::FDFDocument.new
      end
    end

    # Parses the FDF file at the COS level: locates the xref chain, parses each
    # in-use object into a Cos::Document object pool keyed by its xref entry.
    private def parse_cos_document : Pdfbox::Cos::Document
      cos_document = Pdfbox::Cos::Document.new

      xref_offset = locate_xref_offset
      return cos_document unless xref_offset

      sections = collect_xref_sections(xref_offset)
      xref, _trailer = merge_xref_sections(sections)
      self.xref = xref
      @xref_table = xref.entries

      cos_document.add_xref_table(xref.entries)
      xref.entries.each do |key, offset|
        next if offset <= 0
        begin
          obj = parse_indirect_object_at_offset(offset, key)
          if obj
            cos_obj = Pdfbox::Cos::Object.new(key, self)
            cos_obj.object = obj
            cos_document.set_object(key, cos_obj)
          end
        rescue ex
          Log.warn { "Failed to parse FDF object #{key.number}: #{ex.message}" }
        end
      end
      cos_document
    end
  end
end
