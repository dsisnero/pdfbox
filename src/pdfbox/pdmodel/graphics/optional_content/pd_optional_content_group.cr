require "../../document_interchange/marked_content/pd_property_list"

module Pdfbox::Pdmodel::Graphics::OptionalContent
  # Optional content group (Java PDOptionalContentGroup extends PDPropertyList).
  class PDOptionalContentGroup < Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList
    TYPE = "OCG"

    def initialize(name : String)
      super(Pdfbox::Cos::Dictionary.new)
      @dict.set_name("Type", TYPE)
      self.name = name
    end

    def initialize(dict : Pdfbox::Cos::Dictionary)
      type = dict[Pdfbox::Cos::Name.new("Type")]
      type_name = type.as?(Pdfbox::Cos::Name).try(&.value)
      if type_name != TYPE
        raise ArgumentError.new("Provided dictionary is not of type '/#{TYPE}'")
      end
      super(dict)
    end

    def name : String?
      value = @dict[Pdfbox::Cos::Name.new("Name")]
      value.as?(Pdfbox::Cos::String).try(&.value)
    end

    def name=(name : String) : String
      @dict.set_string("Name", name)
      name
    end

    # The state of an optional content group for a given render purpose.
    # Java PDOptionalContentGroup.RenderState.
    enum RenderState
      ON
      OFF

      # Java RenderState#getName: the COS name for this state.
      def cos_name : Pdfbox::Cos::Name
        Pdfbox::Cos::Name.new(to_s)
      end

      # Java RenderState#valueOf(COSName): maps a state name, nil for nil,
      # raising for an unknown name (Java Enum.valueOf).
      def self.value_of(state : ::String?) : RenderState?
        return nil if state.nil?
        case state.upcase
        when "ON"  then RenderState::ON
        when "OFF" then RenderState::OFF
        else
          raise ArgumentError.new("Unknown render state: #{state}")
        end
      end
    end

    # Returns the render state for the given destination (/Usage), or nil.
    # Java PDOptionalContentGroup#getRenderState(RenderDestination).
    def render_state(destination : Pdfbox::Rendering::RenderDestination) : RenderState?
      state = nil.as(::String?)
      usage = @dict.get_dictionary(Pdfbox::Cos::Name.new("Usage"))
      if usage
        case destination
        in Pdfbox::Rendering::RenderDestination::PRINT
          print = usage.get_dictionary(Pdfbox::Cos::Name.new("Print"))
          state = print.try(&.get_name_as_string(Pdfbox::Cos::Name.new("PrintState")))
        in Pdfbox::Rendering::RenderDestination::VIEW
          view = usage.get_dictionary(Pdfbox::Cos::Name.new("View"))
          state = view.try(&.get_name_as_string(Pdfbox::Cos::Name.new("ViewState")))
        in Pdfbox::Rendering::RenderDestination::EXPORT
          # no destination-specific state; fall through to the export fallback
        end
        if state.nil?
          export = usage.get_dictionary(Pdfbox::Cos::Name.new("Export"))
          state = export.try(&.get_name_as_string(Pdfbox::Cos::Name.new("ExportState")))
        end
      end
      state ? RenderState.value_of(state) : nil
    end
  end
end
