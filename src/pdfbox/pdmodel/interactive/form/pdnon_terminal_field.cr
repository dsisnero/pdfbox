# A non-terminal field in an interactive form (has children)
module Pdfbox::Pdmodel::Interactive::Form
  class PDNonTerminalField < PDField
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    def field_type : String
      # Non-terminal fields don't have their own field type
      ""
    end

    def value_as_string : String
      ""
    end

    def value=(value : String)
      # Non-terminal fields don't have values
    end

    def widgets : Array(Annotation::PDAnnotationWidget)
      [] of Annotation::PDAnnotationWidget
    end

    # Get child fields
    def children : Array(PDField)
      kids = @dictionary[Cos::Name.new("Kids")]
      return [] of PDField unless kids.is_a?(Cos::Array)

      result = [] of PDField
      kids.items.each do |kid|
        if kid.is_a?(Cos::Dictionary)
          field = PDFieldFactory.create_field(@acro_form, kid, self)
          result << field if field
        end
      end
      result
    end
  end
end
