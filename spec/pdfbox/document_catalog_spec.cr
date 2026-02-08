require "../spec_helper"

describe Pdfbox::Pdmodel::DocumentCatalog do
  describe "#page_labels" do
    it "retrieves page labels from test_pagelabels.pdf" do
      # Load PDF from test resources
      pdf_path = File.expand_path("../resources/pdfbox/pdmodel/test_pagelabels.pdf", __DIR__)
      doc = Pdfbox::Pdmodel::Document.load(pdf_path)

      if catalog = doc.document_catalog
        page_labels = catalog.page_labels
        if page_labels
          labels = page_labels.labels_by_page_indices
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
        else
          fail "Page labels should not be nil"
        end
      else
        fail "Document catalog should not be nil"
      end
    end
  end

  describe "#page_labels with malformed PDF" do
    it "handles malformed PDF without exception" do
      pdf_path = File.expand_path("../resources/pdfbox/pdmodel/badpagelabels.pdf", __DIR__)
      doc = Pdfbox::Pdmodel::Document.load(pdf_path)

      if catalog = doc.document_catalog
        page_labels = catalog.page_labels
        # Should not raise exception when called
        if page_labels
          labels = page_labels.labels_by_page_indices
          # Just verify it doesn't crash
          labels.should be_a(Array(String))
        end
      else
        fail "Document catalog should not be nil"
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

  it "handles output intents" do
    # Test from TestPDDocumentCatalog.handleOutputIntents
    pdf_path = File.expand_path("../resources/pdfbox/pdmodel/test.unc.pdf", __DIR__)
    icc_path = File.expand_path("../resources/pdfbox/pdmodel/sRGB.icc", __DIR__)

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    doc.should_not be_nil

    if catalog = doc.document_catalog
      # Retrieve OutputIntents - should be empty initially
      output_intents = catalog.output_intents
      output_intents.should be_empty

      # Create and add output intent
      icc_data = File.read(icc_path).to_slice
      output_intent = Pdfbox::Pdmodel::OutputIntent.create(doc, icc_data)
      output_intent.info = "sRGB IEC61966-2.1"
      output_intent.output_condition = "sRGB IEC61966-2.1"
      output_intent.output_condition_identifier = "sRGB IEC61966-2.1"
      output_intent.registry_name = "http://www.color.org"

      catalog.add_output_intent(output_intent)

      # Retrieve OutputIntents - should have 1 now
      output_intents = catalog.output_intents
      output_intents.size.should eq 1

      # Set OutputIntents
      catalog.output_intents = output_intents

      # Retrieve OutputIntents - should still have 1
      output_intents = catalog.output_intents
      output_intents.size.should eq 1
    else
      fail "Document catalog should not be nil"
    end

    doc.close if doc.responds_to?(:close)
  end

  it "handles open action with boolean" do
    # Test from TestPDDocumentCatalog.handleBooleanInOpenAction
    # PDFBOX-3772 -- allow for COSBoolean
    doc = Pdfbox::Pdmodel::Document.create
    doc.should_not be_nil

    if catalog = doc.document_catalog
      # Set OpenAction to boolean false
      catalog.cos_object[Pdfbox::Cos::Name.new("OpenAction")] = Pdfbox::Cos::Boolean::FALSE

      # Get open action - should return nil for boolean false
      open_action = catalog.open_action
      open_action.should be_nil
    else
      fail "Document catalog should not be nil"
    end

    doc.close if doc.responds_to?(:close)
  end
end
