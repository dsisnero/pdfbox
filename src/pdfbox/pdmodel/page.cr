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
    property resource_cache : ResourceCache?

    def initialize(cos_page : Cos::Dictionary? = nil)
      @cos_page = cos_page || default_page_dictionary
    end

    def cos_object : Cos::Dictionary?
      @cos_page
    end

    # Get page media box (boundaries). Java PDPage#getMediaBox: the box is
    # inherited from the /Pages nodes and US Letter is used when it is missing.
    def media_box : Rectangle?
      cos_page = @cos_page
      return unless cos_page

      base = inherited_attribute(Cos::Name.new("MediaBox"))
      box = rectangle_from(base)
      box || PageSizes::LETTER
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

    # Get page crop box. Java PDPage#getCropBox: inherited like the MediaBox,
    # clipped to it, and replaced by the MediaBox when absent.
    def crop_box : Rectangle?
      cos_page = @cos_page
      return media_box unless cos_page

      box = rectangle_from(inherited_attribute(Cos::Name.new("CropBox")))
      return media_box unless box

      clip_to_media_box(box)
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

    # The BleedBox, or the CropBox when unset. Java PDPage#getBleedBox.
    def bleed_box : Rectangle?
      page_box(Cos::Name.new("BleedBox")) || crop_box
    end

    # Sets the BleedBox; nil removes it. Java PDPage#setBleedBox.
    def bleed_box=(rect : Rectangle?) : Rectangle?
      set_page_box(Cos::Name.new("BleedBox"), rect)
    end

    # The TrimBox, or the CropBox when unset. Java PDPage#getTrimBox.
    def trim_box : Rectangle?
      page_box(Cos::Name.new("TrimBox")) || crop_box
    end

    # Sets the TrimBox; nil removes it. Java PDPage#setTrimBox.
    def trim_box=(rect : Rectangle?) : Rectangle?
      set_page_box(Cos::Name.new("TrimBox"), rect)
    end

    # The ArtBox, or the CropBox when unset. Java PDPage#getArtBox.
    def art_box : Rectangle?
      page_box(Cos::Name.new("ArtBox")) || crop_box
    end

    # Sets the ArtBox; nil removes it. Java PDPage#setArtBox.
    def art_box=(rect : Rectangle?) : Rectangle?
      set_page_box(Cos::Name.new("ArtBox"), rect)
    end

    # Reads a box array from the page dictionary, clipping it to the media box.
    private def page_box(name : Cos::Name) : Rectangle?
      cos_page = @cos_page
      return unless cos_page

      value = cos_page[name]?
      return unless value
      value = value.object if value.is_a?(Cos::Object)
      return unless value.is_a?(Cos::Array)
      return unless value.size == 4

      llx = to_float(value[0]?)
      lly = to_float(value[1]?)
      urx = to_float(value[2]?)
      ury = to_float(value[3]?)
      return unless llx && lly && urx && ury

      clip_to_media_box(Rectangle.new(llx, lly, urx, ury))
    end

    private def set_page_box(name : Cos::Name, rect : Rectangle?) : Rectangle?
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page
      if rect
        cos_page[name] = Cos::Array.new([
          Cos::Float.new(rect.lower_left_x),
          Cos::Float.new(rect.lower_left_y),
          Cos::Float.new(rect.upper_right_x),
          Cos::Float.new(rect.upper_right_y),
        ])
      else
        cos_page.delete(name)
      end
      rect
    end

    # Clips the given box to the bounds of the media box. Java PDPage#clipToMediaBox.
    private def clip_to_media_box(box : Rectangle) : Rectangle
      media = media_box
      return box unless media

      Rectangle.new(
        Math.max(media.lower_left_x, box.lower_left_x),
        Math.max(media.lower_left_y, box.lower_left_y),
        Math.min(media.upper_right_x, box.upper_right_x),
        Math.min(media.upper_right_y, box.upper_right_y)
      )
    end

    # Get the page additional actions. Java PDPage#getActions (creates /AA lazily).
    def actions : Interactive::Action::PDPageAdditionalActions
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page
      add_actions = cos_page.get_dictionary(Cos::Name.new("AA"))
      unless add_actions
        add_actions = Cos::Dictionary.new
        cos_page[Cos::Name.new("AA")] = add_actions
      end
      Interactive::Action::PDPageAdditionalActions.new(add_actions)
    end

    # Sets the page additional actions. Java PDPage#setActions.
    def actions=(actions : Interactive::Action::PDPageAdditionalActions) : Interactive::Action::PDPageAdditionalActions
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page
      cos_page[Cos::Name.new("AA")] = actions.cos_object
      actions
    end

    def matrix : Util::Matrix
      Util::Matrix.new
    end

    # Get page rotation. Java PDPage#getRotation: inherited from the /Pages
    # nodes, only multiples of 90 are accepted, normalized to 0..359.
    def rotation : Int32
      cos_page = @cos_page
      return 0 unless cos_page

      rotate = inherited_attribute(Cos::Name.new("Rotate"))
      angle = case rotate
              when Cos::Integer then rotate.value.to_i32
              when Cos::Float   then rotate.value.to_i32
              else                   return 0
              end
      return 0 unless angle % 90 == 0

      (angle % 360 + 360) % 360
    end

    # Set page rotation
    def rotation=(degrees : Int32) : Int32
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page
      cos_page[Cos::Name.new("Rotate")] = Cos::Integer.new(degrees)
      degrees
    end

    # The key of this page in the structural parent tree, or -1 if absent.
    # Java PDPage#getStructParents.
    def struct_parents : Int32
      cos_page = @cos_page
      return -1 unless cos_page
      cos_page.get_int(Cos::Name::STRUCT_PARENTS, -1_i64).to_i32
    end

    def struct_parents=(value : Int) : Int32
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page
      int_value = value.to_i32
      cos_page.set_int(Cos::Name::STRUCT_PARENTS, int_value)
      int_value
    end

    # Get page resources
    def resources : Resources?
      cos_page = @cos_page
      return unless cos_page

      resources_value = inherited_attribute(Cos::Name.new("Resources"))
      return unless resources_value

      if resources_value.is_a?(Cos::Object)
        resources_value = resources_value.object
      end

      return unless resources_value.is_a?(Cos::Dictionary)

      Resources.new(resources_value)
    end

    # Java PDPageTree#getInheritableAttribute for this page (inheritable page
    # attributes are defined on the /Pages nodes, PDF 32000-1 7.7.3.4).
    private def inherited_attribute(name : Cos::Name) : Cos::Base?
      cos_page = @cos_page
      return unless cos_page

      PDPageTree.get_inheritable_attribute(cos_page, name)
    end

    # Reads a four-number COS array as a rectangle, or nil.
    private def rectangle_from(base : Cos::Base?) : Rectangle?
      base = base.object if base.is_a?(Cos::Object)
      return unless base.is_a?(Cos::Array) && base.size == 4

      llx = to_float(base[0]?)
      lly = to_float(base[1]?)
      urx = to_float(base[2]?)
      ury = to_float(base[3]?)
      return unless llx && lly && urx && ury

      Rectangle.new(llx, lly, urx, ury)
    end

    # Java PDPage#clipToMediaBox.
    private def clip_to_media_box(box : Rectangle) : Rectangle
      media = media_box
      return box unless media

      Rectangle.new(
        Math.max(media.lower_left_x, box.lower_left_x),
        Math.max(media.lower_left_y, box.lower_left_y),
        Math.min(media.upper_right_x, box.upper_right_x),
        Math.min(media.upper_right_y, box.upper_right_y)
      )
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

    # The page's content streams (/Contents as a single stream or array).
    # Java PDPage#getContentStreams.
    def content_streams : Array(Cos::Stream)
      cos_page = @cos_page
      return [] of Cos::Stream unless cos_page

      base = cos_page[Cos::Name.new("Contents")]?
      base = base.object if base.is_a?(Cos::Object)
      case base
      when Cos::Stream
        [base]
      when Cos::Array
        base.items.compact_map do |item|
          item = item.object if item.is_a?(Cos::Object)
          item.as?(Cos::Stream)
        end
      else
        [] of Cos::Stream
      end
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

      # Handle indirect references
      if annots.is_a?(Cos::Object)
        annots = annots.object
      end

      unless annots.is_a?(Cos::Array)
        # Lazily create the Annots array in the page dictionary when missing,
        # so that add() writes it back (Java PDPage#getAnnotations behavior).
        cos_page = @cos_page || default_page_dictionary
        return Common::COSArrayList(Interactive::Annotation::PDAnnotation).new(cos_page, Cos::Name.new("Annots"))
      end

      # Convert COSArray to list of PDAnnotation
      actual_list = [] of Interactive::Annotation::PDAnnotation
      annots.items.each do |item|
        dict = item
        # Handle indirect references
        if dict.is_a?(Cos::Object)
          dict = dict.object
        end
        next unless dict.is_a?(Cos::Dictionary)

        actual_list << Interactive::Annotation::PDAnnotation.create_annotation(dict)
      end

      Common::COSArrayList(Interactive::Annotation::PDAnnotation).new(actual_list, annots)
    end

    # Get annotations filtered by the given predicate. Java PDPage#getAnnotations(AnnotationFilter).

    def get_annotations(&block : Interactive::Annotation::PDAnnotation -> Bool) : Common::COSArrayList(Interactive::Annotation::PDAnnotation)
      filtered = annotations.select(&block)
      Common::COSArrayList(Interactive::Annotation::PDAnnotation).new(filtered, Cos::Array.new)
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

    # Removes the page's resources (and nested form resources) from the cache.
    # Java PDPage#removePageResourceFromCache.
    def remove_page_resource_from_cache : Nil
      cache = @resource_cache
      return unless cache
      cos_page = @cos_page
      return unless cos_page

      remove_resources_from_cache(cache, cos_page.get_dictionary(Cos::Name.new("Resources")))
    end

    private def remove_resources_from_cache(cache : ResourceCache, resources : Cos::Dictionary?) : Nil
      return unless resources

      indirect_objects(resources, "ColorSpace").each { |ref| cache.remove_color_space(ref) }
      indirect_objects(resources, "ExtGState").each { |ref| cache.remove_ext_state(ref) }
      indirect_objects(resources, "Font").each { |ref| cache.remove_font(ref) }
      indirect_objects(resources, "Pattern").each { |ref| cache.remove_pattern(ref) }
      indirect_objects(resources, "Properties").each { |ref| cache.remove_properties(ref) }
      indirect_objects(resources, "Shading").each { |ref| cache.remove_shading(ref) }
      indirect_objects(resources, "XObject").each do |ref|
        removed = cache.remove_xobject(ref)
        next unless removed.is_a?(Graphics::Form::PDFormXObject)
        stream = removed.cos_object.as?(Cos::Stream)
        remove_resources_from_cache(cache, stream.try(&.get_dictionary(Cos::Name.new("Resources"))))
      end
    end

    private def indirect_objects(resources : Cos::Dictionary, kind : String) : Array(Cos::Object)
      dict = resources.get_dictionary(Cos::Name.new(kind))
      return [] of Cos::Object unless dict
      dict.entries.values.compact_map do |value|
        value.as?(Cos::Object)
      end
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

    # Get the user unit (Java PDPage#getUserUnit). Non-positive values fall back
    # to 1.0.
    def user_unit : Float32
      cos_page = @cos_page
      return 1.0_f32 unless cos_page
      value = cos_page.get_float(Cos::Name.new("UserUnit"), 1.0_f64).to_f32
      value > 0 ? value : 1.0_f32
    end

    # Set the user unit (Java PDPage#setUserUnit); must be positive.
    def user_unit=(user_unit : Float32) : Float32
      raise ArgumentError.new("User unit must be positive") if user_unit <= 0

      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page
      cos_page.set_float(Cos::Name.new("UserUnit"), user_unit.to_f64)
      user_unit
    end

    # Get the viewports (/VP); nil when absent (Java PDPage#getViewports).
    def viewports : Array(Interactive::Measurement::PDViewportDictionary)?
      cos_page = @cos_page
      return unless cos_page

      array = cos_page.get_array(Cos::Name.new("VP"))
      return unless array

      array.items.compact_map do |item|
        item = item.object if item.is_a?(Cos::Object)
        item.as?(Cos::Dictionary).try { |dict| Interactive::Measurement::PDViewportDictionary.new(dict) }
      end
    end

    # Set the viewports (/VP); nil removes the entry (Java PDPage#setViewports).
    def viewports=(viewports : Array(Interactive::Measurement::PDViewportDictionary)?) : Array(Interactive::Measurement::PDViewportDictionary)?
      cos_page = @cos_page || default_page_dictionary
      @cos_page = cos_page

      key = Cos::Name.new("VP")
      if viewports
        array = Cos::Array.new
        viewports.each { |viewport| array.add(viewport.cos_object) }
        cos_page.set_item(key, array)
      else
        cos_page.delete(key)
      end
      viewports
    end

    def thread_beads : Array(Interactive::Pagenavigation::PDThreadBead)
      cos_page = @cos_page
      return [] of Interactive::Pagenavigation::PDThreadBead unless cos_page

      beads_entry = cos_page["B"]?
      beads_entry = beads_entry.object if beads_entry.is_a?(Cos::Object)
      return [] of Interactive::Pagenavigation::PDThreadBead unless beads_entry.is_a?(Cos::Array)

      beads_array = beads_entry.as(Cos::Array)
      beads_array.items.compact_map do |item|
        item = item.object if item.is_a?(Cos::Object)
        if item.is_a?(Cos::Dictionary)
          Interactive::Pagenavigation::PDThreadBead.new(item)
        end
      end
    end
  end
end
