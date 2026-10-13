# Soft mask for transparency compositing.
# Port of Apache PDFBox PDSoftMask.
#
# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/state/PDSoftMask.java
require "../form/pdtransparency_group"

module Pdfbox::Pdmodel::Graphics::State
  class PDSoftMask
    include Pdfbox::Pdmodel::Common::COSObjectable

    # Java PDSoftMask.create(COSBase): a dictionary is wrapped; a /None name or
    # any other name/value yields nil.
    def self.create(dictionary : Pdfbox::Cos::Base?) : PDSoftMask?
      case dictionary
      when Pdfbox::Cos::Dictionary
        new(dictionary)
      else
        nil
      end
    end

    @dictionary : Pdfbox::Cos::Dictionary
    @sub_type : Pdfbox::Cos::Name?
    @group : Pdfbox::Pdmodel::Graphics::Form::PDTransparencyGroup?
    @group_resolved = false
    @backdrop_color : Pdfbox::Cos::Array?
    @backdrop_color_resolved = false
    @transfer_function : Pdfbox::Pdmodel::Common::Function::PDFunction?
    @transfer_function_resolved = false

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Base
      @dictionary
    end

    # Java getSubType(): the /S entry (Alpha or Luminosity).
    def sub_type : Pdfbox::Cos::Name?
      @sub_type ||= @dictionary.get_dictionary_object(Pdfbox::Cos::Name.new("S")).as?(Pdfbox::Cos::Name)
    end

    # Java getGroup(): builds the group XObject from the /G entry. Java returns
    # a PDTransparencyGroup; a /G whose /Group /S is not /Transparency yields nil.
    def group : Pdfbox::Pdmodel::Graphics::Form::PDTransparencyGroup?
      unless @group_resolved
        @group_resolved = true
        cos_group = @dictionary.get_dictionary_object(Pdfbox::Cos::Name.new("G"))
        if cos_group.is_a?(Pdfbox::Cos::Stream) && transparency_group?(cos_group)
          @group = Pdfbox::Pdmodel::Graphics::Form::PDTransparencyGroup.new(cos_group)
        end
      end
      @group
    end

    # Java getBackdropColor(): the /BC entry.
    def backdrop_color : Pdfbox::Cos::Array?
      unless @backdrop_color_resolved
        @backdrop_color_resolved = true
        @backdrop_color = @dictionary.get_array(Pdfbox::Cos::Name.new("BC"))
      end
      @backdrop_color
    end

    # Java getTransferFunction(): the /TR entry through PDFunction.create.
    def transfer_function : Pdfbox::Pdmodel::Common::Function::PDFunction?
      unless @transfer_function_resolved
        @transfer_function_resolved = true
        cos_tf = @dictionary.get_dictionary_object(Pdfbox::Cos::Name.new("TR"))
        @transfer_function = Pdfbox::Pdmodel::Common::Function::PDFunction.create(cos_tf) if cos_tf
      end
      @transfer_function
    end

    # Java getInitialTransformationMatrix(): the CTM captured when the ExtGState
    # was activated; nil until set.
    property initial_transformation_matrix : Pdfbox::Util::Matrix?

    private def transparency_group?(stream : Pdfbox::Cos::Stream) : Bool
      group = stream.get_dictionary(Pdfbox::Cos::Name.new("Group"))
      return false unless group
      group.get_name_as_string(Pdfbox::Cos::Name.new("S")) == "Transparency"
    end
  end
end
