require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDPropBuild.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDPropBuildDataDict.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDPropBuildDataDict do
    it "has the documented defaults" do
      data = PDPropBuildDataDict.new
      data.name.should be_nil
      data.date.should be_nil
      data.version.should be_nil
      data.revision.should eq(0_i64)
      data.minimum_revision.should eq(0_i64)
      data.pre_release?.should be_false
      data.os.should be_nil
      data.non_efont_no_warn?.should be_true
      data.trusted_mode?.should be_false
    end

    it "round-trips the properties" do
      data = PDPropBuildDataDict.new

      data.name = "Adobe Acrobat"
      data.name.should eq("Adobe Acrobat")

      data.date = "2024:01:01 10:00:00Z"
      data.date.should eq("2024:01:01 10:00:00Z")

      data.version = "23.001"
      data.version.should eq("23.001")
      data.cos_object.get_string(Cos::Name.new("REx")).should eq("23.001")

      data.revision = 42_i64
      data.revision.should eq(42_i64)

      data.minimum_revision = 7_i64
      data.minimum_revision.should eq(7_i64)

      data.pre_release = true
      data.pre_release?.should be_true

      data.non_efont_no_warn = false
      data.non_efont_no_warn?.should be_false

      data.trusted_mode = true
      data.trusted_mode?.should be_true
    end

    it "stores the OS as an array, newest first" do
      data = PDPropBuildDataDict.new
      data.os = "Mac"
      data.os.should eq("Mac")

      data.os = "Win"
      data.os.should eq("Win")
      data.cos_object.get_array(Cos::Name.new("OS")).not_nil!.size.should eq(2)

      data.os = nil
      data.os.should be_nil
      data.cos_object.get_array(Cos::Name.new("OS")).should be_nil
    end
  end

  describe PDPropBuild do
    it "round-trips the filter, pub_sec, and app build data" do
      prop_build = PDPropBuild.new
      prop_build.filter.should be_nil
      prop_build.pub_sec.should be_nil
      prop_build.app.should be_nil

      app = PDPropBuildDataDict.new
      app.name = "Acrobat"
      prop_build.app = app
      prop_build.app.not_nil!.name.should eq("Acrobat")

      filter = PDPropBuildDataDict.new
      filter.name = "Adobe.PPKLite"
      prop_build.filter = filter
      prop_build.filter.not_nil!.name.should eq("Adobe.PPKLite")

      prop_build.app = nil
      prop_build.app.should be_nil
    end
  end

  describe PDSignature do
    it "round-trips the prop build dictionary" do
      signature = PDSignature.new
      signature.prop_build.should be_nil

      prop_build = PDPropBuild.new
      app = PDPropBuildDataDict.new
      app.name = "Acrobat"
      prop_build.app = app
      signature.prop_build = prop_build

      signature.prop_build.not_nil!.app.not_nil!.name.should eq("Acrobat")

      signature.prop_build = nil
      signature.prop_build.should be_nil
    end
  end
end
