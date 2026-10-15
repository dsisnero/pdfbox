require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fdf/FDFAnnotationLink.java
#     the XFDF element parser reads OnActivation/Action/URI/@Name into a
#     PDActionURI stored under /A.
#
# The Java FDFAnnotationTest does not cover this, so the assertions below are
# derived from the Java source.
module Pdfbox::Pdmodel::Fdf
  describe "FDFAnnotationLink action" do
    it "parses the OnActivation URI action from XFDF (Java FDFAnnotationLink)" do
      xml = %(<link page="0" rect="0,0,10,10">) +
            %(<OnActivation><Action><URI Name="https://example.com/"/></Action></OnActivation>) +
            %(</link>)
      annot = FDFAnnotationLink.new(XML.parse(xml).root.not_nil!)

      action = annot.action
      action.should_not be_nil
      action.not_nil!.uri.should eq("https://example.com/")
    end

    it "leaves the action nil when there is no OnActivation URI" do
      xml = %(<link page="0" rect="0,0,10,10"/>)
      annot = FDFAnnotationLink.new(XML.parse(xml).root.not_nil!)
      annot.action.should be_nil
    end
  end
end
