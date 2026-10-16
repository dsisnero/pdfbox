require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAppearanceContentStream.java
#     setLineWidthOnDemand: writes the "w" operator only when the requested
#     width differs from the last set width by more than 0.001. Upstream has no
#     dedicated test; this is a characterization spec.
module Pdfbox::Pdmodel
  describe PDAppearanceContentStream do
    it "set_line_width_on_demand writes only when the width changes" do
      stream = Interactive::Annotation::PDAppearanceStream.new(Cos::Stream.new)
      output = ::IO::Memory.new
      cs = PDAppearanceContentStream.new(stream, output)

      cs.set_line_width_on_demand(2.0)
      cs.set_line_width_on_demand(2.0) # within tolerance -> no operator
      cs.set_line_width_on_demand(2.0005)
      cs.set_line_width_on_demand(3.0)
      cs.close

      String.new(output.to_slice).should eq("2 w\n3 w\n")
    end
  end
end
