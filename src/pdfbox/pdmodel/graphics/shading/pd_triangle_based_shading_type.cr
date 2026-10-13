module Pdfbox::Pdmodel::Graphics::Shading
  # Shared model surface for the Gouraud-shaded triangle meshes (ShadingType 4/5).
  # Port of Apache PDFBox PDTriangleBasedShadingType (model surface).
  abstract class PDTriangleBasedShadingType < PDShading
    # The bits per component (/BitsPerComponent), or -1 (Java getBitsPerComponent).
    def bits_per_component : Int32
      @dict.get_int(Pdfbox::Cos::Name.new("BitsPerComponent"), -1_i64).to_i32
    end

    def bits_per_component=(bits_per_component : Int32) : Nil
      @dict.set_int(Pdfbox::Cos::Name.new("BitsPerComponent"), bits_per_component)
    end

    # The bits per coordinate (/BitsPerCoordinate), or -1 (Java getBitsPerCoordinate).
    def bits_per_coordinate : Int32
      @dict.get_int(Pdfbox::Cos::Name.new("BitsPerCoordinate"), -1_i64).to_i32
    end

    def bits_per_coordinate=(bits_per_coordinate : Int32) : Nil
      @dict.set_int(Pdfbox::Cos::Name.new("BitsPerCoordinate"), bits_per_coordinate)
    end

    # The number of color components: 1 when a function is present, else the color
    # space component count (Java getNumberOfColorComponents).
    def number_of_color_components : Int32
      return 1 if function
      color_space.try(&.number_of_components) || 0
    end

    # Sets the /Decode values (Java setDecodeValues).
    def decode_values=(decode_values : Pdfbox::Cos::Array) : Nil
      @dict[Pdfbox::Cos::Name.new("Decode")] = decode_values
    end

    # The decode range for the given function parameter, or nil (Java getDecodeForParameter).
    def decode_for_parameter(param_num : Int32) : Pdfbox::Pdmodel::PDRange?
      values = @dict.get_array(Pdfbox::Cos::Name.new("Decode"))
      return nil unless values
      return nil unless values.size >= param_num * 2 + 1
      Pdfbox::Pdmodel::PDRange.new(values, param_num)
    end
  end
end
