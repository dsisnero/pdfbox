require "../../../spec_helper"
require "../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::Measurement::PDNumberFormatDictionary do
  it "matches Java defaults and validates constrained values" do
    dictionary = Pdfbox::Pdmodel::Interactive::Measurement::PDNumberFormatDictionary.new

    dictionary.type.should eq("NumberFormat")
    dictionary.fractional_display.should eq("D")
    dictionary.thousands_separator.should eq(",")
    dictionary.decimal_separator.should eq(".")
    dictionary.label_prefix_string.should eq(" ")
    dictionary.label_suffix_string.should eq(" ")
    dictionary.label_position_to_value.should eq("S")
    dictionary.fd?.should be_false

    expect_raises(ArgumentError, /Value must be "D", "F", "R", or "T"/) do
      dictionary.fractional_display = "bad"
    end

    expect_raises(ArgumentError, /Value must be "S", or "P"/) do
      dictionary.label_position_to_value = "bad"
    end
  end

  it "stores numeric and string display settings" do
    dictionary = Pdfbox::Pdmodel::Interactive::Measurement::PDNumberFormatDictionary.new

    dictionary.units = "cm"
    dictionary.conversion_factor = 2.54
    dictionary.denominator = 16
    dictionary.fd = true
    dictionary.thousands_separator = "_"
    dictionary.decimal_separator = ","
    dictionary.label_prefix_string = "~"
    dictionary.label_suffix_string = "."
    dictionary.fractional_display = "F"
    dictionary.label_position_to_value = "P"

    dictionary.units.should eq("cm")
    dictionary.conversion_factor.should eq(2.54)
    dictionary.denominator.should eq(16)
    dictionary.fd?.should be_true
    dictionary.thousands_separator.should eq("_")
    dictionary.decimal_separator.should eq(",")
    dictionary.label_prefix_string.should eq("~")
    dictionary.label_suffix_string.should eq(".")
    dictionary.fractional_display.should eq("F")
    dictionary.label_position_to_value.should eq("P")
  end
end

describe Pdfbox::Pdmodel::Interactive::Measurement::PDRectlinearMeasureDictionary do
  it "sets the Java default subtype and stores arrays" do
    dictionary = Pdfbox::Pdmodel::Interactive::Measurement::PDRectlinearMeasureDictionary.new
    number_format = Pdfbox::Pdmodel::Interactive::Measurement::PDNumberFormatDictionary.new
    number_format.units = "pt"
    number_format.conversion_factor = 1.0

    dictionary.type.should eq("Measure")
    dictionary.subtype.should eq("RL")
    dictionary.scale_ratio = "1 in = 1 in"
    dictionary.change_xs = [number_format]
    dictionary.change_ys = [number_format]
    dictionary.distances = [number_format]
    dictionary.areas = [number_format]
    dictionary.angles = [number_format]
    dictionary.line_sloaps = [number_format]
    dictionary.coord_system_origin = [10, 20.5]
    dictionary.cyx = 3.5

    dictionary.scale_ratio.should eq("1 in = 1 in")
    dictionary.change_xs.as(Array).size.should eq(1)
    dictionary.change_ys.as(Array).size.should eq(1)
    dictionary.distances.as(Array).size.should eq(1)
    dictionary.areas.as(Array).size.should eq(1)
    dictionary.angles.as(Array).size.should eq(1)
    dictionary.line_sloaps.as(Array).size.should eq(1)
    dictionary.change_xs.as(Array).first.units.should eq("pt")
    dictionary.coord_system_origin.should eq([10.0, 20.5])
    dictionary.cyx.should eq(3.5)
  end
end

describe Pdfbox::Pdmodel::Interactive::Measurement::PDViewportDictionary do
  it "stores bbox, name, and measure dictionary" do
    viewport = Pdfbox::Pdmodel::Interactive::Measurement::PDViewportDictionary.new
    bbox = Pdfbox::Pdmodel::Common::PDRectangle.new(1.0_f32, 2.0_f32, 30.0_f32, 40.0_f32)
    measure = Pdfbox::Pdmodel::Interactive::Measurement::PDRectlinearMeasureDictionary.new
    measure.scale_ratio = "1cm = 1cm"

    viewport.bbox = bbox
    viewport.name = "ViewA"
    viewport.measure = measure

    viewport.type.should eq("Viewport")
    viewport.bbox.not_nil!.lower_left_x.should eq(1.0_f32)
    viewport.bbox.not_nil!.lower_left_y.should eq(2.0_f32)
    viewport.bbox.not_nil!.width.should eq(30.0_f32)
    viewport.bbox.not_nil!.height.should eq(40.0_f32)
    viewport.name.should eq("ViewA")
    viewport.measure.should be_a(Pdfbox::Pdmodel::Interactive::Measurement::PDMeasureDictionary)
    viewport.measure.not_nil!.subtype.should eq("RL")
  end
end
