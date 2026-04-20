module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAppearanceStream
    @stream : Cos::Dictionary

    def initialize(@stream : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @stream
    end

    def stream_object : Cos::Stream?
      @stream.as?(Cos::Stream)
    end

    def require_stream_object : Cos::Stream
      stream_object || raise ArgumentError.new("Appearance stream must wrap a COS stream")
    end

    def bbox : Common::PDRectangle?
      @stream.get_array(Cos::Name.new("BBox")).try do |array|
        Common::PDRectangle.new(array)
      end
    end

    def bbox=(rectangle : Common::PDRectangle) : Common::PDRectangle
      @stream[Cos::Name.new("BBox")] = rectangle.cos_object
      rectangle
    end

    def matrix : Util::Matrix
      base = @stream[Cos::Name.new("Matrix")]?
      return Util::Matrix.new unless base

      Util::Matrix.create_matrix(base)
    end

    def matrix=(matrix : Util::Matrix) : Util::Matrix
      array = Cos::Array.new
      array.add(Cos::Float.new(matrix.get_value(0, 0)))
      array.add(Cos::Float.new(matrix.get_value(0, 1)))
      array.add(Cos::Float.new(matrix.get_value(1, 0)))
      array.add(Cos::Float.new(matrix.get_value(1, 1)))
      array.add(Cos::Float.new(matrix.get_value(2, 0)))
      array.add(Cos::Float.new(matrix.get_value(2, 1)))
      @stream[Cos::Name.new("Matrix")] = array
      matrix
    end

    def resources : Pdfbox::Pdmodel::PDResources?
      @stream.get_dictionary(Cos::Name.new("Resources")).try do |dictionary|
        Pdfbox::Pdmodel::PDResources.new(dictionary)
      end
    end

    def resources=(value : Pdfbox::Pdmodel::PDResources) : Pdfbox::Pdmodel::PDResources
      @stream[Cos::Name.new("Resources")] = value.cos_object
      value
    end

    def content_stream : Common::PDStream
      Common::PDStream.new(require_stream_object)
    end
  end

  class PDAppearanceEntry
    @entry : Cos::Dictionary

    def initialize(@entry : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @entry
    end

    def sub_dictionary? : Bool
      !@entry.is_a?(Cos::Stream)
    end

    def stream? : Bool
      @entry.is_a?(Cos::Stream)
    end

    def appearance_stream : PDAppearanceStream
      raise "This entry is not an appearance stream" unless stream?

      PDAppearanceStream.new(@entry)
    end

    def sub_dictionary : Hash(Cos::Name, PDAppearanceStream)
      raise "This entry is not an appearance subdictionary" unless sub_dictionary?

      map = {} of Cos::Name => PDAppearanceStream
      @entry.entries.each do |name, value|
        if stream = value.as?(Cos::Dictionary)
          map[name] = PDAppearanceStream.new(stream)
        end
      end
      map
    end
  end

  class PDAppearanceDictionary
    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
      @dictionary[Cos::Name.new("N")] = Cos::Dictionary.new
    end

    def initialize(@dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    def normal_appearance : PDAppearanceEntry?
      @dictionary[Cos::Name.new("N")]?.as?(Cos::Dictionary).try { |entry| PDAppearanceEntry.new(entry) }
    end

    def normal_appearance=(entry : PDAppearanceEntry) : PDAppearanceEntry
      @dictionary[Cos::Name.new("N")] = entry.cos_object
      entry
    end

    def normal_appearance=(appearance_stream : PDAppearanceStream) : PDAppearanceStream
      @dictionary[Cos::Name.new("N")] = appearance_stream.cos_object
      appearance_stream
    end

    def rollover_appearance : PDAppearanceEntry?
      @dictionary[Cos::Name.new("R")]?.as?(Cos::Dictionary).try { |entry| PDAppearanceEntry.new(entry) } || normal_appearance
    end

    def rollover_appearance=(entry : PDAppearanceEntry) : PDAppearanceEntry
      @dictionary[Cos::Name.new("R")] = entry.cos_object
      entry
    end

    def rollover_appearance=(appearance_stream : PDAppearanceStream) : PDAppearanceStream
      @dictionary[Cos::Name.new("R")] = appearance_stream.cos_object
      appearance_stream
    end

    def down_appearance : PDAppearanceEntry?
      @dictionary[Cos::Name.new("D")]?.as?(Cos::Dictionary).try { |entry| PDAppearanceEntry.new(entry) } || normal_appearance
    end

    def down_appearance=(entry : PDAppearanceEntry) : PDAppearanceEntry
      @dictionary[Cos::Name.new("D")] = entry.cos_object
      entry
    end

    def down_appearance=(appearance_stream : PDAppearanceStream) : PDAppearanceStream
      @dictionary[Cos::Name.new("D")] = appearance_stream.cos_object
      appearance_stream
    end
  end
end
