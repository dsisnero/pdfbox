require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/visible/
# (PDVisibleSigProperties, PDVisibleSignDesigner, PDFTemplateBuilder,
#  PDVisibleSigBuilder, PDFTemplateStructure, PDFTemplateCreator).
#
# Upstream has no unit test for this package: `TestCreateSignature` exercises it
# only through real CMS signing (`CreateVisibleSignature`), which needs a JKS
# keystore and the JCA provider and is out of scope here. These are therefore
# characterization assertions on the structure built by `PDFTemplateCreator`,
# derived from the Java source:
#
#   /AcroForm/Fields[0]                 signature field + widget (shared dict)
#     /AP/N                             holder form (BBox = formatter rect)
#       /Resources/XObject/FRM          inner form
#         /Resources/XObject/n0         blank background layer
#         /Resources/XObject/n2         image form (Matrix = designer transform)
#           /Resources/XObject/img1     the visible-signature image
#
# with the three appearance content streams written by
# `PDVisibleSigBuilder#injectAppearanceStreams`.
module Pdfbox::Pdmodel::Interactive::DigitalSignature::Visible
  HOLDER_CONTENT = "q 1 0 0 1 0 0 cm /FRM Do Q\n"
  INNER_CONTENT  = "q 1 0 0 1 0 0 cm /n0 Do Q q 1 0 0 1 0 0 cm /n2 Do Q\n"
  IMAGE_CONTENT  = "q 100 0 0 50 0 0 cm /img1 Do Q\n"
  PROC_SET_NAMES = ["PDF", "Text", "ImageB", "ImageC", "ImageI"]

  # Builds an opaque black RGBA image of the given size.
  def self.visible_signature_image(width : Int32 = 100, height : Int32 = 50) : CrImage::Image
    image = CrImage::RGBA.new(CrImage.rect(0, 0, width, height))
    height.times do |y|
      width.times do |x|
        image.set_rgba(x, y, CrImage::Color::RGBA.new(0_u8, 0_u8, 0_u8, 255_u8))
      end
    end
    image
  end

  # A 612 x 792 "LETTER" document, matching the page the designer measures.
  def self.visible_signature_document(rotation : Int32 = 0) : Pdfbox::Pdmodel::Document
    document = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(612.0, 792.0)
    page.rotation = rotation
    document.add_page(page)
    document
  end

  def self.cos_name(value : String) : Pdfbox::Cos::Name
    Pdfbox::Cos::Name.new(value)
  end

  def self.cos_dictionary(base : Pdfbox::Cos::Base?) : Pdfbox::Cos::Dictionary?
    base = base.object if base.is_a?(Pdfbox::Cos::Object)
    base.as?(Pdfbox::Cos::Dictionary)
  end

  # Reads a nested dictionary entry, dereferencing indirect objects.
  def self.entry(dictionary : Pdfbox::Cos::Dictionary, key : String) : Pdfbox::Cos::Base?
    dictionary.get_dictionary_object(cos_name(key))
  end

  def self.sub_dictionary(dictionary : Pdfbox::Cos::Dictionary, key : String) : Pdfbox::Cos::Dictionary?
    cos_dictionary(entry(dictionary, key))
  end

  def self.dictionary_entry(dictionary : Pdfbox::Cos::Dictionary, key : String) : Pdfbox::Cos::Dictionary
    sub_dictionary(dictionary, key).not_nil!
  end

  # The decoded appearance stream contents of a form XObject.
  def self.stream_contents(dictionary : Pdfbox::Cos::Dictionary) : String
    dictionary.as(Pdfbox::Cos::Stream).create_input_stream.gets_to_end
  end

  def self.matrix_values(matrix : Pdfbox::Util::Matrix) : Array(Float64)
    [
      matrix.get_value(0, 0), matrix.get_value(0, 1),
      matrix.get_value(1, 0), matrix.get_value(1, 1),
      matrix.get_value(2, 0), matrix.get_value(2, 1),
    ].map(&.to_f64)
  end

  describe PDVisibleSigProperties do
    it "has the documented defaults" do
      properties = PDVisibleSigProperties.new
      properties.signer_name.should be_nil
      properties.signer_location.should be_nil
      properties.signature_reason.should be_nil
      properties.visual_sign_enabled?.should be_false
      properties.page.should eq(0)
      properties.preferred_size.should eq(0)
      properties.visible_signature.should be_nil
      properties.pd_visible_signature.should be_nil
    end

    it "supports the fluent builder chain used by the upstream example" do
      properties = PDVisibleSigProperties.new
      chained = properties.signer_name("name")
        .signer_location("location")
        .signature_reason("Security")
        .preferred_size(1600)
        .page(2)
        .visual_sign_enabled(true)

      chained.should be(properties)
      properties.signer_name.should eq("name")
      properties.signer_location.should eq("location")
      properties.signature_reason.should eq("Security")
      properties.preferred_size.should eq(1600)
      properties.page.should eq(2)
      properties.visual_sign_enabled?.should be_true
    end
  end

  describe PDVisibleSignDesigner do
    it "measures the page and the image" do
      document = visible_signature_document
      designer = PDVisibleSignDesigner.new(document, visible_signature_image, 1)
      designer.page_width.should eq(612.0_f32)
      designer.page_height.should eq(792.0_f32)
      designer.width.should eq(100.0_f32)
      designer.height.should eq(50.0_f32)
      designer.template_height.should eq(792.0_f32)
      designer.image_size_in_percents.should eq(100.0_f32)
      designer.rotation.should eq(0)
      designer.signature_field_name.should eq("sig")
      designer.formatter_rectangle_parameters.should eq([0, 0, 100, 50])
      designer.x_axis.should eq(0.0_f32)
      designer.y_axis.should eq(0.0_f32)
      designer.transform.should be_a(Pdfbox::Util::Matrix)
      document.close
    end

    it "reads the image from a stream" do
      io = ::IO::Memory.new
      CrImage::PNG.write(io, visible_signature_image(20, 10))
      io.rewind

      designer = PDVisibleSignDesigner.new(io)
      designer.width.should eq(20.0_f32)
      designer.height.should eq(10.0_f32)
      designer.formatter_rectangle_parameters.should eq([0, 0, 20, 10])
      designer.image.should_not be_nil
    end

    it "rejects a page number below 1" do
      document = visible_signature_document
      expect_raises(ArgumentError, "First page of pdf is 1, not 0") do
        PDVisibleSignDesigner.new(document, visible_signature_image, 0)
      end
      document.close
    end

    it "zooms the image and the formatter rectangle" do
      document = visible_signature_document
      designer = PDVisibleSignDesigner.new(document, visible_signature_image, 1)
      designer.zoom(-50).should be(designer)
      designer.width.should eq(50.0_f32)
      designer.height.should eq(25.0_f32)
      designer.formatter_rectangle_parameters.should eq([0, 0, 50, 25])
      document.close
    end

    it "swaps the coordinates and builds the transform for a 90 degree rotation" do
      document = visible_signature_document(90)
      designer = PDVisibleSignDesigner.new(document, visible_signature_image, 1)
      designer.coordinates(100.0_f32, 200.0_f32)
      designer.adjust_for_rotation.should be(designer)

      designer.x_axis.should eq(200.0_f32)
      designer.y_axis.should eq(592.0_f32)
      designer.width.should eq(50.0_f32)
      designer.height.should eq(100.0_f32)
      matrix_values(designer.transform).should eq([0.0, 0.5, -2.0, 0.0, 100.0, 0.0])
      document.close
    end

    it "swaps the coordinates and builds the transform for a 270 degree rotation" do
      document = visible_signature_document(270)
      designer = PDVisibleSignDesigner.new(document, visible_signature_image, 1)
      designer.coordinates(100.0_f32, 200.0_f32)
      designer.adjust_for_rotation

      designer.x_axis.should eq(362.0_f32)
      designer.y_axis.should eq(100.0_f32)
      designer.width.should eq(50.0_f32)
      designer.height.should eq(100.0_f32)
      matrix_values(designer.transform).should eq([0.0, -0.5, 2.0, 0.0, 0.0, 50.0])
      document.close
    end

    it "moves the coordinates and builds the transform for a 180 degree rotation" do
      document = visible_signature_document(180)
      designer = PDVisibleSignDesigner.new(document, visible_signature_image, 1)
      designer.coordinates(100.0_f32, 200.0_f32)
      designer.adjust_for_rotation

      designer.x_axis.should eq(412.0_f32)
      designer.y_axis.should eq(542.0_f32)
      designer.width.should eq(100.0_f32)
      designer.height.should eq(50.0_f32)
      matrix_values(designer.transform).should eq([-1.0, 0.0, 0.0, -1.0, 100.0, 50.0])
      document.close
    end

    it "loads the signature image from a file" do
      path = "spec/resources/pdfbox/cos/simple.png"
      designer = PDVisibleSignDesigner.new(::IO::Memory.new(File.read(path)))
      designer.signature_image(path).should be(designer)
      designer.image.should_not be_nil
    end
  end

  describe PDFTemplateCreator do
    it "builds the holder/inner/image form structure" do
      document = visible_signature_document
      designer = PDVisibleSignDesigner.new(document, visible_signature_image, 1)
      properties = PDVisibleSigProperties.new
      properties.visual_sign_enabled(true).page(1).set_pd_visible_signature(designer)

      properties.build_signature
      bytes = properties.visible_signature.not_nil!
      visual = Pdfbox::Loader.load_pdf(bytes)

      visual.number_of_pages.should eq(1)
      page = visual.get_page(0)
      page.media_box.not_nil!.width.should eq(612.0)
      page.media_box.not_nil!.height.should eq(792.0)

      acro_form = visual.document_catalog.not_nil!.acro_form.not_nil!
      acro_form.signatures_exist?.should be_true
      acro_form.append_only?.should be_true
      acro_form.default_appearance.should eq("/sylfaen 0 Tf 0 g")

      acro_form.fields.size.should eq(1)
      field = acro_form.fields[0].as(Pdfbox::Pdmodel::Interactive::Form::PDSignatureField)
      field.field_type.should eq("Sig")

      widget = field.widgets[0]
      # /Rect from the designer coordinates (x=0, y=0, 100 x 50 on a 792 high page)
      rectangle = widget.rectangle.not_nil!
      rectangle.lower_left_x.should eq(0.0_f32)
      rectangle.lower_left_y.should eq(742.0_f32)
      rectangle.upper_right_x.should eq(100.0_f32)
      rectangle.upper_right_y.should eq(792.0_f32)

      widget_dictionary = widget.cos_object
      # Java PDFTemplateCreator#createWidgetDictionary: /DR = holder form resources
      dictionary_entry(widget_dictionary, "DR").should_not be_nil

      appearance = dictionary_entry(widget_dictionary, "AP")
      holder = dictionary_entry(appearance, "N")
      stream_contents(holder).should eq(HOLDER_CONTENT)
      holder.get_int(cos_name("FormType"), 0_i64).should eq(1)
      Pdfbox::Pdmodel::Common::PDRectangle.new(holder.get_array(cos_name("BBox")).not_nil!)
        .width.should eq(100.0_f32)

      holder_resources = dictionary_entry(holder, "Resources")
      holder_xobjects = dictionary_entry(holder_resources, "XObject")
      holder_xobjects.entries.keys.map(&.value).should eq(["FRM"])

      inner = dictionary_entry(holder_xobjects, "FRM")
      stream_contents(inner).should eq(INNER_CONTENT)
      inner_resources = dictionary_entry(inner, "Resources")
      inner_xobjects = dictionary_entry(inner_resources, "XObject")
      inner_xobjects.entries.keys.map(&.value).sort!.should eq(["n0", "n2"])

      image_form = dictionary_entry(inner_xobjects, "n2")
      stream_contents(image_form).should eq(IMAGE_CONTENT)
      matrix_values(Pdfbox::Util::Matrix.create_matrix(entry(image_form, "Matrix").not_nil!))
        .should eq([1.0, 0.0, 0.0, 1.0, 0.0, 0.0])

      image_xobjects = dictionary_entry(dictionary_entry(image_form, "Resources"), "XObject")
      image = dictionary_entry(image_xobjects, "img1")
      image.get_name_as_string(cos_name("Subtype")).should eq("Image")
      image.get_int(cos_name("Width"), 0_i64).should eq(100)
      image.get_int(cos_name("Height"), 0_i64).should eq(50)

      # Java PDFTemplateBuilder#createBackgroundLayerForm: blank n0 layer
      background = dictionary_entry(inner_xobjects, "n0")
      stream_contents(background).should eq("")
      background.get_int(cos_name("FormType"), 0_i64).should eq(1)

      # Java PDFTemplateBuilder#injectProcSetArray
      proc_set = holder_resources.get_array(cos_name("ProcSet")).not_nil!
      proc_set.items.map { |item| item.as(Pdfbox::Cos::Name).value }.should eq(PROC_SET_NAMES)
      page.cos_object.not_nil!.get_array(cos_name("ProcSet")).not_nil!.items.size.should eq(5)

      document.close
      visual.close
    end

    it "exposes the template structure through the builder" do
      builder = PDVisibleSigBuilder.new
      creator = PDFTemplateCreator.new(builder)
      structure = creator.pdf_structure
      structure.should be(builder.structure)
      structure.page.should be_nil
      structure.visual_signature.should be_nil
    end
  end

  describe SignatureOptions do
    it "reads the visual signature from the built properties" do
      document = visible_signature_document
      designer = PDVisibleSignDesigner.new(document, visible_signature_image, 1)
      properties = PDVisibleSigProperties.new
      properties.page(1).visual_sign_enabled(true).set_pd_visible_signature(designer)
      properties.build_signature

      options = SignatureOptions.new
      options.set_visual_signature(properties)
      options.visual_signature.should_not be_nil
      options.visual_signature.not_nil!.number_of_pages.should eq(1)

      document.close
      options.close
    end
  end
end
