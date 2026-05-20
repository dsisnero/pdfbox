module Pdfbox::Pdfwriter::Compress
  # Collects objects from a PDF document and organizes them into compressed object streams.
  # Port of org.apache.pdfbox.pdfwriter.compress.COSWriterCompressionPool.
  class COSWriterCompressionPool
    getter top_level_objects : Array(Pdfbox::Cos::ObjectKey)
    getter object_stream_objects : Array(Pdfbox::Cos::ObjectKey)

    @top_level_objects = [] of Pdfbox::Cos::ObjectKey
    @object_stream_objects = [] of Pdfbox::Cos::ObjectKey
    @seen = Set(UInt64).new
    @object_to_key = {} of UInt64 => Pdfbox::Cos::ObjectKey
    @key_to_object = {} of Pdfbox::Cos::ObjectKey => Pdfbox::Cos::Base

    MAX_OBJECTS_PER_STREAM = 256

    def initialize(@document : Pdfbox::Pdmodel::Document, @parameters : CompressParameters? = nil)
      @parameters ||= CompressParameters::DEFAULT_COMPRESSION
      roots = [] of Pdfbox::Cos::Base
      if catalog = @document.document_catalog
        roots << catalog.cos_object
      end
      collect_structure_iteratively(roots)
    end

    # Create object streams for all compressible objects.
    # Returns list of COSWriterObjectStream instances, each with up to 256 objects.
    def create_object_streams : Array(COSWriterObjectStream)
      streams = [] of COSWriterObjectStream
      return streams if @object_stream_objects.empty?

      stream = COSWriterObjectStream.new(self)
      @object_stream_objects.each do |key|
        if stream.prepared_keys.size >= MAX_OBJECTS_PER_STREAM
          streams << stream
          stream = COSWriterObjectStream.new(self)
        end
        obj = @key_to_object[key]?
        next unless obj
        stream.prepare_stream_object(key, obj)
      end
      streams << stream unless stream.prepared_keys.empty?
      streams
    end

    # Check if the given object is tracked by this pool.
    def contains?(obj : Pdfbox::Cos::Base) : Bool
      @object_to_key.has_key?(obj.object_id.to_u64)
    end

    # Get the object key assigned to this object.
    def key_for(obj : Pdfbox::Cos::Base) : Pdfbox::Cos::ObjectKey?
      @object_to_key[obj.object_id.to_u64]?
    end

    # Register an object with its key.
    def register_object(key : Pdfbox::Cos::ObjectKey, obj : Pdfbox::Cos::Base) : Nil
      @object_to_key[obj.object_id.to_u64] = key
      @key_to_object[key] = obj
    end

    private def collect_structure_iteratively(initial_roots : Array(Pdfbox::Cos::Base)) : Nil
      queue = Deque(Pdfbox::Cos::Base).new
      initial_roots.each { |root| queue << root }

      until queue.empty?
        current = queue.shift
        next unless mark_once(current)

        case current
        when Pdfbox::Cos::Object
          if resolved = current.object
            queue << resolved
          end
        when Pdfbox::Cos::Array
          current.items.each { |item| queue << item }
        when Pdfbox::Cos::Dictionary
          current.entries.each_value { |value| queue << value }
        end
      end
    end

    private def mark_once(base : Pdfbox::Cos::Base) : Bool
      identity = base.object_id.to_u64
      return false if @seen.includes?(identity)
      @seen << identity
      true
    end
  end
end
