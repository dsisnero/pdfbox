module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAppearanceStream
    @stream : Cos::Dictionary

    def initialize(@stream : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @stream
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
