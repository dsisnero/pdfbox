require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationLine.java
#     getCaption/setCaption, getLeaderLength/setLeaderLength,
#     getLeaderExtend/setLeaderExtend, getLeaderOffset/setLeaderOffset,
#     getCaptionStyle/setCaptionStyle, getCaptionHorizontalOffset/setCaptionHorizontalOffset,
#     getCaptionVerticalOffset/setCaptionVerticalOffset and the XFDF element parser.
#
# The Java FDFAnnotationTest does not cover these, so the assertions below are
# derived from the Java source.
module Pdfbox::Pdmodel::Fdf
  describe "FDFAnnotationLine caption/leader" do
    it "defaults the caption/leader values (Java getters)" do
      annot = FDFAnnotationLine.new
      annot.caption?.should be_false
      annot.leader_length.should eq(0.0)
      annot.leader_extend.should eq(0.0)
      annot.leader_offset.should eq(0.0)
      annot.caption_style.should be_nil
      annot.caption_horizontal_offset.should eq(0.0)
      annot.caption_vertical_offset.should eq(0.0)
    end

    it "round-trips caption and leader properties (Java setters)" do
      annot = FDFAnnotationLine.new
      annot.caption = true
      annot.leader_length = 5.5
      annot.leader_extend = 2.25
      annot.leader_offset = 1.5
      annot.caption_style = "Top"
      annot.caption_horizontal_offset = 3.0
      annot.caption_vertical_offset = 4.0

      annot.caption?.should be_true
      annot.leader_length.should eq(5.5)
      annot.leader_extend.should eq(2.25)
      annot.leader_offset.should eq(1.5)
      annot.caption_style.should eq("Top")
      annot.caption_horizontal_offset.should eq(3.0)
      annot.caption_vertical_offset.should eq(4.0)
    end

    it "parses the caption/leader XFDF attributes (Java FDFAnnotationLine(Element))" do
      xml = %(<line page="0" rect="0,0,10,10" start="1,2" end="3,4" ) +
            %(leaderLength="5" leaderExtend="2" leaderOffset="1" ) +
            %(caption="yes" caption-offset-h="3" caption-offset-v="4" caption-style="Top"/>)
      annot = FDFAnnotationLine.new(XML.parse(xml).root.not_nil!)

      annot.line.should eq([1.0, 2.0, 3.0, 4.0])
      annot.caption?.should be_true
      annot.leader_length.should eq(5.0)
      annot.leader_extend.should eq(2.0)
      annot.leader_offset.should eq(1.0)
      annot.caption_horizontal_offset.should eq(3.0)
      annot.caption_vertical_offset.should eq(4.0)
      annot.caption_style.should eq("Top")
    end

    it "ignores caption sub-attributes when caption is not yes (Java guard)" do
      xml = %(<line page="0" rect="0,0,10,10" start="1,2" end="3,4" ) +
            %(caption="no" caption-offset-h="3" caption-style="Top"/>)
      annot = FDFAnnotationLine.new(XML.parse(xml).root.not_nil!)
      annot.caption?.should be_false
      annot.caption_horizontal_offset.should eq(0.0)
      annot.caption_style.should be_nil
    end
  end
end
