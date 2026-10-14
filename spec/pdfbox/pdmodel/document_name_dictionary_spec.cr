require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDocumentNameDictionary.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDocumentCatalog.java (getNames/setNames/getDests)
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDestinationNameTreeNode.java
#
# Characterization spec: upstream has no dedicated test for the name dictionary
# surface (TestEmbeddedFiles only exercises getEmbeddedFiles), so these
# assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel
  describe DocumentNameDictionary do
    it "creates the /Names entry from the catalog (Java catalog constructor)" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      catalog.names.should be_nil

      names = DocumentNameDictionary.new(catalog)
      catalog.cos_object[Cos::Name.new("Names")].should_not be_nil
      catalog.names.not_nil!.cos_object.should be(names.cos_object)
    end

    it "assigns and clears the names dictionary via the catalog setter" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      names = DocumentNameDictionary.new(catalog)
      catalog.names = names
      catalog.names.should_not be_nil
      catalog.names = nil
      catalog.names.should be_nil
    end

    it "reads the dests name tree and resolves a page destination" do
      page = Cos::Dictionary.new
      dest = Cos::Array.new
      dest.add(page)
      dest.add(Cos::Name.new("XYZ"))
      dest.add(Cos::Integer.new(0))
      dest.add(Cos::Integer.new(0))
      dest.add(Cos::Integer.new(0))

      entries = Cos::Array.new
      entries.add(Cos::String.new("Chapter1"))
      entries.add(dest)

      dests_dict = Cos::Dictionary.new
      dests_dict[Cos::Name.new("Names")] = entries

      names_dict = Cos::Dictionary.new
      names_dict[Cos::Name.new("Dests")] = dests_dict
      catalog_dict = Cos::Dictionary.new
      catalog_dict[Cos::Name.new("Names")] = names_dict
      catalog = DocumentCatalog.new(catalog_dict)

      tree = catalog.names.not_nil!.dests.not_nil!
      resolved = tree.value("Chapter1")
      resolved.should be_a(Interactive::DocumentNavigation::Destination::PDPageXYZDestination)
      resolved.not_nil!.page.should be(page)
    end

    it "falls back to the catalog /Dests dictionary and clears it when set" do
      catalog_dests = Cos::Dictionary.new
      names_dict = Cos::Dictionary.new
      catalog_dict = Cos::Dictionary.new
      catalog_dict[Cos::Name.new("Names")] = names_dict
      catalog_dict[Cos::Name.new("Dests")] = catalog_dests
      catalog = DocumentCatalog.new(catalog_dict)

      names = catalog.names.not_nil!
      names.dests.should_not be_nil
      names.dests.not_nil!.cos_object.should be(catalog_dests)

      replacement = Common::PDDestinationNameTreeNode.new
      names.dests = replacement
      names.dests.not_nil!.cos_object.should be(replacement.cos_object)
      # Java clears the potentially out-of-date catalog /Dests reference
      catalog_dict[Cos::Name.new("Dests")]?.should be_nil
    end

    it "round-trips embedded files and javascript trees" do
      catalog = DocumentCatalog.new(Cos::Dictionary.new)
      names = DocumentNameDictionary.new(catalog)

      names.embedded_files.should be_nil
      ef = NameTreeNode(ComplexFileSpecification).new(Cos::Dictionary.new) do |_base|
        ComplexFileSpecification.new(Cos::Dictionary.new)
      end
      names.embedded_files = ef
      names.embedded_files.not_nil!.cos_object.should be(ef.cos_object)

      names.javascript.should be_nil
      js = Common::PDJavascriptNameTreeNode.new
      names.javascript = js
      names.javascript.not_nil!.cos_object.should be(js.cos_object)

      names.embedded_files = nil
      names.embedded_files.should be_nil
      names.javascript = nil
      names.javascript.should be_nil
    end

    it "converts a non-page name-tree entry without raising (PDFBOX-5975)" do
      node = Common::PDDestinationNameTreeNode.new
      entries = Cos::Array.new
      entries.add(Cos::String.new("Broken"))
      entries.add(Cos::String.new("SomeStringDestination"))
      node.cos_object[Cos::Name.new("Names")] = entries

      # Java returns null for a non-page destination; the Crystal signature is
      # non-nil so an empty page destination stands in for that entry.
      node.value("Broken").should be_a(Interactive::DocumentNavigation::Destination::PDPageDestination)
    end
  end
end
