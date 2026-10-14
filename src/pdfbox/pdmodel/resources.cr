require "../cos"
require "./resource_cache"

module Pdfbox::Pdmodel
  class PDResources
    include Pdfbox::Pdmodel::Common::COSObjectable

    @dict : Pdfbox::Cos::Dictionary
    @resource_cache : ResourceCache?

    def initialize
      @dict = Pdfbox::Cos::Dictionary.new
      @resource_cache = nil
    end

    def initialize(@dict : Pdfbox::Cos::Dictionary, @resource_cache : ResourceCache? = nil)
    end

    def cos_object : Pdfbox::Cos::Base
      @dict
    end

    def resource_cache : ResourceCache?
      @resource_cache
    end

    def font(name : Pdfbox::Cos::Name) : Pdfbox::Cos::Base?
      resource_entry("Font", name)
    end

    def get_font(name : Pdfbox::Cos::Name) : Pdfbox::Pdmodel::Font::PDFont?
      entry = font(name)
      return unless entry
      dictionary = entry.is_a?(Pdfbox::Cos::Object) ? entry.object : entry
      return unless dictionary.is_a?(Pdfbox::Cos::Dictionary)
      Pdfbox::Pdmodel::Font::PDFontFactory.create_font(dictionary, @resource_cache)
    end

    def add(font : Pdfbox::Pdmodel::Font::PDFont) : Pdfbox::Cos::Name
      add_resource("Font", font.cos_object, "F")
    end

    def put(name : Pdfbox::Cos::Name, font : Pdfbox::Pdmodel::Font::PDFont) : Pdfbox::Cos::Name
      subdictionary("Font")[name] = font.cos_object
      name
    end

    def font_names : Array(Pdfbox::Cos::Name)
      resource_names("Font")
    end

    def ext_g_state(name : Pdfbox::Cos::Name) : Graphics::State::PDExtendedGraphicsState?
      resource_entry("ExtGState", name).as?(Pdfbox::Cos::Dictionary).try do |dictionary|
        Graphics::State::PDExtendedGraphicsState.new(dictionary)
      end
    end

    def ext_g_state_names : Array(Pdfbox::Cos::Name)
      resource_names("ExtGState")
    end

    def xobject(name : Pdfbox::Cos::Name) : Pdfbox::Cos::Base?
      resource_entry("XObject", name)
    end

    def pattern(name : Pdfbox::Cos::Name) : Graphics::Pattern::PDAbstractPattern?
      entry = resource_entry("Pattern", name)
      return unless entry
      dict = entry.as?(Pdfbox::Cos::Dictionary)
      dict ? Graphics::Pattern::PDAbstractPattern.create(dict, @resource_cache) : nil
    end

    def xobject_names : Array(Pdfbox::Cos::Name)
      resource_names("XObject")
    end

    def pattern_names : Array(Pdfbox::Cos::Name)
      resource_names("Pattern")
    end

    # The color space resource (/ColorSpace), or nil (Java getColorSpace).
    def color_space(name : Pdfbox::Cos::Name) : Graphics::Color::PDColorSpace?
      base = resource_entry("ColorSpace", name)
      base ? Graphics::Color::PDColorSpace.create(base) : nil
    end

    # Whether a color space with the given name exists (Java hasColorSpace).
    def has_color_space?(name : Pdfbox::Cos::Name) : Bool
      !resource_entry("ColorSpace", name).nil?
    end

    def color_space_names : Array(Pdfbox::Cos::Name)
      resource_names("ColorSpace")
    end

    # The property list resource (/Properties), or nil (Java getProperties).
    def properties(name : Pdfbox::Cos::Name) : DocumentInterchange::MarkedContent::PDPropertyList?
      base = resource_entry("Properties", name)
      dict = base.is_a?(Pdfbox::Cos::Object) ? base.object : base
      dict.is_a?(Pdfbox::Cos::Dictionary) ? DocumentInterchange::MarkedContent::PDPropertyList.create(dict) : nil
    end

    def properties_names : Array(Pdfbox::Cos::Name)
      resource_names("Properties")
    end

    def shading_names : Array(Pdfbox::Cos::Name)
      resource_names("Shading")
    end

    def add(form : Graphics::Form::PDFormXObject, prefix : String = "Form") : Pdfbox::Cos::Name
      add_resource("XObject", form.cos_object, prefix)
    end

    def add(pattern : Graphics::Pattern::PDAbstractPattern, prefix : String = "Pattern") : Pdfbox::Cos::Name
      add_resource("Pattern", pattern.cos_object, prefix)
    end

    # Returns the shading resource, or nil. Java PDResources#getShading.
    def shading(name : Pdfbox::Cos::Name) : Graphics::Shading::PDShading?
      base = resource_entry("Shading", name)
      return unless base
      dict = base.as?(Pdfbox::Cos::Dictionary)
      dict ? Graphics::Shading::PDShading.create(dict) : nil
    end

    # Adds a shading to the resources (name prefix "sh"). Java PDResources#add(PDShading).
    def add(shading : Graphics::Shading::PDShading) : Pdfbox::Cos::Name
      add_resource("Shading", shading.cos_object, "sh")
    end

    # Adds a property list to the resources. Java PDResources#add(PDPropertyList):
    # optional content groups use prefix "oc", other property lists "Prop".
    def add(properties : DocumentInterchange::MarkedContent::PDPropertyList) : Pdfbox::Cos::Name
      prefix = properties.is_a?(Graphics::OptionalContent::PDOptionalContentGroup) ? "oc" : "Prop"
      add_resource("Properties", properties.cos_object, prefix)
    end

    def put(name : Pdfbox::Cos::Name, state : Graphics::State::PDExtendedGraphicsState) : Graphics::State::PDExtendedGraphicsState
      subdictionary("ExtGState")[name] = state.cos_object
      state
    end

    private def resource_entry(group_name : String, name : Pdfbox::Cos::Name) : Pdfbox::Cos::Base?
      dictionary = @dict[Pdfbox::Cos::Name.new(group_name)]?
      return unless dictionary
      dictionary = dictionary.object if dictionary.is_a?(Pdfbox::Cos::Object)
      return unless dictionary.is_a?(Pdfbox::Cos::Dictionary)

      entry = dictionary[name]?
      return unless entry
      entry.is_a?(Pdfbox::Cos::Object) ? entry.object : entry
    end

    private def resource_names(group_name : String) : Array(Pdfbox::Cos::Name)
      dictionary = @dict[Pdfbox::Cos::Name.new(group_name)]?
      return [] of Pdfbox::Cos::Name unless dictionary
      dictionary = dictionary.object if dictionary.is_a?(Pdfbox::Cos::Object)
      return [] of Pdfbox::Cos::Name unless dictionary.is_a?(Pdfbox::Cos::Dictionary)

      dictionary.entries.keys
    end

    private def add_resource(group_name : String, resource : Pdfbox::Cos::Base, prefix : String) : Pdfbox::Cos::Name
      dictionary = subdictionary(group_name)
      index = 1
      while dictionary.has_key?(Pdfbox::Cos::Name.new("#{prefix}#{index}"))
        index += 1
      end

      name = Pdfbox::Cos::Name.new("#{prefix}#{index}")
      dictionary[name] = resource
      name
    end

    private def subdictionary(group_name : String) : Pdfbox::Cos::Dictionary
      key = Pdfbox::Cos::Name.new(group_name)
      dictionary = @dict[key]?
      unless dictionary
        dictionary = Pdfbox::Cos::Dictionary.new
        @dict[key] = dictionary
      end
      dictionary = dictionary.object if dictionary.is_a?(Pdfbox::Cos::Object)
      dictionary.as(Pdfbox::Cos::Dictionary)
    end
  end
end
