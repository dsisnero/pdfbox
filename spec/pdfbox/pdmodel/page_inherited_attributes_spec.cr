require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDPage.java
#     getMediaBox()  -> PDPageTree.getInheritableAttribute(page, MEDIA_BOX), else
#                       PDRectangle.LETTER
#     getCropBox()   -> PDPageTree.getInheritableAttribute(page, CROP_BOX), clipped
#                       to the MediaBox, else getMediaBox()
#     getRotation()  -> PDPageTree.getInheritableAttribute(page, ROTATE); only
#                       multiples of 90 are accepted and the result is normalized
#                       to 0..359
#     getResources() -> PDPageTree.getInheritableAttribute(page, RESOURCES)
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDPageTree.java
#     getInheritableAttribute walks /Parent (only through /Type /Pages nodes) with
#     a visited set, so a cyclic /Parent chain cannot recurse forever.
#
# The port only read these attributes from the page dictionary itself, so a PDF
# that defines /MediaBox, /CropBox or /Rotate once on the /Pages node (which the
# specification allows and real files do) lost them.
private def inherited_rectangle(llx : Float64, lly : Float64, urx : Float64, ury : Float64) : Pdfbox::Cos::Array
  array = Pdfbox::Cos::Array.new
  array.add(Pdfbox::Cos::Float.new(llx))
  array.add(Pdfbox::Cos::Float.new(lly))
  array.add(Pdfbox::Cos::Float.new(urx))
  array.add(Pdfbox::Cos::Float.new(ury))
  array
end

# A page whose `/Parent` is a /Pages node carrying *attributes*.
private def inherited_page(attributes : Hash(String, Pdfbox::Cos::Base),
                           page_values : Hash(String, Pdfbox::Cos::Base) = {} of String => Pdfbox::Cos::Base,
                           cycle : Bool = false) : Pdfbox::Pdmodel::Page
  pages = Pdfbox::Cos::Dictionary.new
  pages[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("Pages")
  pages[Pdfbox::Cos::Name.new("Count")] = Pdfbox::Cos::Integer.new(1)
  attributes.each { |name, value| pages[Pdfbox::Cos::Name.new(name)] = value }

  page_dictionary = Pdfbox::Cos::Dictionary.new
  page_dictionary[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("Page")
  page_dictionary[Pdfbox::Cos::Name.new("Parent")] = pages
  page_values.each { |name, value| page_dictionary[Pdfbox::Cos::Name.new(name)] = value }

  kids = Pdfbox::Cos::Array.new
  kids.add(page_dictionary)
  pages[Pdfbox::Cos::Name.new("Kids")] = kids
  # A /Parent back to the page builds the cyclic chain PDFBOX-6040 guards against.
  pages[Pdfbox::Cos::Name.new("Parent")] = page_dictionary if cycle

  Pdfbox::Pdmodel::Page.new(page_dictionary)
end

describe "PDPage inherited attributes" do
  it "inherits the MediaBox from the /Pages node" do
    page = inherited_page({"MediaBox" => inherited_rectangle(0.0, 0.0, 200.0, 300.0)})
    box = page.media_box.not_nil!
    box.width.should eq(200.0)
    box.height.should eq(300.0)
  end

  it "falls back to US Letter when no MediaBox is defined" do
    page = inherited_page({} of String => Pdfbox::Cos::Base)
    box = page.media_box.not_nil!
    box.width.should eq(612.0)
    box.height.should eq(792.0)
  end

  it "prefers the page's own MediaBox" do
    page = inherited_page(
      {"MediaBox" => inherited_rectangle(0.0, 0.0, 200.0, 300.0)},
      {"MediaBox" => inherited_rectangle(0.0, 0.0, 100.0, 100.0)}
    )
    page.media_box.not_nil!.width.should eq(100.0)
  end

  it "inherits the CropBox and clips it to the MediaBox" do
    page = inherited_page({
      "MediaBox" => inherited_rectangle(0.0, 0.0, 612.0, 792.0),
      "CropBox"  => inherited_rectangle(-10.0, -10.0, 700.0, 800.0),
    })
    box = page.crop_box.not_nil!
    box.lower_left_x.should eq(0.0)
    box.lower_left_y.should eq(0.0)
    box.upper_right_x.should eq(612.0)
    box.upper_right_y.should eq(792.0)
  end

  it "falls back to the inherited MediaBox when no CropBox is defined" do
    page = inherited_page({"MediaBox" => inherited_rectangle(0.0, 0.0, 200.0, 300.0)})
    page.crop_box.not_nil!.width.should eq(200.0)
  end

  it "inherits the rotation" do
    page = inherited_page({"Rotate" => Pdfbox::Cos::Integer.new(90)})
    page.rotation.should eq(90)
  end

  it "normalizes and validates the rotation" do
    inherited_page({"Rotate" => Pdfbox::Cos::Integer.new(450)}).rotation.should eq(90)
    inherited_page({"Rotate" => Pdfbox::Cos::Integer.new(-90)}).rotation.should eq(270)
    inherited_page({"Rotate" => Pdfbox::Cos::Integer.new(45)}).rotation.should eq(0)
  end

  it "inherits the resources" do
    resources = Pdfbox::Cos::Dictionary.new
    resources[Pdfbox::Cos::Name.new("ProcSet")] = Pdfbox::Cos::Array.new
    page = inherited_page({"Resources" => resources})
    page.resources.should_not be_nil
  end

  it "survives a cyclic /Parent chain" do
    page = inherited_page({"MediaBox" => inherited_rectangle(0.0, 0.0, 200.0, 300.0)}, cycle: true)
    page.media_box.not_nil!.width.should eq(200.0)
  end
end
