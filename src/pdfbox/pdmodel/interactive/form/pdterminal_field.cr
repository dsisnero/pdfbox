# Base class for terminal fields (fields with widgets)
module Pdfbox::Pdmodel::Interactive::Form
  abstract class PDTerminalField < PDField
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    def widgets : Array(Annotation::PDAnnotationWidget)
      result = [] of Annotation::PDAnnotationWidget

      # Check if this dictionary is itself a widget
      subtype = @dictionary[Cos::Name.new("Subtype")]
      if subtype.is_a?(Cos::Name) && subtype.value == "Widget"
        result << Annotation::PDAnnotationWidget.new(@dictionary)
      end

      # Check for Kids array containing widgets
      kids = @dictionary[Cos::Name.new("Kids")]
      if kids.is_a?(Cos::Array)
        kids.items.each do |kid|
          if kid.is_a?(Cos::Dictionary)
            kid_subtype = kid[Cos::Name.new("Subtype")]
            if kid_subtype.is_a?(Cos::Name) && kid_subtype.value == "Widget"
              result << Annotation::PDAnnotationWidget.new(kid)
            end
          end
        end
      end

      result
    end
  end
end
