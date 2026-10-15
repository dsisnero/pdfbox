require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationText.java
#     getIcon/setIcon, getState/setState, getStateModel/setStateModel and the
#     element parser. Java getIcon falls back to PDAnnotationText.NAME_NOTE.
#
# The Java FDFAnnotationTest does not cover these, so the assertions below are
# derived from the Java source.
module Pdfbox::Pdmodel::Fdf
  describe "FDFAnnotationText icon/state" do
    it "defaults the icon to Note (Java getIcon)" do
      annot = FDFAnnotationText.new
      annot.icon.should eq("Note")
      annot.state.should be_nil
      annot.state_model.should be_nil
    end

    it "round-trips icon/state/state_model (Java setters)" do
      annot = FDFAnnotationText.new
      annot.icon = "Comment"
      annot.state = "Accepted"
      annot.state_model = "Review"

      annot.icon.should eq("Comment")
      annot.state.should eq("Accepted")
      annot.state_model.should eq("Review")
    end

    it "parses icon/state/statemodel from XFDF (Java FDFAnnotationText(Element))" do
      xml = %(<text page="0" rect="0,0,10,10" icon="Comment" state="Accepted" statemodel="Review"/>)
      annot = FDFAnnotationText.new(XML.parse(xml).root.not_nil!)

      annot.icon.should eq("Comment")
      annot.state.should eq("Accepted")
      annot.state_model.should eq("Review")
    end

    it "does not set the state without a state model (Java guard)" do
      xml = %(<text page="0" rect="0,0,10,10" state="Accepted"/>)
      annot = FDFAnnotationText.new(XML.parse(xml).root.not_nil!)

      annot.state.should be_nil
      annot.state_model.should be_nil
    end
  end
end
