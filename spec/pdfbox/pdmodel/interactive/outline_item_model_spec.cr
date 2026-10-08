require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/documentnavigation/outline/PDOutlineItem.java
# Ports the action/destination/structure-element/text-color surface and
# findDestinationPage (page destinations, GoTo actions and named destinations
# via the /Names /Dests name tree).
alias OutlineItemNS = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline
alias OutlineDestNS = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination
alias OutlineActionNS = Pdfbox::Pdmodel::Interactive::Action
alias OutlineColorNS = Pdfbox::Pdmodel::Graphics::Color

module OutlineItemModelSpec
  def self.item : OutlineItemNS::PDOutlineItem
    OutlineItemNS::PDOutlineItem.new
  end

  def self.page_destination(page : Pdfbox::Pdmodel::Page) : OutlineDestNS::PDPageXYZDestination
    dest = OutlineDestNS::PDPageXYZDestination.new
    dest.page = page.cos_object.not_nil!
    dest
  end
end

describe "PDOutlineItem model surface" do
  it "has no destination, action or structure element by default" do
    item = OutlineItemModelSpec.item
    item.destination.should be_nil
    item.action.should be_nil
    item.structure_element.should be_nil
  end

  it "round-trips a page destination" do
    item = OutlineItemModelSpec.item
    dest = OutlineDestNS::PDPageXYZDestination.new
    dest.page = Pdfbox::Cos::Dictionary.new
    item.destination = dest

    result = item.destination
    result.should be_a(OutlineDestNS::PDPageXYZDestination)
  end

  it "round-trips a GoTo action" do
    item = OutlineItemModelSpec.item
    dest = OutlineDestNS::PDPageXYZDestination.new
    dest.page = Pdfbox::Cos::Dictionary.new

    action = OutlineActionNS::PDActionGoTo.new
    action.destination = dest
    item.action = action

    item.action.should be_a(OutlineActionNS::PDActionGoTo)
  end

  it "round-trips a structure element" do
    item = OutlineItemModelSpec.item
    structure = Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement.new("P", nil)
    item.structure_element = structure

    result = item.structure_element
    result.should_not be_nil
    result.not_nil!.cos_object.should eq(structure.cos_object)
  end

  it "defaults the text color to black and round-trips a set color" do
    item = OutlineItemModelSpec.item
    item.text_color.components.should eq([0.0_f32, 0.0_f32, 0.0_f32])

    item.text_color = OutlineColorNS::PDColor.new(
      [1.0_f32, 0.0_f32, 0.0_f32],
      OutlineColorNS::PDDeviceRGB::INSTANCE,
    )
    item.text_color.components.should eq([1.0_f32, 0.0_f32, 0.0_f32])
  end

  it "finds the page for a page destination" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      3.times { doc.add_page }

      item = OutlineItemModelSpec.item
      item.destination = OutlineItemModelSpec.page_destination(doc.get_page(2))

      item.find_destination_page(doc).try(&.cos_object).should eq(doc.get_page(2).cos_object)
    ensure
      doc.close
    end
  end

  it "finds the page through a GoTo action" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      3.times { doc.add_page }

      action = OutlineActionNS::PDActionGoTo.new
      action.destination = OutlineItemModelSpec.page_destination(doc.get_page(1))

      item = OutlineItemModelSpec.item
      item.action = action

      item.find_destination_page(doc).try(&.cos_object).should eq(doc.get_page(1).cos_object)
    ensure
      doc.close
    end
  end

  it "finds the page through a page-number destination" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      3.times { doc.add_page }

      dest = OutlineDestNS::PDPageXYZDestination.new
      dest.page_number = 2
      item = OutlineItemModelSpec.item
      item.destination = dest

      item.find_destination_page(doc).try(&.cos_object).should eq(doc.get_page(2).cos_object)
    ensure
      doc.close
    end
  end

  it "resolves a named destination via the /Names /Dests name tree" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      3.times { doc.add_page }

      dest_array = Pdfbox::Cos::Array.new
      dest_array.add(doc.get_page(1).cos_object.not_nil!)
      dest_array.add(Pdfbox::Cos::Name.new("XYZ"))
      dest_array.grow_to_size(5, Pdfbox::Cos::Null.instance)

      names_array = Pdfbox::Cos::Array.new
      names_array.add(Pdfbox::Cos::String.new("MyDest"))
      names_array.add(dest_array)

      dests_tree = Pdfbox::Cos::Dictionary.new
      dests_tree[Pdfbox::Cos::Name.new("Names")] = names_array

      names = Pdfbox::Cos::Dictionary.new
      names[Pdfbox::Cos::Name.new("Dests")] = dests_tree

      catalog = doc.document_catalog.not_nil!
      catalog.cos_object[Pdfbox::Cos::Name.new("Names")] = names

      item = OutlineItemModelSpec.item
      item.destination = OutlineDestNS::PDNamedDestination.new("MyDest")

      item.find_destination_page(doc).try(&.cos_object).should eq(doc.get_page(1).cos_object)
    ensure
      doc.close
    end
  end

  it "returns nil when there is no destination or action" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      OutlineItemModelSpec.item.find_destination_page(doc).should be_nil
    ensure
      doc.close
    end
  end
end
