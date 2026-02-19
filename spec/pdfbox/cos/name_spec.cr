require "../../spec_helper"

describe Pdfbox::Cos::Name do
  it "round-trips non-ASCII name keys without replacement (PDFBox-4076)" do
    special = "中国你好!"
    output = IO::Memory.new

    document = Pdfbox::Pdmodel::Document.create
    catalog = document.document_catalog || raise "expected document catalog"
    catalog_dict = catalog.cos_object
    catalog_dict.set_string(special, special)
    document.save(output)

    loaded = Pdfbox::Loader.load_pdf(output.to_slice)
    loaded_doc_catalog = loaded.document_catalog || raise "expected loaded catalog"
    loaded_catalog = loaded_doc_catalog.cos_object

    loaded_catalog.contains_key?(special).should be_true
    value = loaded_catalog[Pdfbox::Cos::Name.new(special)].as(Pdfbox::Cos::String).value
    value.should eq(special)
  end
end
