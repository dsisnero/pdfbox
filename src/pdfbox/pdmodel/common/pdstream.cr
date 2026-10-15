# PDStream represents a stream in a PDF document.
# Streams are tied to a single PDF document.
require "../../cos"
require "../document"

module Pdfbox::Pdmodel::Common
  class PDStream
    @stream : Cos::Stream

    # Creates a PDStream which wraps the given COSStream
    def initialize(@stream : Cos::Stream)
    end

    # Creates a new empty PDStream object attached to a COSDocument
    def initialize(document : Cos::Document)
      @stream = document.create_cos_stream
    end

    # Creates a new empty PDStream object attached to the given document
    def initialize(document : Pdmodel::PDDocument)
      @stream = document.document.create_cos_stream
    end

    # Creates a PDStream from input data, copying into a new stream
    def initialize(document : Pdmodel::PDDocument, input : ::IO)
      @stream = document.document.create_cos_stream
      output = @stream.create_output_stream
      ::IO.copy(input, output)
      output.close
    end

    # Creates a PDStream from input data with a single filter
    def initialize(document : Pdmodel::PDDocument, input : ::IO, filter : Cos::Name)
      @stream = document.document.create_cos_stream
      output = @stream.create_output_stream(filter)
      ::IO.copy(input, output)
      output.close
    end

    # Creates a PDStream from input data with multiple filters
    def initialize(document : Pdmodel::PDDocument, input : ::IO, filters : Cos::Array)
      @stream = document.document.create_cos_stream
      output = @stream.create_output_stream(filters)
      ::IO.copy(input, output)
      output.close
    end

    # Creates a PDStream from input data with optional filters (nil, Cos::Name, or Cos::Array)
    def initialize(document : Pdmodel::PDDocument, input : ::IO, filters : Cos::Base?)
      @stream = document.document.create_cos_stream
      output = @stream.create_output_stream(filters)
      ::IO.copy(input, output)
      output.close
    end

    # Get the cos stream associated with this object
    def cos_object : Cos::Stream
      @stream
    end

    # This will get a stream that can be written to
    def create_output_stream : ::IO
      @stream.create_output_stream
    end

    # This will get a stream that can be written to, with the given filter
    def create_output_stream(filter : Cos::Name) : ::IO
      @stream.create_output_stream(filter)
    end

    # This will get a stream that can be read from
    def create_input_stream : ::IO
      @stream.create_input_stream
    end

    # This will get a stream with some filters applied but not others
    def create_input_stream(stop_filters : Array(String)?) : ::IO
      @stream.create_input_stream(stop_filters || [] of String)
    end

    # This will get the length of the filtered/compressed stream
    def length : Int32
      @stream.get_int(Cos::Name::LENGTH, 0).to_i32
    end

    # This will get the list of filters that are associated with this stream
    # Returns an empty array if there are no filters
    def filters : Array(Cos::Name)
      filters_base = @stream[Cos::Name::FILTER]

      case filters_base
      when Cos::Name
        [filters_base]
      when Cos::Array
        filters_base.items.map { |item| item.as(Cos::Name) }
      else
        [] of Cos::Name
      end
    end

    # This will set the filters that are part of this stream
    def filters=(filters : Array(Cos::Name))
      @stream[Cos::Name::FILTER] = Cos::Array.new(filters)
    end

    # This will copy the stream into a byte array
    def to_byte_array : Bytes
      io = create_input_stream
      io.getb_to_end
    end

    # The metadata stream (/Metadata), or nil (Java getMetadata).
    def metadata : PDMetadata?
      md = @stream.get_dictionary_object(Cos::Name.new("Metadata"))
      return nil unless md
      return PDMetadata.new(md) if md.is_a?(Cos::Stream)
      raise ArgumentError.new("Expected a COSStream but was a #{md.class}")
    end

    # Sets the metadata stream (/Metadata); nil removes it (Java setMetadata).
    def metadata=(meta : PDMetadata?) : Nil
      key = Cos::Name.new("Metadata")
      if meta
        @stream.set_item(key, meta.cos_object)
      else
        @stream.delete(key)
      end
    end

    # The decoded stream length (/DL). Java getDecodedStreamLength.
    def decoded_stream_length : Int32
      @stream.get_int(Cos::Name.new("DL"), 0).to_i32
    end

    def decoded_stream_length=(decoded_stream_length : Int32) : Nil
      @stream.set_int(Cos::Name.new("DL"), decoded_stream_length)
    end

    # The file specification (/F), or nil (Java getFile).
    def file : Filespecification::PDFileSpecification?
      Filespecification::PDFileSpecification.create_fs(@stream.get_dictionary_object(Cos::Name.new("F")))
    end

    # Sets the file specification (/F); nil removes it (Java setFile).
    def file=(f : Filespecification::PDFileSpecification?) : Nil
      key = Cos::Name.new("F")
      if f
        @stream.set_item(key, f.cos_object)
      else
        @stream.delete(key)
      end
    end

    # The file filters (/F_Filter) (Java getFileFilters).
    def file_filters : Array(String)
      filters_base = @stream.get_dictionary_object(Cos::Name.new("F_Filter"))
      case filters_base
      when Cos::Name
        [filters_base.value]
      when Cos::Array
        filters_base.to_cos_name_string_list.compact
      else
        [] of String
      end
    end

    def file_filters=(filters : Array(String)) : Nil
      @stream[Cos::Name.new("F_Filter")] = Cos::Array.of_cos_names(filters)
    end

    # The decode parameters (/DecodeParms, falling back to /DP).
    # Java PDStream#getDecodeParms.
    def decode_parms : Array(COSDictionaryMap(Bool | Int64 | Float64 | String))?
      internal_get_decode_params(Cos::Name.new("DecodeParms"), Cos::Name.new("DP"))
    end

    # The file decode parameters (/FDecodeParms). Java PDStream#getFileDecodeParams.
    def file_decode_params : Array(COSDictionaryMap(Bool | Int64 | Float64 | String))?
      internal_get_decode_params(Cos::Name.new("FDecodeParms"), nil)
    end

    # Sets the decode parameters (/DecodeParms). Java PDStream#setDecodeParms.
    def decode_parms=(parms : Enumerable(COSDictionaryMap(Bool | Int64 | Float64 | String))?) : Nil
      set_decode_params(Cos::Name.new("DecodeParms"), parms)
    end

    # Sets the file decode parameters (/FDecodeParms). Java PDStream#setFileDecodeParams.
    def file_decode_params=(parms : Enumerable(COSDictionaryMap(Bool | Int64 | Float64 | String))?) : Nil
      set_decode_params(Cos::Name.new("FDecodeParms"), parms)
    end

    # Java PDStream#internalGetDecodeParams: a dictionary becomes a one-element
    # list of maps; an array becomes a list of maps (non-dictionary entries skipped).
    private def internal_get_decode_params(name1 : Cos::Name, name2 : Cos::Name?) : Array(COSDictionaryMap(Bool | Int64 | Float64 | String))?
      value = @stream.get_dictionary_object(name1)
      value = @stream.get_dictionary_object(name2) if value.nil? && name2

      case value
      when Cos::Dictionary
        map = COSDictionaryMap.convert_basic_types_to_map(value)
        map ? [map] : nil
      when Cos::Array
        result = [] of COSDictionaryMap(Bool | Int64 | Float64 | String)
        value.items.each do |entry|
          entry = entry.object if entry.is_a?(Cos::Object)
          next unless entry.is_a?(Cos::Dictionary)
          if map = COSDictionaryMap.convert_basic_types_to_map(entry)
            result << map
          end
        end
        result
      end
    end

    private def set_decode_params(key : Cos::Name, parms : Enumerable(COSDictionaryMap(Bool | Int64 | Float64 | String))?) : Nil
      if parms
        array = Cos::Array.new
        parms.each { |map| array.add(map.to_dictionary) }
        @stream.set_item(key, array)
      else
        @stream.delete(key)
      end
    end
  end
end
