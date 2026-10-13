require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/shading/PDShadingType1.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/shading/PDShadingType2.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/shading/PDShadingType3.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/shading/PDTriangleBasedShadingType.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/shading/PDMeshBasedShadingType.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/shading/PDShadingType4..7.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Shading
  private def self.shading_dict(type : Int32, color_space : String? = nil) : Cos::Dictionary
    dict = Cos::Dictionary.new
    dict[Cos::Name.new("ShadingType")] = Cos::Integer.new(type.to_i64)
    if cs = color_space
      dict[Cos::Name.new("ColorSpace")] = Cos::Name.new(cs)
    end
    dict
  end

  private def self.cos_array(values : Array(Float64)) : Cos::Array
    array = Cos::Array.new
    values.each { |value| array.add(Cos::Float.new(value)) }
    array
  end

  describe "shading type model" do
    it "reports the shading type for each concrete subclass" do
      PDShading.create(shading_dict(1)).should be_a(PDShadingType1)
      PDShading.create(shading_dict(2)).should be_a(PDShadingType2)
      PDShading.create(shading_dict(3)).should be_a(PDShadingType3)
      PDShading.create(shading_dict(4)).should be_a(PDShadingType4)
      PDShading.create(shading_dict(5)).should be_a(PDShadingType5)
      PDShading.create(shading_dict(6)).should be_a(PDShadingType6)
      PDShading.create(shading_dict(7)).should be_a(PDShadingType7)

      PDShading.create(shading_dict(1)).shading_type.should eq(1)
      PDShading.create(shading_dict(2)).shading_type.should eq(2)
      PDShading.create(shading_dict(3)).shading_type.should eq(3)
      PDShading.create(shading_dict(4)).shading_type.should eq(4)
      PDShading.create(shading_dict(5)).shading_type.should eq(5)
      PDShading.create(shading_dict(6)).shading_type.should eq(6)
      PDShading.create(shading_dict(7)).shading_type.should eq(7)

      PDShading.create(shading_dict(3)).should be_a(PDShadingType2)
      PDShading.create(shading_dict(5)).should be_a(PDTriangleBasedShadingType)
      PDShading.create(shading_dict(6)).should be_a(PDTriangleBasedShadingType)
      PDShading.create(shading_dict(7)).should be_a(PDMeshBasedShadingType)
    end

    it "round-trips the function-based shading (type 1) domain and matrix" do
      shading = PDShadingType1.new(shading_dict(1))
      shading.domain.should be_nil

      shading.domain = cos_array([0.0, 1.0])
      shading.domain.not_nil!.to_float_array.should eq([0.0, 1.0])

      # Java getMatrix returns the identity when /Matrix is absent.
      shading.matrix.should eq(Pdfbox::Util::Matrix.identity)

      shading.matrix = Pdfbox::Util::Matrix.translate(7.0_f32, 8.0_f32)
      shading.matrix.translate_x.should eq(7.0_f32)
      shading.matrix.translate_y.should eq(8.0_f32)
    end

    it "round-trips the axial shading (type 2) coords/domain/extend" do
      shading = PDShadingType2.new(shading_dict(2))
      shading.coords.should be_nil
      shading.extend_values.should be_nil
      shading.domain.should be_nil

      shading.coords = cos_array([10.0, 20.0, 110.0, 120.0])
      shading.domain = cos_array([0.0, 1.0])
      shading.extend_values = cos_array([1.0, 0.0])

      shading.coords.not_nil!.to_float_array.should eq([10.0, 20.0, 110.0, 120.0])
      shading.domain.not_nil!.to_float_array.should eq([0.0, 1.0])
      shading.extend_values.not_nil!.to_float_array.should eq([1.0, 0.0])
    end

    it "exposes bits per coordinate/component/flag and decode for triangle shadings" do
      shading = PDShadingType4.new(shading_dict(4))
      shading.bits_per_coordinate.should eq(-1)
      shading.bits_per_component.should eq(-1)
      shading.bits_per_flag.should eq(-1)

      shading.bits_per_coordinate = 16
      shading.bits_per_component = 8
      shading.bits_per_flag = 2
      shading.bits_per_coordinate.should eq(16)
      shading.bits_per_component.should eq(8)
      shading.bits_per_flag.should eq(2)

      shading.decode_values = cos_array([0.0, 200.0, 0.0, 200.0, 0.0, 1.0])
      shading.decode_for_parameter(0).not_nil!.min.should eq(0.0)
      shading.decode_for_parameter(0).not_nil!.max.should eq(200.0)
      shading.decode_for_parameter(2).not_nil!.max.should eq(1.0)
      shading.decode_for_parameter(3).should be_nil
    end

    it "exposes vertices per row for the lattice-form shading (type 5)" do
      shading = PDShadingType5.new(shading_dict(5))
      shading.vertices_per_row.should eq(-1)
      shading.vertices_per_row = 4
      shading.vertices_per_row.should eq(4)
      shading.bits_per_coordinate = 12
      shading.bits_per_coordinate.should eq(12)
    end

    it "derives the number of color components from the color space" do
      PDShadingType4.new(shading_dict(4, "DeviceRGB")).number_of_color_components.should eq(3)
      PDShadingType4.new(shading_dict(4, "DeviceGray")).number_of_color_components.should eq(1)
      PDShadingType6.new(shading_dict(6, "DeviceRGB")).number_of_color_components.should eq(3)
    end
  end
end
