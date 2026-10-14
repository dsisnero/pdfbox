module Pdfbox::Pdmodel::Graphics::Shading
  # Base class for a PDF shading dictionary (PDF 32000-1 8.7.4.3).
  # Port of Apache PDFBox PDShading (model surface).
  class PDShading
    include Pdfbox::Pdmodel::Common::COSObjectable

    SHADING_TYPE1 = 1
    SHADING_TYPE2 = 2
    SHADING_TYPE3 = 3
    SHADING_TYPE4 = 4
    SHADING_TYPE5 = 5
    SHADING_TYPE6 = 6
    SHADING_TYPE7 = 7

    def initialize(@dict : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Base
      @dict
    end

    # The /ShadingType entry.
    def shading_type : Int32
      @dict.get_int(Pdfbox::Cos::Name.new("ShadingType"), 0_i64).to_i32
    end

    # Java PDShading#setShadingType.
    def shading_type=(shading_type : Int32) : Int32
      @dict.set_int(Pdfbox::Cos::Name.new("ShadingType"), shading_type)
      shading_type
    end

    # The object type name. Java PDShading#getType (always "Shading").
    def type : String
      "Shading"
    end

    # The shading background (/Background), or nil. Java getBackground.
    def background : Pdfbox::Cos::Array?
      @dict.get_dictionary_object(Pdfbox::Cos::Name.new("Background")).as?(Pdfbox::Cos::Array)
    end

    # Java PDShading#setBackground (nil removes the entry).
    def background=(new_background : Pdfbox::Cos::Array?) : Pdfbox::Cos::Array?
      set_optional_array("Background", new_background)
      new_background
    end

    # The shading bounding box (/BBox), or nil. Java getBBox.
    def bbox : Pdfbox::Pdmodel::Common::PDRectangle?
      array = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("BBox")).as?(Pdfbox::Cos::Array)
      array ? Pdfbox::Pdmodel::Common::PDRectangle.new(array) : nil
    end

    # Java PDShading#setBBox (nil removes the entry).
    def bbox=(new_bbox : Pdfbox::Pdmodel::Common::PDRectangle?) : Pdfbox::Pdmodel::Common::PDRectangle?
      key = Pdfbox::Cos::Name.new("BBox")
      if new_bbox
        @dict[key] = new_bbox.cos_object
      else
        @dict.delete(key)
      end
      new_bbox
    end

    # The anti-alias flag (/AntiAlias), default false. Java getAntiAlias.
    def anti_alias? : Bool
      value = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("AntiAlias"))
      value.is_a?(Pdfbox::Cos::Boolean) ? value.value : false
    end

    # Java PDShading#setAntiAlias.
    def anti_alias=(anti_alias : Bool) : Bool
      @dict.set_boolean(Pdfbox::Cos::Name.new("AntiAlias"), anti_alias)
      anti_alias
    end

    # The shading color space (/ColorSpace), or nil.
    def color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace?
      value = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("ColorSpace"))
      return unless value
      Pdfbox::Pdmodel::Graphics::Color::PDColorSpace.create(value)
    end

    # Java PDShading#setColorSpace (nil removes the entry).
    def color_space=(new_color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace?) : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace?
      key = Pdfbox::Cos::Name.new("ColorSpace")
      if new_color_space
        @dict[key] = new_color_space.cos_object
      else
        @dict.delete(key)
      end
      new_color_space
    end

    # Java PDShading#create: dispatch on the ShadingType entry.
    def self.create(dictionary : Pdfbox::Cos::Dictionary) : PDShading
      case dictionary.get_int(Pdfbox::Cos::Name.new("ShadingType"), 0_i64).to_i32
      when 1 then PDShadingType1.new(dictionary)
      when 2 then PDShadingType2.new(dictionary)
      when 3 then PDShadingType3.new(dictionary)
      when 4 then PDShadingType4.new(dictionary)
      when 5 then PDShadingType5.new(dictionary)
      when 6 then PDShadingType6.new(dictionary)
      when 7 then PDShadingType7.new(dictionary)
      else
        raise ArgumentError.new("Unknown shading type #{dictionary.get_int(Pdfbox::Cos::Name.new("ShadingType"), 0_i64)}")
      end
    end

    # The shading function (/Function), or nil (Java getFunction).
    def function : Pdfbox::Pdmodel::Common::Function::PDFunction?
      value = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("Function"))
      value ? Pdfbox::Pdmodel::Common::Function::PDFunction.create(value) : nil
    end

    def function=(new_function : Pdfbox::Pdmodel::Common::Function::PDFunction) : Nil
      @dict[Pdfbox::Cos::Name.new("Function")] = new_function.cos_object
    end

    # Java PDShading#setFunction(COSArray): sets the /Function entry to an array.
    def function=(new_functions : Pdfbox::Cos::Array) : Nil
      set_optional_array("Function", new_functions)
    end

    # The shading function(s) as an array. Java getFunctionsArray.
    private def functions_array : Array(Pdfbox::Pdmodel::Common::Function::PDFunction)
      object = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("Function"))
      case object
      when Pdfbox::Cos::Dictionary
        [Pdfbox::Pdmodel::Common::Function::PDFunction.create(object)]
      when Pdfbox::Cos::Array
        object.items.map { |item| Pdfbox::Pdmodel::Common::Function::PDFunction.create(item) }
      else
        raise ::IO::Error.new("mandatory /Function element must be a dictionary or an array")
      end
    end

    # Java PDShading#evalFunction(float).
    def eval_function(input_value : Float32) : Array(Float32)
      eval_function([input_value])
    end

    # Java PDShading#evalFunction(float[]), clamping each output to [0, 1].
    def eval_function(input : Array(Float32)) : Array(Float32)
      functions = functions_array
      return_values = if functions.size == 1
                        functions[0].eval(input)
                      else
                        functions.map { |function| function.eval(input)[0] }
                      end
      return_values.map { |value| value < 0.0_f32 ? 0.0_f32 : (value > 1.0_f32 ? 1.0_f32 : value) }
    end

    # Shared setter for optional COSArray entries (Java setItem(name, null) removes).
    protected def set_optional_array(key : ::String, value : Pdfbox::Cos::Array?) : Nil
      name = Pdfbox::Cos::Name.new(key)
      if value
        @dict[name] = value
      else
        @dict.delete(name)
      end
    end
  end
end

require "./shading/pd_shading_type1"
require "./shading/pd_shading_type2"
require "./shading/pd_shading_type3"
require "./shading/pd_triangle_based_shading_type"
require "./shading/pd_shading_type4"
require "./shading/pd_shading_type5"
require "./shading/pd_mesh_based_shading_type"
require "./shading/pd_shading_type6"
require "./shading/pd_shading_type7"
