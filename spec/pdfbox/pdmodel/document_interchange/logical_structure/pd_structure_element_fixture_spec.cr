require "../../../../spec_helper"

module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  module PDStructureElementSpecHelpers
    # Each element can be an array, a dictionary or a number.
    # See PDF specification Table 323 - Entries in a structure element dictionary
    def self.check_element(
      base : Pdfbox::Cos::Base?,
      attribute_set : Set(Revisions(PDAttributeObject)),
      class_map : Hash(String, PDAttributeObject | Array(PDAttributeObject)),
      class_set : Set(String),
    ) : Nil
      return unless base

      if base.is_a?(Pdfbox::Cos::Array)
        base.items.each do |base2|
          base2 = base2.object if base2.is_a?(Pdfbox::Cos::Object)
          check_element(base2, attribute_set, class_map, class_set)
        end
      elsif base.is_a?(Pdfbox::Cos::Dictionary)
        kdict = base
        if kdict.has_key?(Pdfbox::Cos::Name.new("Pg"))
          structure_element = PDStructureElement.new(kdict)
          attributes = structure_element.attributes
          attribute_set.add(attributes)
          class_names = structure_element.class_names

          # "If both the A and C entries are present and a given attribute is
          # specified by both, the one specified by the A entry shall take precedence."
          if kdict.has_key?(Pdfbox::Cos::Name.new("C")) && !kdict.has_key?(Pdfbox::Cos::Name.new("A"))
            class_names.size.times do |i|
              class_name = class_names.get_object(i)
              class_set.add(class_name)
              class_map.has_key?(class_name).should be_true
            end
          end
        end
        if kdict.has_key?(Pdfbox::Cos::Name.new("K"))
          check_element(kdict.get_dictionary_object(Pdfbox::Cos::Name.new("K")), attribute_set, class_map, class_set)
        end
      end
    end
  end

  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDStructureElementTest.java
  describe PDStructureElement do
    it "PDStructureElementTest#testClassMap" do
      attribute_set = Set(Revisions(PDAttributeObject)).new
      class_set = Set(String).new

      path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDFBOX-2725-878725.pdf")
      doc = Pdfbox::Loader.load_pdf(path)
      begin
        structure_tree_root = doc.document_catalog.not_nil!.structure_tree_root
        structure_tree_root.should_not be_nil
        PDStructureElementSpecHelpers.check_element(
          structure_tree_root.not_nil!.k, attribute_set, structure_tree_root.not_nil!.class_map, class_set
        )
      ensure
        doc.close
      end

      attribute_set.each do |r|
        if r.size >= 2
          obj0 = r.get_object(0)
          obj0.should be_a(TaggedPdf::PDTableAttributeObject)
          table = obj0.as(TaggedPdf::PDTableAttributeObject)
          table.owner.should eq("Table")
          table.col_span.should eq(2)

          obj1 = r.get_object(1)
          obj1.should be_a(TaggedPdf::PDLayoutAttributeObject)
          layout = obj1.as(TaggedPdf::PDLayoutAttributeObject)
          layout.owner.should eq("Layout")
          width = layout.width
          width.should be_a(Float32)
          width_f = width.as(Float32)
          (width_f == 166.375_f32 || width_f == 246.75_f32).should be_true
          height = layout.height
          height.should be_a(Float32)
          height_f = height.as(Float32)
          (height_f == 14.0_f32 || height_f == 17.0_f32).should be_true
          layout.inline_align.should eq("Start")
          block_align = layout.block_align
          (block_align == "After" || block_align == "Before").should be_true
          r.get_revision_number(0).should eq(0)
          r.get_revision_number(1).should eq(0)
        end
      end

      attribute_set.size.should eq(72)
      cnt = attribute_set.sum { |r| r.size }
      cnt.should eq(45)
      class_set.size.should eq(10)
    end

    it "PDStructureElementTest#testPDFBox4197" do
      attribute_set = Set(Revisions(PDAttributeObject)).new
      class_set = Set(String).new

      path = SpecPaths.resolve("spec/resources/pdfbox/pdmodel/documentinterchange/logicalstructure/PDFBOX-4197.pdf")
      doc = Pdfbox::Loader.load_pdf(path)
      begin
        structure_tree_root = doc.document_catalog.not_nil!.structure_tree_root
        structure_tree_root.should_not be_nil
        PDStructureElementSpecHelpers.check_element(
          structure_tree_root.not_nil!.k, attribute_set, structure_tree_root.not_nil!.class_map, class_set
        )
      ensure
        doc.close
      end

      attribute_set.size.should eq(117)
      cnt = attribute_set.sum { |r| r.size }
      cnt.should eq(111) # this one was 105 before PDFBOX-4197 was fixed
      class_set.size.should eq(0)
    end
  end
end
