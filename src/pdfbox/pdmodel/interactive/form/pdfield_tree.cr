module Pdfbox::Pdmodel::Interactive::Form
  # The field tree (Java PDFieldTree): walks every field of an AcroForm with the
  # parents before their children, guarding against a `/Kids` entry that is
  # reachable twice through an identity set on the COS dictionaries (PDFBOX-5044;
  # the guard cannot use the PDField objects because a new PDField is created on
  # every lookup).
  class PDFieldTree
    include Enumerable(PDField)

    Log = ::Log.for(self)

    # Java PDFieldTree(PDAcroForm): the root cannot be null.
    def initialize(@acro_form : PDAcroForm?)
      raise ArgumentError.new("root cannot be null") if @acro_form.nil?
    end

    # Walks all fields in the tree, in order (Java PDFieldTree#iterator). Like
    # Java's FieldIterator, which enqueues the whole tree when it is created, the
    # traversal is built once per iteration, so a tree can be iterated repeatedly.
    def each(& : PDField ->) : Nil
      form = @acro_form
      return unless form

      nodes = [] of PDField
      seen = Set(UInt64).new
      form.fields.each { |field| collect(field, seen, nodes) }
      nodes.each { |node| yield node }
    end

    # Java PDFieldTree#iterator: a fresh traversal per call.
    def each : Iterator(PDField)
      nodes = [] of PDField
      each { |node| nodes << node }
      nodes.each
    end

    private def collect(node : PDField, seen : Set(UInt64), nodes : Array(PDField)) : Nil
      nodes << node
      seen.add(node.cos_object.object_id)
      return unless node.is_a?(PDNonTerminalField)

      node.children.each do |kid|
        if seen.includes?(kid.cos_object.object_id)
          # Java logs this at error level (PDFBOX-5044).
          Log.error do
            "Child of field '#{node.fully_qualified_name}' already exists elsewhere, ignored to avoid recursion"
          end
        else
          collect(kid, seen, nodes)
        end
      end
    end
  end
end
