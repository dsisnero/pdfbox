# PDPage implementation for PDFBox Crystal
#
# Represents a page in a PDF document.
# Corresponds to PDPage in Apache PDFBox.

require "../cos"
require "../util"

module Pdfbox::Pdmodel
  # PDF page class
  class Page
    @cos_page : Cos::Dictionary?

    def initialize(cos_page : Cos::Dictionary? = nil)
      @cos_page = cos_page || default_page_dictionary
    end

    def cos_object : Cos::Dictionary?
      @cos_page
    end

    # Get page media box (boundaries)
    def media_box : Rectangle?
      cos_page = @cos_page
      return unless cos_page

      media_box = cos_page[Cos::Name.new("MediaBox")]
      return unless media_box

      if media_box.is_a?(Cos::Object)
        media_box = media_box.object
      end

      return unless media_box.is_a?(Cos::Array)
      return unless media_box.size == 4

      llx = to_float(media_box[0]?)
      lly = to_float(media_box[1]?)
      urx = to_float(media_box[2]?)
      ury = to_float(media_box[3]?)
      return unless llx && lly && urx && ury

      Rectangle.new(llx, lly, urx, ury)
    end

    # Set page media box
    def media_box=(rect : Rectangle) : Rectangle
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page

      cos_page[Cos::Name.new("MediaBox")] = Cos::Array.new([
        Cos::Float.new(rect.lower_left_x),
        Cos::Float.new(rect.lower_left_y),
        Cos::Float.new(rect.upper_right_x),
        Cos::Float.new(rect.upper_right_y),
      ])
      rect
    end

    # Get page crop box
    def crop_box : Rectangle?
      cos_page = @cos_page
      return media_box unless cos_page

      crop_box = cos_page[Cos::Name.new("CropBox")]?
      return media_box unless crop_box

      if crop_box.is_a?(Cos::Object)
        crop_box = crop_box.object
      end

      return media_box unless crop_box.is_a?(Cos::Array)
      return media_box unless crop_box.size == 4

      llx = to_float(crop_box[0]?)
      lly = to_float(crop_box[1]?)
      urx = to_float(crop_box[2]?)
      ury = to_float(crop_box[3]?)
      return media_box unless llx && lly && urx && ury

      Rectangle.new(llx, lly, urx, ury)
    end

    # Set page crop box
    def crop_box=(rect : Rectangle) : Rectangle
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page

      cos_page[Cos::Name.new("CropBox")] = Cos::Array.new([
        Cos::Float.new(rect.lower_left_x),
        Cos::Float.new(rect.lower_left_y),
        Cos::Float.new(rect.upper_right_x),
        Cos::Float.new(rect.upper_right_y),
      ])
      rect
    end

    def bbox : Rectangle?
      crop_box
    end

    def matrix : Util::Matrix
      Util::Matrix.new
    end

    # Get page rotation
    def rotation : Int32
      cos_page = @cos_page
      return 0 unless cos_page

      rotate = cos_page[Cos::Name.new("Rotate")]?
      return 0 unless rotate

      if rotate.is_a?(Cos::Object)
        rotate = rotate.object
      end

      case rotate
      when Cos::Integer
        rotate.value.to_i32
      when Cos::Float
        rotate.value.to_i32
      else
        0
      end
    end

    # Set page rotation
    def rotation=(degrees : Int32) : Int32
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page
      cos_page[Cos::Name.new("Rotate")] = Cos::Integer.new(degrees)
      degrees
    end

    # Get page resources
    def resources : Resources?
      cos_page = @cos_page
      return unless cos_page

      resources_value = cos_page[Cos::Name.new("Resources")]
      return unless resources_value

      # Handle indirect references
      if resources_value.is_a?(Cos::Object)
        resources_value = resources_value.object
      end

      return unless resources_value.is_a?(Cos::Dictionary)

      Resources.new(resources_value)
    end

    # Set page resources
    def resources=(resources : Resources) : Nil
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page
      cos_page[Cos::Name.new("Resources")] = resources.cos_object
    end

    # Get page contents stream
    def contents : Cos::Stream?
      cos_page = @cos_page
      return unless cos_page

      contents = cos_page[Cos::Name.new("Contents")]
      return unless contents

      if contents.is_a?(Cos::Object)
        contents = contents.object
      end

      if contents.is_a?(Cos::Array)
        first = contents[0]?
        if first.is_a?(Cos::Object)
          first = first.object
        end
        return first.as?(Cos::Stream)
      end

      contents.as?(Cos::Stream)
    end

    # Set page contents stream
    def contents=(stream : Cos::Stream) : Cos::Stream
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page
      cos_page[Cos::Name.new("Contents")] = stream
      stream
    end

    def contents_base : Cos::Base?
      cos_page = @cos_page
      return unless cos_page
      cos_page[Cos::Name.new("Contents")]?
    end

    def has_contents? : Bool
      !contents.nil?
    end

    # Get annotations on this page
    def annotations : Common::COSArrayList(Interactive::Annotation::PDAnnotation)
      annots = @cos_page.try(&.[Cos::Name.new("Annots")])
      return Common::COSArrayList(Interactive::Annotation::PDAnnotation).new unless annots

      # Handle indirect references
      if annots.is_a?(Cos::Object)
        annots = annots.object
      end

      return Common::COSArrayList(Interactive::Annotation::PDAnnotation).new unless annots.is_a?(Cos::Array)

      # Convert COSArray to list of PDAnnotation
      actual_list = [] of Interactive::Annotation::PDAnnotation
      annots.items.each do |item|
        dict = item
        # Handle indirect references
        if dict.is_a?(Cos::Object)
          dict = dict.object
        end
        next unless dict.is_a?(Cos::Dictionary)

        # Check subtype and create appropriate annotation
        subtype = dict[Cos::Name.new("Subtype")]
        if subtype.is_a?(Cos::Name)
          case subtype.value
          when "Highlight"
            actual_list << Interactive::Annotation::PDAnnotationHighlight.new(dict)
          when "Link"
            actual_list << Interactive::Annotation::PDAnnotationLink.new(dict)
          when "Circle"
            actual_list << Interactive::Annotation::PDAnnotationCircle.new(dict)
          when "Square"
            actual_list << Interactive::Annotation::PDAnnotationSquare.new(dict)
          else
            # Generic annotation as fallback
            actual_list << Interactive::Annotation::PDAnnotation.new(dict)
          end
        else
          # No subtype, create generic annotation
          actual_list << Interactive::Annotation::PDAnnotation.new(dict)
        end
      end

      Common::COSArrayList(Interactive::Annotation::PDAnnotation).new(actual_list, annots)
    end

    # Set annotations on this page
    def annotations=(annotations : Enumerable(Interactive::Annotation::PDAnnotation)) : Nil
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page

      array = Cos::Array.new
      annotations.each do |annot|
        array.add(annot.cos_object)
      end
      cos_page[Cos::Name.new("Annots")] = array
    end

    def transition : Interactive::Pagenavigation::PDTransition?
      cos_page = @cos_page
      return unless cos_page

      transition_value = cos_page[Cos::Name.new("Trans")]
      return unless transition_value

      if transition_value.is_a?(Cos::Object)
        transition_value = transition_value.object
      end

      return unless transition_value.is_a?(Cos::Dictionary)

      Interactive::Pagenavigation::PDTransition.new(transition_value)
    end

    def transition=(transition : Interactive::Pagenavigation::PDTransition?) : Interactive::Pagenavigation::PDTransition?
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page

      key = Cos::Name.new("Trans")
      if transition
        cos_page[key] = transition.cos_object
      else
        cos_page.delete(key)
      end
      transition
    end

    def set_transition(transition : Interactive::Pagenavigation::PDTransition, duration : Int | Float) : Nil
      self.transition = transition
      (@cos_page || default_page_dictionary).set_float(Cos::Name.new("Dur"), duration.to_f64)
    end

    private def default_page_dictionary : Cos::Dictionary
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("Type")] = Cos::Name.new("Page")
      dict[Cos::Name.new("MediaBox")] = Cos::Array.new([
        Cos::Float.new(0.0_f64),
        Cos::Float.new(0.0_f64),
        Cos::Float.new(612.0_f64),
        Cos::Float.new(792.0_f64),
      ])
      dict
    end

    private def to_float(base : Cos::Base?) : Float64?
      return unless base
      case base
      when Cos::Integer
        base.value.to_f64
      when Cos::Float
        base.value
      end
    end

    # Get XMP metadata from page
    # Java equivalent: PDPage.getMetadata()
    def metadata : Pdmodel::Common::PDMetadata?
      cos_page = @cos_page
      return unless cos_page
      meta_obj = cos_page.get_stream(Cos::Name.new("Metadata"))
      meta_obj ? Pdmodel::Common::PDMetadata.new(meta_obj) : nil
    end
  end
end
