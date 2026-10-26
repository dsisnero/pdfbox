# Visible signature template construction.
#
# Ported from Apache PDFBox
# `org.apache.pdfbox.pdmodel.interactive.digitalsignature.visible`
# (`PDFTemplateBuilder`, `PDVisibleSigBuilder`, `PDFTemplateStructure`,
# `PDFTemplateCreator`, `PDVisibleSignDesigner`, `PDVisibleSigProperties`).
#
# Divergences, all forced by the platform:
#
# * `java.awt.image.BufferedImage` is `CrImage::Image`.
# * `java.awt.geom.AffineTransform` is `Pdfbox::Util::Matrix`.
# * `PDFTemplateStructure#visual_signature` holds the template `Document`
#   (Java holds its `COSDocument`), and `PDFTemplateCreator#build_pdf` saves it
#   to memory and returns the bytes (Java returns an `InputStream`).
# * `PDVisibleSigProperties#visible_signature` is the built `Bytes` rather than
#   the Java `InputStream`; `SignatureOptions#set_visual_signature` consumes it.
# * `PDVisibleSignDesigner` keeps the image size as 0 until an image is set
#   (Java keeps a null `Float` and throws a `NullPointerException` on `getWidth`).
module Pdfbox::Pdmodel::Interactive::DigitalSignature::Visible
  # Holds every object built by a `PDFTemplateBuilder` (Java PDFTemplateStructure).
  class PDFTemplateStructure
    property page : Pdfbox::Pdmodel::Page?
    property template : Pdfbox::Pdmodel::Document?
    property acro_form : Form::PDAcroForm?
    property signature_field : Form::PDSignatureField?
    property pd_signature : Form::PDSignature?
    property acro_form_dictionary : Cos::Dictionary?
    property signature_rectangle : Common::PDRectangle?
    property affine_transform : Util::Matrix?
    property proc_set : Cos::Array?
    property image : Graphics::Image::PDImageXObject?
    property formatter_rectangle : Common::PDRectangle?
    property holder_form_stream : Common::PDStream?
    property holder_form_resources : Pdfbox::Pdmodel::PDResources?
    property holder_form : Graphics::Form::PDFormXObject?
    property appearance_dictionary : Annotation::PDAppearanceDictionary?
    property inner_form_stream : Common::PDStream?
    property inner_form_resources : Pdfbox::Pdmodel::PDResources?
    property inner_form : Graphics::Form::PDFormXObject?
    property image_form_stream : Common::PDStream?
    property image_form_resources : Pdfbox::Pdmodel::PDResources?
    property acro_form_fields : Array(Form::PDField)?
    property inner_form_name : Cos::Name?
    property image_form_name : Cos::Name?
    property image_name : Cos::Name?
    property visual_signature : Pdfbox::Pdmodel::Document?
    property image_form : Graphics::Form::PDFormXObject?
    property widget_dictionary : Cos::Dictionary?

    # Java: "no constructor".
    def initialize
    end
  end

  # The visible signature design properties (Java PDVisibleSignDesigner).
  # Setters use `param()` instead of `setParam()` to allow chaining, as in Java.
  class PDVisibleSignDesigner
    getter image : CrImage::Image?
    getter x_axis : Float32
    getter y_axis : Float32
    getter page_height : Float32
    getter page_width : Float32
    getter signature_field_name : String
    getter formatter_rectangle_parameters : Array(Int32)
    getter image_size_in_percents : Float32
    getter rotation : Int32

    @image : CrImage::Image? = nil
    @image_width : Float32 = 0.0_f32
    @image_height : Float32 = 0.0_f32
    @x_axis : Float32 = 0.0_f32
    @y_axis : Float32 = 0.0_f32
    @page_height : Float32 = 0.0_f32
    @page_width : Float32 = 0.0_f32
    @signature_field_name : String = "sig"
    @formatter_rectangle_parameters : Array(Int32) = [0, 0, 100, 50]
    @transform : Util::Matrix = Util::Matrix.new
    @image_size_in_percents : Float32 = 0.0_f32
    @rotation : Int32 = 0

    # Java PDVisibleSignDesigner(String, InputStream, int): measures the page
    # size from a PDF file.
    def initialize(filename : String, image_stream : ::IO, page : Int32)
      read_image_stream(image_stream)
      calculate_page_size_from_file(filename, page)
    end

    # Java PDVisibleSignDesigner(RandomAccessRead, InputStream, int).
    def initialize(document_source : Pdfbox::IO::RandomAccessRead, image_stream : ::IO, page : Int32)
      read_image_stream(image_stream)
      calculate_page_size_from_random_access_read(document_source, page)
    end

    # Java PDVisibleSignDesigner(PDDocument, InputStream, int).
    def initialize(document : Pdfbox::Pdmodel::Document, image_stream : ::IO, page : Int32)
      read_image_stream(image_stream)
      calculate_page_size(document, page)
    end

    # Java PDVisibleSignDesigner(String, BufferedImage, int).
    def initialize(filename : String, image : CrImage::Image, page : Int32)
      set_image(image)
      calculate_page_size_from_file(filename, page)
    end

    # Java PDVisibleSignDesigner(RandomAccessRead, BufferedImage, int).
    def initialize(document_source : Pdfbox::IO::RandomAccessRead, image : CrImage::Image, page : Int32)
      set_image(image)
      calculate_page_size_from_random_access_read(document_source, page)
    end

    # Java PDVisibleSignDesigner(PDDocument, BufferedImage, int).
    def initialize(document : Pdfbox::Pdmodel::Document, image : CrImage::Image, page : Int32)
      set_image(image)
      calculate_page_size(document, page)
    end

    # Java PDVisibleSignDesigner(InputStream): usable for signing existing
    # signature fields, so no page size is calculated.
    def initialize(image_stream : ::IO)
      read_image_stream(image_stream)
    end

    # Adjust signature for page rotation. Call this after all x and y
    # coordinates have been set (Java adjustForRotation).
    def adjust_for_rotation : self
      case @rotation
      when 90
        # https://stackoverflow.com/a/34359956/535646
        temp = @y_axis
        @y_axis = @page_height - @x_axis - @image_width
        @x_axis = temp

        @transform = Util::Matrix.new(
          0.0_f32, @image_height / @image_width,
          -@image_width / @image_height, 0.0_f32,
          @image_width, 0.0_f32
        )

        temp = @image_height
        @image_height = @image_width
        @image_width = temp
      when 180
        new_x = @page_width - @x_axis - @image_width
        new_y = @page_height - @y_axis - @image_height
        @x_axis = new_x
        @y_axis = new_y

        @transform = Util::Matrix.new(-1.0_f32, 0.0_f32, 0.0_f32, -1.0_f32, @image_width, @image_height)
      when 270
        temp = @x_axis
        @x_axis = @page_width - @y_axis - @image_height
        @y_axis = temp

        @transform = Util::Matrix.new(
          0.0_f32, -@image_height / @image_width,
          @image_width / @image_height, 0.0_f32,
          0.0_f32, @image_height
        )

        temp = @image_height
        @image_height = @image_width
        @image_width = temp
      end
      self
    end

    # Reads the signature image from a file (Java signatureImage).
    def signature_image(path : String) : self
      File.open(path, "rb") { |file| read_image_stream(file) }
      self
    end

    # Zooms the signature image by the given percentage (Java zoom).
    def zoom(percent : Float32) : self
      @image_height += (@image_height * percent) / 100
      @image_width += (@image_width * percent) / 100
      @formatter_rectangle_parameters[2] = @image_width.to_i
      @formatter_rectangle_parameters[3] = @image_height.to_i
      self
    end

    # Java coordinates(float, float).
    def coordinates(x : Float32, y : Float32) : self
      x_axis(x)
      y_axis(y)
      self
    end

    # Java xAxis(float).
    def x_axis(value : Float32) : self
      @x_axis = value
      self
    end

    # Java yAxis(float).
    def y_axis(value : Float32) : self
      @y_axis = value
      self
    end

    # The signature image width (Java getWidth).
    def width : Float32
      @image_width
    end

    # Java width(float).
    def width(value : Float32) : self
      @image_width = value
      @formatter_rectangle_parameters[2] = value.to_i
      self
    end

    # The signature image height (Java getHeight).
    def height : Float32
      @image_height
    end

    # Java height(float).
    def height(value : Float32) : self
      @image_height = value
      @formatter_rectangle_parameters[3] = value.to_i
      self
    end

    # The template height, which is the page height (Java getTemplateHeight,
    # protected).
    def template_height : Float32
      page_height
    end

    # Java signatureFieldName(String).
    def signature_field_name(value : String) : self
      @signature_field_name = value
      self
    end

    # The affine transformation for the PDF Matrix (Java getTransform).
    def transform : Util::Matrix
      @transform
    end

    # Java transform(AffineTransform).
    def transform(value : Util::Matrix) : self
      @transform = value.clone
      self
    end

    # Java formatterRectangleParameters(int[]).
    def formatter_rectangle_parameters(params : Array(Int32)) : self
      @formatter_rectangle_parameters = params
      self
    end

    # Java imageSizeInPercents(float).
    def image_size_in_percents=(value : Float32) : Float32
      @image_size_in_percents = value
    end

    # Java getSignatureText: not implemented upstream either.
    def signature_text : String
      raise Cos::UnsupportedOperationError.new("That method is not yet implemented")
    end

    # Java signatureText(String): not implemented upstream either.
    def signature_text=(_value : String) : Nil
      raise Cos::UnsupportedOperationError.new("That method is not yet implemented")
    end

    private def calculate_page_size_from_file(filename : String, page : Int32) : Nil
      document = Pdfbox::Loader.load_pdf(filename)
      begin
        calculate_page_size(document, page)
      ensure
        document.close
      end
    end

    private def calculate_page_size_from_random_access_read(source : Pdfbox::IO::RandomAccessRead, page : Int32) : Nil
      document = Pdfbox::Loader.load_pdf(source)
      begin
        calculate_page_size(document, page)
      ensure
        document.close
      end
    end

    # Each page of a document can be a different size; the page size comes from
    # the media box (Java calculatePageSize).
    private def calculate_page_size(document : Pdfbox::Pdmodel::Document, page : Int32) : Nil
      if page < 1
        raise ArgumentError.new("First page of pdf is 1, not #{page}")
      end

      first_page = document.get_page(page - 1)
      media_box = first_page.media_box || PageSizes::LETTER
      @page_height = media_box.height.to_f32
      @page_width = media_box.width.to_f32
      @image_size_in_percents = 100.0_f32
      @rotation = first_page.rotation % 360
    end

    # Reads the image stream of the signature and sets the height and width
    # (Java readImageStream).
    private def read_image_stream(stream : ::IO) : Nil
      set_image(CrImage.read(stream))
    end

    # Sets the image and its height and width (Java setImage).
    private def set_image(image : CrImage::Image) : Nil
      @image = image
      bounds = image.bounds
      @image_height = bounds.height.to_f32
      @image_width = bounds.width.to_f32
      @formatter_rectangle_parameters[2] = bounds.width
      @formatter_rectangle_parameters[3] = bounds.height
    end
  end

  # The visible signature properties (Java PDVisibleSigProperties).
  class PDVisibleSigProperties
    getter signer_name : String?
    getter signer_location : String?
    getter signature_reason : String?
    getter page : Int32
    getter preferred_size : Int32
    getter visible_signature : Bytes?
    getter pd_visible_signature : PDVisibleSignDesigner?

    @visual_sign_enabled : Bool

    def initialize
      @signer_name = nil
      @signer_location = nil
      @signature_reason = nil
      @visual_sign_enabled = false
      @page = 0
      @preferred_size = 0
      @visible_signature = nil
      @pd_visible_signature = nil
    end

    # Builds the visible signature template PDF (Java buildSignature).
    def build_signature : Nil
      designer = @pd_visible_signature
      raise ArgumentError.new("pdVisibleSignature is null") unless designer

      builder = PDVisibleSigBuilder.new
      creator = PDFTemplateCreator.new(builder)
      @visible_signature = creator.build_pdf(designer)
      nil
    end

    # Java signerName(String).
    def signer_name(value : String) : self
      @signer_name = value
      self
    end

    # Java signerLocation(String).
    def signer_location(value : String) : self
      @signer_location = value
      self
    end

    # Java signatureReason(String).
    def signature_reason(value : String) : self
      @signature_reason = value
      self
    end

    # Java page(int): the 1-based page number the signature is placed on.
    def page(value : Int32) : self
      @page = value
      self
    end

    # Java preferredSize(int): the preferred signature size in bytes, or 0 to
    # use the default.
    def preferred_size(value : Int32) : self
      @preferred_size = value
      self
    end

    # Whether the visible signature is added (Java isVisualSignEnabled).
    def visual_sign_enabled? : Bool
      @visual_sign_enabled
    end

    # Java visualSignEnabled(boolean).
    def visual_sign_enabled(value : Bool) : self
      @visual_sign_enabled = value
      self
    end

    # Java setPdVisibleSignature.
    # ameba:disable Naming/AccessorMethodName
    def set_pd_visible_signature(designer : PDVisibleSignDesigner) : self
      @pd_visible_signature = designer
      self
    end

    # Java setVisibleSignature(InputStream).
    # ameba:disable Naming/AccessorMethodName
    def set_visible_signature(data : Bytes?) : Nil
      @visible_signature = data
    end
  end

  # Builds a visible signature template (Java PDFTemplateBuilder).
  abstract class PDFTemplateBuilder
    abstract def create_affine_transform(affine_transform : Util::Matrix) : Nil
    abstract def create_page(properties : PDVisibleSignDesigner) : Nil
    abstract def create_template(page : Pdfbox::Pdmodel::Page) : Nil
    abstract def create_acro_form(template : Pdfbox::Pdmodel::Document) : Nil
    abstract def create_signature_field(acro_form : Form::PDAcroForm) : Nil
    abstract def create_signature(signature_field : Form::PDSignatureField, page : Pdfbox::Pdmodel::Page, signer_name : String) : Nil
    abstract def create_acro_form_dictionary(acro_form : Form::PDAcroForm, signature_field : Form::PDSignatureField) : Nil
    abstract def create_signature_rectangle(signature_field : Form::PDSignatureField, properties : PDVisibleSignDesigner) : Nil
    abstract def create_proc_set_array : Nil
    abstract def create_signature_image(template : Pdfbox::Pdmodel::Document, image : CrImage::Image) : Nil
    abstract def create_formatter_rectangle(params : Array(Int32)) : Nil
    abstract def create_holder_form_stream(template : Pdfbox::Pdmodel::Document) : Nil
    abstract def create_holder_form_resources : Nil
    abstract def create_holder_form(resources : Pdfbox::Pdmodel::PDResources, stream : Common::PDStream, bbox : Common::PDRectangle) : Nil
    abstract def create_appearance_dictionary(holder_form : Graphics::Form::PDFormXObject, signature_field : Form::PDSignatureField) : Nil
    abstract def create_inner_form_stream(template : Pdfbox::Pdmodel::Document) : Nil
    abstract def create_inner_form_resource : Nil
    abstract def create_inner_form(resources : Pdfbox::Pdmodel::PDResources, stream : Common::PDStream, bbox : Common::PDRectangle) : Nil
    abstract def insert_inner_form_to_holder_resources(inner_form : Graphics::Form::PDFormXObject, holder_form_resources : Pdfbox::Pdmodel::PDResources) : Nil
    abstract def create_image_form_stream(template : Pdfbox::Pdmodel::Document) : Nil
    abstract def create_image_form_resources : Nil
    abstract def create_image_form(image_form_resources : Pdfbox::Pdmodel::PDResources, inner_form_resource : Pdfbox::Pdmodel::PDResources, image_form_stream : Common::PDStream, bbox : Common::PDRectangle, affine_transform : Util::Matrix, image : Graphics::Image::PDImageXObject) : Nil
    abstract def create_background_layer_form(inner_form_resource : Pdfbox::Pdmodel::PDResources, bbox : Common::PDRectangle) : Nil
    abstract def inject_proc_set_array(inner_form : Graphics::Form::PDFormXObject, page : Pdfbox::Pdmodel::Page, inner_form_resources : Pdfbox::Pdmodel::PDResources, image_form_resources : Pdfbox::Pdmodel::PDResources, holder_form_resources : Pdfbox::Pdmodel::PDResources, proc_set : Cos::Array) : Nil
    abstract def inject_appearance_streams(holder_form_stream : Common::PDStream, inner_form_stream : Common::PDStream, image_form_stream : Common::PDStream, image_form_name : Cos::Name, image_name : Cos::Name, inner_form_name : Cos::Name, properties : PDVisibleSignDesigner) : Nil
    abstract def create_visual_signature(template : Pdfbox::Pdmodel::Document) : Nil
    abstract def create_widget_dictionary(signature_field : Form::PDSignatureField, holder_form_resources : Pdfbox::Pdmodel::PDResources) : Nil
    abstract def structure : PDFTemplateStructure
    abstract def close_template(template : Pdfbox::Pdmodel::Document) : Nil
  end

  # Builds the signature PDF without keeping the elements; they are kept in the
  # PDF template structure (Java PDVisibleSigBuilder).
  class PDVisibleSigBuilder < PDFTemplateBuilder
    @structure : PDFTemplateStructure

    def initialize
      @structure = PDFTemplateStructure.new
    end

    def structure : PDFTemplateStructure
      @structure
    end

    def create_page(properties : PDVisibleSignDesigner) : Nil
      # Java `new PDPage(new PDRectangle(width, height))`; `Page.new` already
      # defaults the type and a LETTER media box, which is replaced here.
      page = Pdfbox::Pdmodel::Page.new
      page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(
        properties.page_width.to_f64, properties.page_height.to_f64
      )
      @structure.page = page
    end

    def create_template(page : Pdfbox::Pdmodel::Page) : Nil
      template = Pdfbox::Pdmodel::Document.new
      template.add_page(page)
      @structure.template = template
    end

    def create_acro_form(template : Pdfbox::Pdmodel::Document) : Nil
      acro_form = Form::PDAcroForm.new(template)
      if catalog = template.document_catalog
        catalog.acro_form = acro_form
      end
      @structure.acro_form = acro_form
    end

    def create_signature_field(acro_form : Form::PDAcroForm) : Nil
      @structure.signature_field = Form::PDSignatureField.new(acro_form)
    end

    def create_signature(signature_field : Form::PDSignatureField, page : Pdfbox::Pdmodel::Page, signer_name : String) : Nil
      pd_signature = Form::PDSignature.new
      widget = signature_field.widgets[0]
      signature_field.set_value(pd_signature)
      widget.page = page
      page.annotations.add(widget)
      pd_signature.name = signer_name unless signer_name.empty?
      @structure.pd_signature = pd_signature
    end

    def create_acro_form_dictionary(acro_form : Form::PDAcroForm, signature_field : Form::PDSignatureField) : Nil
      acro_form_dictionary = acro_form.cos_object
      acro_form.signatures_exist = true
      acro_form.append_only = true
      acro_form_dictionary.direct = true
      # Java `acroForm.getFields().add(signatureField)`; `#fields` rebuilds the
      # list here, so the field is added to the /Fields array directly.
      acro_form.add_field(signature_field)
      # WTF sylfaen? (Java comment)
      acro_form.default_appearance = "/sylfaen 0 Tf 0 g"
      @structure.acro_form_fields = acro_form.fields
      @structure.acro_form_dictionary = acro_form_dictionary
    end

    def create_signature_rectangle(signature_field : Form::PDSignatureField, properties : PDVisibleSignDesigner) : Nil
      rect = Common::PDRectangle.new
      rect.upper_right_x = properties.x_axis + properties.width
      rect.upper_right_y = properties.template_height - properties.y_axis
      rect.lower_left_y = properties.template_height - properties.y_axis - properties.height
      rect.lower_left_x = properties.x_axis
      signature_field.widgets[0].rectangle = rect
      @structure.signature_rectangle = rect
    end

    def create_affine_transform(affine_transform : Util::Matrix) : Nil
      @structure.affine_transform = affine_transform
    end

    def create_proc_set_array : Nil
      proc_set = Cos::Array.new
      proc_set.add(Cos::Name.new("PDF"))
      proc_set.add(Cos::Name.new("Text"))
      proc_set.add(Cos::Name.new("ImageB"))
      proc_set.add(Cos::Name.new("ImageC"))
      proc_set.add(Cos::Name.new("ImageI"))
      @structure.proc_set = proc_set
    end

    def create_signature_image(template : Pdfbox::Pdmodel::Document, image : CrImage::Image) : Nil
      @structure.image = Graphics::Image::LosslessFactory.create_from_image(template, image)
    end

    def create_formatter_rectangle(params : Array(Int32)) : Nil
      formatter_rectangle = Common::PDRectangle.new
      formatter_rectangle.lower_left_x = Math.min(params[0], params[2]).to_f32
      formatter_rectangle.lower_left_y = Math.min(params[1], params[3]).to_f32
      formatter_rectangle.upper_right_x = Math.max(params[0], params[2]).to_f32
      formatter_rectangle.upper_right_y = Math.max(params[1], params[3]).to_f32
      @structure.formatter_rectangle = formatter_rectangle
    end

    def create_holder_form_stream(template : Pdfbox::Pdmodel::Document) : Nil
      @structure.holder_form_stream = Common::PDStream.new(template)
    end

    def create_holder_form_resources : Nil
      @structure.holder_form_resources = Pdfbox::Pdmodel::PDResources.new
    end

    def create_holder_form(resources : Pdfbox::Pdmodel::PDResources, stream : Common::PDStream, bbox : Common::PDRectangle) : Nil
      holder_form = Graphics::Form::PDFormXObject.new(stream)
      holder_form.resources = resources
      holder_form.bbox = bbox
      holder_form.form_type = 1
      @structure.holder_form = holder_form
    end

    def create_appearance_dictionary(holder_form : Graphics::Form::PDFormXObject, signature_field : Form::PDSignatureField) : Nil
      appearance = Annotation::PDAppearanceDictionary.new
      appearance.cos_object.direct = true

      appearance_stream = Annotation::PDAppearanceStream.new(holder_form.cos_object.as(Cos::Dictionary))

      appearance.normal_appearance = appearance_stream
      signature_field.widgets[0].appearance = appearance
      @structure.appearance_dictionary = appearance
    end

    def create_inner_form_stream(template : Pdfbox::Pdmodel::Document) : Nil
      @structure.inner_form_stream = Common::PDStream.new(template)
    end

    def create_inner_form_resource : Nil
      @structure.inner_form_resources = Pdfbox::Pdmodel::PDResources.new
    end

    def create_inner_form(resources : Pdfbox::Pdmodel::PDResources, stream : Common::PDStream, bbox : Common::PDRectangle) : Nil
      inner_form = Graphics::Form::PDFormXObject.new(stream)
      inner_form.resources = resources
      inner_form.bbox = bbox
      inner_form.form_type = 1
      @structure.inner_form = inner_form
    end

    def insert_inner_form_to_holder_resources(inner_form : Graphics::Form::PDFormXObject, holder_form_resources : Pdfbox::Pdmodel::PDResources) : Nil
      holder_form_resources.put(Cos::Name.new("FRM"), inner_form)
      @structure.inner_form_name = Cos::Name.new("FRM")
    end

    def create_image_form_stream(template : Pdfbox::Pdmodel::Document) : Nil
      @structure.image_form_stream = Common::PDStream.new(template)
    end

    def create_image_form_resources : Nil
      @structure.image_form_resources = Pdfbox::Pdmodel::PDResources.new
    end

    def create_image_form(image_form_resources : Pdfbox::Pdmodel::PDResources, inner_form_resource : Pdfbox::Pdmodel::PDResources, image_form_stream : Common::PDStream, bbox : Common::PDRectangle, affine_transform : Util::Matrix, image : Graphics::Image::PDImageXObject) : Nil
      image_form = Graphics::Form::PDFormXObject.new(image_form_stream)
      image_form.bbox = bbox
      image_form.matrix = affine_transform
      image_form.resources = image_form_resources
      image_form.form_type = 1

      image_form_resources.cos_object.as(Cos::Dictionary).direct = true

      image_form_name = Cos::Name.new("n2")
      inner_form_resource.put(image_form_name, image_form)
      image_name = image_form_resources.add(image, "img")
      @structure.image_form = image_form
      @structure.image_form_name = image_form_name
      @structure.image_name = image_name
    end

    def create_background_layer_form(inner_form_resource : Pdfbox::Pdmodel::PDResources, bbox : Common::PDRectangle) : Nil
      # create blank n0 background layer form
      n0_form = Graphics::Form::PDFormXObject.new(Cos::Stream.new)
      n0_form.bbox = bbox
      n0_form.resources = Pdfbox::Pdmodel::PDResources.new
      n0_form.form_type = 1
      inner_form_resource.put(Cos::Name.new("n0"), n0_form)
    end

    def inject_proc_set_array(inner_form : Graphics::Form::PDFormXObject, page : Pdfbox::Pdmodel::Page, inner_form_resources : Pdfbox::Pdmodel::PDResources, image_form_resources : Pdfbox::Pdmodel::PDResources, holder_form_resources : Pdfbox::Pdmodel::PDResources, proc_set : Cos::Array) : Nil
      proc_set_name = Cos::Name.new("ProcSet")
      if inner_form_resource = inner_form.resources
        inner_form_resource.cos_object.as(Cos::Dictionary)[proc_set_name] = proc_set
      end
      if page_dictionary = page.cos_object
        page_dictionary[proc_set_name] = proc_set
      end
      inner_form_resources.cos_object.as(Cos::Dictionary)[proc_set_name] = proc_set
      image_form_resources.cos_object.as(Cos::Dictionary)[proc_set_name] = proc_set
      holder_form_resources.cos_object.as(Cos::Dictionary)[proc_set_name] = proc_set
    end

    def inject_appearance_streams(holder_form_stream : Common::PDStream, inner_form_stream : Common::PDStream, image_form_stream : Common::PDStream, image_form_name : Cos::Name, image_name : Cos::Name, inner_form_name : Cos::Name, properties : PDVisibleSignDesigner) : Nil
      # Use width and height of BBox as values for transformation matrix.
      formatter_rectangle = @structure.formatter_rectangle
      width = formatter_rectangle ? formatter_rectangle.width.to_i : 0
      height = formatter_rectangle ? formatter_rectangle.height.to_i : 0

      img_form_content = "q #{width} 0 0 #{height} 0 0 cm /#{image_name.value} Do Q\n"
      holder_form_content = "q 1 0 0 1 0 0 cm /#{inner_form_name.value} Do Q\n"
      inner_form_content = "q 1 0 0 1 0 0 cm /n0 Do Q q 1 0 0 1 0 0 cm /#{image_form_name.value} Do Q\n"

      append_raw_commands(holder_form_stream.create_output_stream, holder_form_content)
      append_raw_commands(inner_form_stream.create_output_stream, inner_form_content)
      append_raw_commands(image_form_stream.create_output_stream, img_form_content)
    end

    def append_raw_commands(io : ::IO, commands : String) : Nil
      io.write(commands.to_slice)
      io.close
    end

    def create_visual_signature(template : Pdfbox::Pdmodel::Document) : Nil
      @structure.visual_signature = template
    end

    def create_widget_dictionary(signature_field : Form::PDSignatureField, holder_form_resources : Pdfbox::Pdmodel::PDResources) : Nil
      widget_dictionary = signature_field.widgets[0].cos_object
      widget_dictionary.set_need_to_be_updated(true)
      widget_dictionary[Cos::Name.new("DR")] = holder_form_resources.cos_object
      @structure.widget_dictionary = widget_dictionary
    end

    def close_template(template : Pdfbox::Pdmodel::Document) : Nil
      template.close
      @structure.template.try(&.close)
    end
  end

  # Builds a PDF with a visible signature step by step (Java PDFTemplateCreator).
  class PDFTemplateCreator
    def initialize(@pdf_builder : PDFTemplateBuilder)
    end

    # Returns the PDF template structure (Java getPdfStructure).
    def pdf_structure : PDFTemplateStructure
      @pdf_builder.structure
    end

    # Builds the PDF holding the visible signature and returns it as bytes
    # (Java buildPDF, which returns a stream).
    def build_pdf(properties : PDVisibleSignDesigner) : Bytes
      structure = pdf_structure

      # we create array of [Text, ImageB, ImageC, ImageI]
      @pdf_builder.create_proc_set_array

      # create page
      @pdf_builder.create_page(properties)
      page = required(structure.page, "page")

      # create template
      @pdf_builder.create_template(page)
      template = required(structure.template, "template")

      begin
        # create /AcroForm
        @pdf_builder.create_acro_form(template)
        acro_form = required(structure.acro_form, "acroForm")
        # AcroForm contains signature fields
        @pdf_builder.create_signature_field(acro_form)
        signature_field = required(structure.signature_field, "signatureField")
        # The signature field is needed as a "holder" for the /AP tree, but the
        # /P and /V PDSignatureField entries are ignored by PDDocument#addSignature.
        @pdf_builder.create_signature(signature_field, page, "")
        # that is /AcroForm/DR entry
        @pdf_builder.create_acro_form_dictionary(acro_form, signature_field)
        # create AffineTransform
        @pdf_builder.create_affine_transform(properties.transform)
        transform = required(structure.affine_transform, "affineTransform")
        # rectangle, formatter, image. /AcroForm/DR/XObject contains that form
        @pdf_builder.create_signature_rectangle(signature_field, properties)
        @pdf_builder.create_formatter_rectangle(properties.formatter_rectangle_parameters)
        bbox = required(structure.formatter_rectangle, "formatterRectangle")
        @pdf_builder.create_signature_image(template, required(properties.image, "image"))
        # create form stream, form and resource.
        @pdf_builder.create_holder_form_stream(template)
        holder_form_stream = required(structure.holder_form_stream, "holderFormStream")
        @pdf_builder.create_holder_form_resources
        holder_form_resources = required(structure.holder_form_resources, "holderFormResources")
        @pdf_builder.create_holder_form(holder_form_resources, holder_form_stream, bbox)
        # that is /AP entry the appearance dictionary.
        @pdf_builder.create_appearance_dictionary(required(structure.holder_form, "holderForm"), signature_field)
        # inner form stream, form and resource (holder form contains inner form)
        @pdf_builder.create_inner_form_stream(template)
        @pdf_builder.create_inner_form_resource
        inner_form_resource = required(structure.inner_form_resources, "innerFormResources")
        @pdf_builder.create_inner_form(
          inner_form_resource,
          required(structure.inner_form_stream, "innerFormStream"),
          bbox
        )
        inner_form = required(structure.inner_form, "innerForm")
        # inner form must be in the holder form as we wrote
        @pdf_builder.insert_inner_form_to_holder_resources(inner_form, holder_form_resources)
        # Image form is in this structure: /AcroForm/DR/FRM/Resources/XObject/n2
        @pdf_builder.create_image_form_stream(template)
        image_form_stream = required(structure.image_form_stream, "imageFormStream")
        @pdf_builder.create_image_form_resources
        image_form_resources = required(structure.image_form_resources, "imageFormResources")
        @pdf_builder.create_image_form(
          image_form_resources, inner_form_resource, image_form_stream, bbox,
          transform, required(structure.image, "image")
        )
        @pdf_builder.create_background_layer_form(inner_form_resource, bbox)
        # now inject procSetArray
        @pdf_builder.inject_proc_set_array(
          inner_form, page, inner_form_resource, image_form_resources,
          holder_form_resources, required(structure.proc_set, "procSet")
        )
        image_form_name = required(structure.image_form_name, "imageFormName")
        image_name = required(structure.image_name, "imageName")
        inner_form_name = required(structure.inner_form_name, "innerFormName")
        # now create Streams of AP
        @pdf_builder.inject_appearance_streams(
          holder_form_stream,
          required(structure.inner_form_stream, "innerFormStream"),
          image_form_stream,
          image_form_name, image_name, inner_form_name, properties
        )
        @pdf_builder.create_visual_signature(template)
        @pdf_builder.create_widget_dictionary(signature_field, holder_form_resources)
        visual_signature_as_bytes(required(structure.visual_signature, "visualSignature"))
      ensure
        @pdf_builder.close_template(template)
      end
    end

    private def required(value : T?, name : String) : T forall T
      value || raise ArgumentError.new("#{name} is null")
    end

    private def visual_signature_as_bytes(document : Pdfbox::Pdmodel::Document) : Bytes
      io = ::IO::Memory.new
      document.save(io)
      io.to_slice.dup
    end
  end
end
