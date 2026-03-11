module Pdfbox::Pdfwriter::Compress
  # Iterative object collection port for Java COSWriterCompressionPool traversal paths.
  class COSWriterCompressionPool
    getter top_level_objects, object_stream_objects

    @top_level_objects = [] of Pdfbox::Cos::ObjectKey
    @object_stream_objects = [] of Pdfbox::Cos::ObjectKey
    @seen = Set(UInt64).new

    def initialize(@document : Pdfbox::Pdmodel::Document, @parameters : CompressParameters? = nil)
      @parameters ||= CompressParameters::DEFAULT_COMPRESSION
      roots = [] of Pdfbox::Cos::Base
      if catalog = @document.document_catalog
        roots << catalog.cos_object
      end
      collect_structure_iteratively(roots)
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
