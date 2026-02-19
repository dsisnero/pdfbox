require "../../spec_helper"

describe Pdfbox::Cos::Document do
  it "handles nil xref keys and returns empty type/linearization lookups (PDFBOX-6132)" do
    document = Pdfbox::Cos::Document.new
    xref_table = {nil => 10_i64} of Pdfbox::Cos::ObjectKey? => Int64
    document.add_xref_table(xref_table)

    document.objects_by_type(Pdfbox::Cos::Name.new("T")).should eq([] of Pdfbox::Cos::Object)
    document.linearized_dictionary.should be_nil
  end
end
