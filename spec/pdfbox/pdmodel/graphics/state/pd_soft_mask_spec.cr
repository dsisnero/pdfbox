require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/state/PDSoftMask.java
#
# Characterization spec: upstream has no dedicated PDSoftMask test, so these
# assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::State
  describe PDSoftMask do
    describe ".create" do
      it "returns nil for the /None name and any other name" do
        PDSoftMask.create(Cos::Name.new("None")).should be_nil
        PDSoftMask.create(Cos::Name.new("Alpha")).should be_nil
      end

      it "returns nil for nil and for non-dictionary values" do
        PDSoftMask.create(nil).should be_nil
        PDSoftMask.create(Cos::Integer.new(0)).should be_nil
      end

      it "wraps a dictionary and exposes it as the COS object" do
        dict = Cos::Dictionary.new
        mask = PDSoftMask.create(dict)
        mask.should_not be_nil
        mask.as(PDSoftMask).cos_object.should be(dict)
      end
    end

    describe "accessors" do
      it "reads the /S subtype" do
        dict = Cos::Dictionary.new
        dict[Cos::Name.new("S")] = Cos::Name.new("Luminosity")
        PDSoftMask.new(dict).sub_type.as(Cos::Name).value.should eq("Luminosity")
      end

      it "returns nil subtype when /S is absent" do
        PDSoftMask.new(Cos::Dictionary.new).sub_type.should be_nil
      end

      it "reads the /BC backdrop color array" do
        dict = Cos::Dictionary.new
        bc = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
        dict[Cos::Name.new("BC")] = bc
        PDSoftMask.new(dict).backdrop_color.should eq(bc)
      end

      it "returns nil backdrop color when /BC is absent" do
        PDSoftMask.new(Cos::Dictionary.new).backdrop_color.should be_nil
      end

      it "creates a PDFunction from the /TR entry" do
        dict = Cos::Dictionary.new
        dict[Cos::Name.new("TR")] = type2_function_dict
        function = PDSoftMask.new(dict).transfer_function
        function.should be_a(Pdfbox::Pdmodel::Common::Function::PDFunctionType2)
      end

      it "returns nil transfer function when /TR is absent" do
        PDSoftMask.new(Cos::Dictionary.new).transfer_function.should be_nil
      end

      it "has no initial transformation matrix until one is set" do
        PDSoftMask.new(Cos::Dictionary.new).initial_transformation_matrix.should be_nil
      end

      it "stores the initial transformation matrix" do
        mask = PDSoftMask.new(Cos::Dictionary.new)
        ctm = Pdfbox::Util::Matrix.new(1.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 5.0_f32, 7.0_f32)
        mask.initial_transformation_matrix = ctm
        mask.initial_transformation_matrix.should eq(ctm)
      end
    end

    describe "#group" do
      it "builds a form XObject from a transparency-group /G stream" do
        list = PDSoftMask.new(smask_with_group("Transparency"))
        list.group.should be_a(Pdfbox::Pdmodel::Graphics::Form::PDFormXObject)
      end

      it "returns nil for a non-transparency /G stream" do
        PDSoftMask.new(smask_with_group("DeviceRGB")).group.should be_nil
      end

      it "returns nil when /G is absent" do
        PDSoftMask.new(Cos::Dictionary.new).group.should be_nil
      end

      it "memoizes the group" do
        mask = PDSoftMask.new(smask_with_group("Transparency"))
        mask.group.should be(mask.group)
      end
    end
  end

  describe PDExtendedGraphicsState do
    describe "#copy_into_graphics_state with /SMask" do
      it "applies the soft mask and captures the current CTM" do
        smask = Cos::Dictionary.new
        smask[Cos::Name.new("S")] = Cos::Name.new("Alpha")

        dict = Cos::Dictionary.new
        dict[Cos::Name.new("SMask")] = smask

        gs = PDGraphicsState.new(Pdfbox::Pdmodel::Common::PDRectangle.new)
        ctm = Pdfbox::Util::Matrix.new(1.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 3.0_f32, 4.0_f32)
        gs.current_transformation_matrix = ctm

        PDExtendedGraphicsState.new(dict).copy_into_graphics_state(gs)

        gs.soft_mask.should_not be_nil
        gs.soft_mask.as(PDSoftMask).initial_transformation_matrix.should eq(ctm)
      end

      it "clears the soft mask when /SMask is /None" do
        dict = Cos::Dictionary.new
        dict[Cos::Name.new("SMask")] = Cos::Name.new("None")

        gs = PDGraphicsState.new(Pdfbox::Pdmodel::Common::PDRectangle.new)
        gs.soft_mask = PDSoftMask.new(Cos::Dictionary.new)

        PDExtendedGraphicsState.new(dict).copy_into_graphics_state(gs)

        gs.soft_mask.should be_nil
      end
    end

    it "#soft_mask returns nil for /None and a mask for a dictionary" do
      none_dict = Cos::Dictionary.new
      none_dict[Cos::Name.new("SMask")] = Cos::Name.new("None")
      PDExtendedGraphicsState.new(none_dict).soft_mask.should be_nil

      alpha_dict = Cos::Dictionary.new
      alpha_dict[Cos::Name.new("SMask")] = Cos::Dictionary.new
      PDExtendedGraphicsState.new(alpha_dict).soft_mask.should_not be_nil
    end
  end

  private def self.type2_function_dict : Cos::Dictionary
    dict = Cos::Dictionary.new
    dict[Cos::Name.new("FunctionType")] = Cos::Integer.new(2)
    dict[Cos::Name.new("Domain")] = Cos::Array.new([Cos::Float.new(0.0), Cos::Float.new(1.0)])
    dict[Cos::Name.new("C0")] = Cos::Array.new([Cos::Float.new(0.0)])
    dict[Cos::Name.new("C1")] = Cos::Array.new([Cos::Float.new(1.0)])
    dict[Cos::Name.new("N")] = Cos::Float.new(1.0)
    dict
  end

  private def self.smask_with_group(group_subtype : String) : Cos::Dictionary
    group = Cos::Dictionary.new
    group[Cos::Name.new("S")] = Cos::Name.new(group_subtype)

    group_stream = Cos::Stream.new
    group_stream[Cos::Name.new("Subtype")] = Cos::Name.new("Form")
    group_stream[Cos::Name.new("Group")] = group

    smask = Cos::Dictionary.new
    smask[Cos::Name.new("G")] = group_stream
    smask
  end
end
