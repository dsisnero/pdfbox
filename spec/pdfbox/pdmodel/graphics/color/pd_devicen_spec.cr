require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceN.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceNAttributes.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceNProcess.java
#
# Characterization spec: upstream has no dedicated PDDeviceN test, so these
# assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Color
  private def self.devicen_tint : Cos::Dictionary
    tint = Cos::Dictionary.new
    tint[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
    tint[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
    tint[Cos::Name.new("Range")] = Cos::Array.new([
      Cos::Float.new(0.0), Cos::Float.new(1.0), Cos::Float.new(0.0),
      Cos::Float.new(1.0), Cos::Float.new(0.0), Cos::Float.new(1.0),
    ])
    tint[Cos::Name.new("C0")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(0.0), Cos::Float.new(0.0)])
    tint[Cos::Name.new("C1")] = Cos::Array.new([Cos::Float.new(1.0), Cos::Float.new(1.0), Cos::Float.new(1.0)])
    tint[Cos::Name.new("N")] = Cos::Float.new(1.0)
    tint
  end

  private def self.devicen_array : Cos::Array
    array = Cos::Array.new
    array.add(Cos::Name.new("DeviceN"))
    array.add(Cos::Array.new([Cos::Name.new("Spot")]))
    array.add(Cos::Name.new("DeviceRGB"))
    array.add(devicen_tint)
    array
  end

  describe PDDeviceN do
    it "is dispatched by PDColorSpace.create" do
      PDColorSpace.create(devicen_array).should be_a(PDDeviceN)
    end

    it "reports name, components, colorants, and defaults" do
      device_n = PDDeviceN.new
      device_n.name.should eq("DeviceN")
      device_n.colorant_names.should be_empty
      device_n.number_of_components.should eq(0)
      device_n.n_channel?.should be_false
    end

    it "converts through the tint transform and alternate colour space" do
      device_n = PDDeviceN.new(devicen_array)
      device_n.colorant_names.should eq(["Spot"])
      device_n.number_of_components.should eq(1)
      device_n.alternate_color_space.should be_a(PDDeviceRGB)
      device_n.tint_transform.should_not be_nil
      device_n.initial_color.components.should eq([1.0_f32])

      device_n.to_rgb([0.0_f32]).should eq([0.0_f32, 0.0_f32, 0.0_f32])
      device_n.to_rgb([1.0_f32]).should eq([1.0_f32, 1.0_f32, 1.0_f32])
    end

    it "reads the attributes process dictionary and NChannel subtype" do
      attr_dict = Cos::Dictionary.new
      attr_dict.set_name(Cos::Name::SUBTYPE, "NChannel")
      process = Cos::Dictionary.new
      process[Cos::Name.new("Components")] = Cos::Array.new([Cos::Name.new("Cyan"), Cos::Name.new("Magenta")])
      process[Cos::Name.new("ColorSpace")] = Cos::Name.new("DeviceCMYK")
      attr_dict[Cos::Name.new("Process")] = process

      device_n = PDDeviceN.new
      device_n.attributes = PDDeviceNAttributes.new(attr_dict)
      device_n.n_channel?.should be_true

      attributes = device_n.attributes.not_nil!
      attributes.n_channel?.should be_true
      attributes.process.not_nil!.components.should eq(["Cyan", "Magenta"])
      attributes.process.not_nil!.color_space.should be_a(PDDeviceCMYK)
    end

    it "round-trips colorant names and clears attributes" do
      device_n = PDDeviceN.new(devicen_array)
      device_n.colorant_names = ["A", "B", "C"]
      device_n.colorant_names.should eq(["A", "B", "C"])
      device_n.number_of_components.should eq(3)

      attr_dict = Cos::Dictionary.new
      attr_dict.set_name(Cos::Name::SUBTYPE, "NChannel")
      device_n.attributes = PDDeviceNAttributes.new(attr_dict)
      device_n.attributes.should_not be_nil

      device_n.attributes = nil
      device_n.attributes.should be_nil
      device_n.cos_object.as(Cos::Array).size.should eq(4)
    end
  end
end
