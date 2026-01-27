require "../spec_helper"

describe Pdfbox::Pdmodel::DocumentCatalog do
  describe "#page_labels" do
    it "retrieves page labels from test_pagelabels.pdf" do
      # Load PDF from test resources
      pdf_path = File.expand_path("../resources/pdfbox/pdmodel/test_pagelabels.pdf", __DIR__)
      doc = Pdfbox::Pdmodel::Document.load(pdf_path)
      catalog = doc.document_catalog
      catalog.should_not be_nil

      catalog.should_not be_nil
      page_labels = catalog.as(Pdfbox::Pdmodel::DocumentCatalog).page_labels
      page_labels.should_not be_nil

      labels = page_labels.as(Pdfbox::Pdmodel::PageLabels).labels_by_page_indices
      labels.size.should eq(12)
      labels[0].should eq("A1")
      labels[1].should eq("A2")
      labels[2].should eq("A3")
      labels[3].should eq("i")
      labels[4].should eq("ii")
      labels[5].should eq("iii")
      labels[6].should eq("iv")
      labels[7].should eq("v")
      labels[8].should eq("vi")
      labels[9].should eq("vii")
      labels[10].should eq("Appendix I")
      labels[11].should eq("Appendix II")
    end
  end

  describe "#page_labels with malformed PDF" do
    it "handles malformed PDF without exception" do
      pdf_path = File.expand_path("../resources/pdfbox/pdmodel/badpagelabels.pdf", __DIR__)
      doc = Pdfbox::Pdmodel::Document.load(pdf_path)
      catalog = doc.document_catalog
      catalog.should_not be_nil

      page_labels = catalog.as(Pdfbox::Pdmodel::DocumentCatalog).page_labels
      # Should not raise exception when called
      if page_labels
        labels = page_labels.labels_by_page_indices
        # Just verify it doesn't crash
        labels.should be_a(Array(String))
      end
    end
  end

  describe "#page_count" do
    it "retrieves correct number of pages from test.unc.pdf" do
      pdf_path = File.expand_path("../resources/pdfbox/pdmodel/test.unc.pdf", __DIR__)
      doc = Pdfbox::Pdmodel::Document.load(pdf_path)
      doc.page_count.should eq(4)
    end
  end

  pending "output intents functionality" do
    # TODO: Port test for output intents once implemented
    # This test corresponds to handleOutputIntents() in Java test
    # Currently skipped as output intents not yet implemented
  end

  pending "open action with boolean" do
    # TODO: Port test for open action with boolean
    # This test corresponds to handleBooleanInOpenAction() in Java test
    # Currently skipped as open action not yet implemented
  end
end
