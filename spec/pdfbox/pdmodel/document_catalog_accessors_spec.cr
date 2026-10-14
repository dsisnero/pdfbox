require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDocumentCatalog.java
#     getPageMode/setPageMode, getPageLayout/setPageLayout, getThreads/setThreads,
#     getActions/setActions, getURI/setURI, getLanguage/setLanguage, setPageLabels
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/PageModeTest.java
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/PageLayoutTest.java
#
# Characterization spec: upstream covers the PageMode/PageLayout enums but not the
# catalog accessors, so the assertions below are inferred from the Java observable
# behavior (including the getPageMode/getPageLayout invalid-name fallbacks).
module Pdfbox::Pdmodel
  describe DocumentCatalog do
    it "defaults the page mode to USE_NONE and round-trips a valid value (Java getPageMode)" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      catalog.page_mode.should eq(PageMode::USE_NONE)

      catalog.page_mode = PageMode::USE_OPTIONAL_CONTENT
      catalog.cos_object.get_name_as_string(Cos::Name.new("PageMode")).should eq("UseOC")
      catalog.page_mode.should eq(PageMode::USE_OPTIONAL_CONTENT)
    end

    it "falls back to USE_NONE for an invalid page mode (Java logs and defaults)" do
      catalog_dict = Cos::Dictionary.new
      catalog_dict[Cos::Name.new("PageMode")] = Cos::Name.new("Dulacb`ecj")
      DocumentCatalog.new(catalog_dict).page_mode.should eq(PageMode::USE_NONE)
    end

    it "defaults the page layout to SINGLE_PAGE and round-trips a valid value (Java getPageLayout)" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      catalog.page_layout.should eq(PageLayout::SINGLE_PAGE)

      catalog.page_layout = PageLayout::TWO_COLUMN_LEFT
      catalog.cos_object.get_name_as_string(Cos::Name.new("PageLayout")).should eq("TwoColumnLeft")
      catalog.page_layout.should eq(PageLayout::TWO_COLUMN_LEFT)
    end

    it "falls back to SINGLE_PAGE for an invalid or empty page layout (Java getPageLayout)" do
      invalid = Cos::Dictionary.new
      invalid[Cos::Name.new("PageLayout")] = Cos::Name.new("SinglePag")
      DocumentCatalog.new(invalid).page_layout.should eq(PageLayout::SINGLE_PAGE)

      empty = Cos::Dictionary.new
      empty[Cos::Name.new("PageLayout")] = Cos::Name.new("")
      DocumentCatalog.new(empty).page_layout.should eq(PageLayout::SINGLE_PAGE)
    end

    it "lazily creates and round-trips the article threads (Java getThreads/setThreads)" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      catalog.threads.should be_empty
      catalog.cos_object[Cos::Name.new("Threads")].should_not be_nil

      thread = Interactive::Pagenavigation::PDThread.new
      catalog.threads = [thread]
      catalog.threads.size.should eq(1)
      catalog.threads.first.cos_object.should be(thread.cos_object)
    end

    it "lazily creates and round-trips the document catalog actions (Java getActions/setActions)" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      catalog.actions.cos_object.should_not be_nil
      catalog.cos_object[Cos::Name.new("AA")].should_not be_nil

      replacement = Interactive::Action::PDDocumentCatalogAdditionalActions.new
      catalog.actions = replacement
      catalog.actions.cos_object.should be(replacement.cos_object)

      catalog.actions = nil
      catalog.cos_object[Cos::Name.new("AA")]?.should be_nil
    end

    it "round-trips the document-level URI (Java getURI/setURI)" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      catalog.uri.should be_nil

      uri = Interactive::Action::PDURIDictionary.new
      uri.base = "http://example.com/"
      catalog.uri = uri
      catalog.uri.not_nil!.cos_object.should be(uri.cos_object)
      catalog.uri.not_nil!.base.should eq("http://example.com/")

      catalog.uri = nil
      catalog.uri.should be_nil
    end

    it "round-trips the document language and clears it on nil (Java getLanguage/setLanguage)" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      catalog.language.should be_nil

      catalog.language = "en-US"
      catalog.cos_object.get_string(Cos::Name.new("Lang")).should eq("en-US")
      catalog.language.should eq("en-US")

      catalog.language = nil
      catalog.language.should be_nil
    end

    it "sets and clears the page labels descriptor (Java setPageLabels)" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      catalog.page_labels.should be_nil

      labels = PageLabels.new(Cos::Dictionary.new, catalog)
      catalog.page_labels = labels
      catalog.page_labels.not_nil!.cos_object.should be(labels.cos_object)

      catalog.page_labels = nil
      catalog.page_labels.should be_nil
    end
  end
end
