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

    def pattern(name : Pdfbox::Cos::Name) : Graphics::Pattern::PDTilingPattern?
      resource_entry("Pattern", name).as?(Pdfbox::Cos::Stream).try do |stream|
        Graphics::Pattern::PDTilingPattern.new(stream, @resource_cache)
      end
    end

    def xobject_names : Array(Pdfbox::Cos::Name)
      resource_names("XObject")
    end

    def pattern_names : Array(Pdfbox::Cos::Name)
      resource_names("Pattern")
    end

    def add(form : Graphics::Form::PDFormXObject, prefix : String = "Form") : Pdfbox::Cos::Name
      add_resource("XObject", form.cos_object, prefix)
    end

    def add(pattern : Graphics::Pattern::PDTilingPattern, prefix : String = "Pattern") : Pdfbox::Cos::Name
      add_resource("Pattern", pattern.cos_object, prefix)
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
