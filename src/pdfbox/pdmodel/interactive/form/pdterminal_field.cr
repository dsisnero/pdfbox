# Base class for terminal fields (fields with widgets)
module Pdfbox::Pdmodel::Interactive::Form
  abstract class PDTerminalField < PDField
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    def widgets : Array(Annotation::PDAnnotationWidget)
      result = [] of Annotation::PDAnnotationWidget

      # Match Java PDTerminalField#getWidgets: a field without a Kids array
      # is itself the widget; otherwise collect the widget kids.
      kids = @dictionary[Cos::Name.new("Kids")]
      kids = kids.object if kids.is_a?(Cos::Object)
      if kids.nil?
        result << Annotation::PDAnnotationWidget.new(@dictionary)
      elsif kids.is_a?(Cos::Array) && !kids.items.empty?
        kids.items.each do |kid|
          kid_dict = kid.is_a?(Cos::Dictionary) ? kid : (kid.is_a?(Cos::Object) ? kid.object.as?(Cos::Dictionary) : nil)
          result << Annotation::PDAnnotationWidget.new(kid_dict) if kid_dict
        end
      end

      result
    end
  end
end
