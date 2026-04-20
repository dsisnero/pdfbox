module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAppearanceCharacteristicsDictionary
    @dictionary : Cos::Dictionary

    def initialize(@dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    def rotation : Int32
      @dictionary.get_int(Cos::Name.new("R"), 0_i64).to_i32
    end

    def rotation=(value : Int) : Int32
      int_value = value.to_i32
      @dictionary.set_int(Cos::Name.new("R"), int_value)
      int_value
    end

    def border_colour : Graphics::Color::PDColor?
      color_for(Cos::Name.new("BC"))
    end

    def border_colour=(value : Graphics::Color::PDColor) : Graphics::Color::PDColor
      @dictionary[Cos::Name.new("BC")] = value.to_cos_array
      value
    end

    def background : Graphics::Color::PDColor?
      color_for(Cos::Name.new("BG"))
    end

    def background=(value : Graphics::Color::PDColor) : Graphics::Color::PDColor
      @dictionary[Cos::Name.new("BG")] = value.to_cos_array
      value
    end

    def normal_caption : String?
      @dictionary.get_string(Cos::Name.new("CA"))
    end

    def normal_caption=(value : String) : String
      @dictionary.set_string(Cos::Name.new("CA"), value)
      value
    end

    def rollover_caption : String?
      @dictionary.get_string(Cos::Name.new("RC"))
    end

    def rollover_caption=(value : String) : String
      @dictionary.set_string(Cos::Name.new("RC"), value)
      value
    end

    def alternate_caption : String?
      @dictionary.get_string(Cos::Name.new("AC"))
    end

    def alternate_caption=(value : String) : String
      @dictionary.set_string(Cos::Name.new("AC"), value)
      value
    end

    private def color_for(name : Cos::Name) : Graphics::Color::PDColor?
      color_array = @dictionary.get_array(name)
      return unless color_array

      color_space = case color_array.size
                    when 1
                      Graphics::Color::PDDeviceGray::INSTANCE
                    when 3
                      Graphics::Color::PDDeviceRGB::INSTANCE
                    when 4
                      Graphics::Color::PDDeviceCMYK::INSTANCE
                    else
                      nil
                    end
      return unless color_space

      Graphics::Color::PDColor.new(color_array, color_space)
    end
  end
end
