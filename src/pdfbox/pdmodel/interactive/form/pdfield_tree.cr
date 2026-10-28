module Pdfbox::Pdmodel::Interactive::Form
  # The field tree (Java PDFieldTree): an `Iterable`-style collection that hands
  # out a fresh `FieldIterator` per traversal (Crystal's `Enumerable` is the
  # counterpart of Java's `Iterable`; the tree itself is not an `Iterator`, so it
  # can be walked again and again).
  class PDFieldTree
    include Enumerable(PDField)

    Log = ::Log.for(self)

    # Java PDFieldTree(PDAcroForm): the root cannot be null.
    def initialize(@acro_form : PDAcroForm?)
      raise ArgumentError.new("root cannot be null") if @acro_form.nil?
    end

    # Java PDFieldTree#iterator: a fresh traversal per call.
    def each : FieldIterator
      form = @acro_form
      raise ArgumentError.new("root cannot be null") unless form

      FieldIterator.new(form)
    end

    def each(& : PDField ->) : Nil
      each.each { |field| yield field }
    end

    # Java PDFieldTree.FieldIterator: walks the field tree in
    # parent-before-children order. The identity set on the COS dictionaries stops
    # a `/Kids` entry that is reachable twice from recursing forever
    # (PDFBOX-5044; the guard cannot use PDField because a new one is created on
    # every lookup).
    #
    # Like Java, the whole tree is enqueued when the iterator is created (Java
    # queues it in the FieldIterator constructor) and `next` then pops from that
    # queue, so a top-level field that is also reachable as a kid is still yielded
    # from the top-level list — that is what the PDFBOX-4131-0 fixture expects.
    class FieldIterator
      include Iterator(PDField)

      def initialize(@acro_form : PDAcroForm)
        @queue = Deque(PDField).new
        @seen = Set(UInt64).new
        @acro_form.fields.each { |field| enqueue_kids(field) }
      end

      def next : PDField | Iterator::Stop
        return stop if @queue.empty?

        @queue.shift
      end

      private def enqueue_kids(node : PDField) : Nil
        @queue << node
        @seen.add(node.cos_object.object_id)
        return unless node.is_a?(PDNonTerminalField)

        node.children.each do |kid|
          if @seen.includes?(kid.cos_object.object_id)
            # Java logs this at error level (PDFBOX-5044).
            PDFieldTree::Log.error do
              "Child of field '#{node.fully_qualified_name}' already exists elsewhere, ignored to avoid recursion"
            end
          else
            enqueue_kids(kid)
          end
        end
      end
    end
  end
end
