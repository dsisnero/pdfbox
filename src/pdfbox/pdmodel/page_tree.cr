# PDPageTree implementation for PDFBox Crystal
#
# The page tree defines the ordering of pages in the document in an efficient manner.
# Corresponds to PDPageTree in Apache PDFBox.

require "../cos"
require "./page"
require "log"

module Pdfbox::Pdmodel
  Log = ::Log.for(self)

  # The page tree, which defines the ordering of pages in the document in an efficient manner.
  class PDPageTree
    include Enumerable(Page)

    @root : Cos::Dictionary
    @document : Document?
    @page_set = Set(Cos::Dictionary).new

    # Constructor for embedding (creating new page trees)
    def initialize
      @root = Cos::Dictionary.new
      @root[Cos::Name.new("Type")] = Cos::Name.new("Pages")
      @root[Cos::Name.new("Kids")] = Cos::Array.new
      @root[Cos::Name.new("Count")] = Cos::Integer.new(0)
      @document = nil
    end

    # Constructor for reading existing page trees
    def initialize(@root : Cos::Dictionary)
      @document = nil
      repair_bad_pdf_if_needed
    end

    # Constructor for reading with document reference
    def initialize(@root : Cos::Dictionary, @document : Document?)
      repair_bad_pdf_if_needed
    end

    # Repair bad PDFs which contain a Page dict instead of a page tree (PDFBOX-3154)
    private def repair_bad_pdf_if_needed : Nil
      if Cos::Name.new("Page") == @root[Cos::Name.new("Type")]
        kids = Cos::Array.new
        kids.add(@root)
        @root = Cos::Dictionary.new
        @root[Cos::Name.new("Kids")] = kids
        @root.set_int(Cos::Name.new("Count"), 1)
      end
    end

    # Returns the given attribute, inheriting from parent tree nodes if necessary.
    def self.get_inheritable_attribute(node : Cos::Dictionary, key : Cos::Name) : Cos::Base?
      get_inheritable_attribute(node, key, Set(Cos::Dictionary).new)
    end

    private def self.get_inheritable_attribute(node : Cos::Dictionary, key : Cos::Name, visited : Set(Cos::Dictionary)) : Cos::Base?
      return if visited.includes?(node)
      visited.add(node)

      value = node[key]
      return value if value

      parent = get_parent_node(node)
      if parent && Cos::Name.new("Pages") == parent[Cos::Name.new("Type")]
        return get_inheritable_attribute(parent, key, visited)
      end

      nil
    end

    private def self.get_parent_node(node : Cos::Dictionary) : Cos::Dictionary?
      parent = node[Cos::Name.new("Parent")] || node[Cos::Name.new("P")]
      return unless parent

      if parent.is_a?(Cos::Object)
        parent = parent.object
      end

      parent.as?(Cos::Dictionary)
    end

    # Instance method version for use within the class
    private def get_parent_node(node : Cos::Dictionary) : Cos::Dictionary?
      parent = node[Cos::Name.new("Parent")] || node[Cos::Name.new("P")]
      return unless parent

      if parent.is_a?(Cos::Object)
        parent = parent.object
      end

      parent.as?(Cos::Dictionary)
    end

    # Returns an iterator which walks all pages in the tree, in order.
    def each(&block : Page ->) : Nil
      PageIterator.new(@root, @document).each(&block)
    end

    # Returns an iterator for the page tree
    def each : Iterator(Page)
      PageIterator.new(@root, @document)
    end

    # Helper to get kids from malformed PDFs.
    private def get_kids(node : Cos::Dictionary) : Array(Cos::Dictionary)
      kids = node[Cos::Name.new("Kids")]
      unless kids.is_a?(Cos::Array)
        # probably a malformed PDF
        return [] of Cos::Dictionary
      end

      result = [] of Cos::Dictionary
      kids.size.times do |i|
        base = kids[i]?
        next unless base

        if base.is_a?(Cos::Dictionary)
          result << base
        elsif base.is_a?(Cos::Object)
          obj = base.object
          result << obj if obj.is_a?(Cos::Dictionary)
        elsif base.is_a?(Cos::Null)
          # Replace null entry with an empty page
          empty_page = Cos::Dictionary.new
          empty_page[Cos::Name.new("Type")] = Cos::Name.new("Page")
          kids[i] = empty_page
          result << empty_page
        end
      end

      result
    end

    # Returns the page at the given index (0-based).
    #
    # Raises IndexError if the requested index is higher than the page count.
    # Raises RuntimeError if the requested index doesn't point to a valid page dictionary.
    def get(index : Int32) : Page
      dict = get_page_dict(index + 1, @root, 0)
      sanitize_type(dict)
      create_page(dict)
    end

    # Alias for get (Java compatibility)
    def [](index : Int32) : Page
      get(index)
    end

    private def sanitize_type(dictionary : Cos::Dictionary) : Nil
      type = dictionary[Cos::Name.new("Type")]
      if type.nil?
        dictionary[Cos::Name.new("Type")] = Cos::Name.new("Page")
        return
      end

      unless type.is_a?(Cos::Name) && type.value == "Page"
        raise RuntimeError.new("Expected 'Page' but found #{type}")
      end
    end

    # Returns the given COS page using a depth-first search.
    private def get_page_dict(page_num : Int32, node : Cos::Dictionary, encountered : Int32) : Cos::Dictionary
      raise IndexError.new("Index out of bounds: #{page_num}") if page_num < 1

      if @page_set.includes?(node)
        @page_set.clear
        raise RuntimeError.new("Possible recursion found when searching for page #{page_num}")
      else
        @page_set.add(node)
      end

      if page_tree_node?(node)
        count = node_count(node)
        if page_num <= encountered + count
          # it's a kid of this node
          get_kids(node).each do |kid|
            # which kid?
            if page_tree_node?(kid)
              kid_count = node_count(kid)
              if page_num <= encountered + kid_count
                # it's this kid
                return get_page_dict(page_num, kid, encountered)
              else
                encountered += kid_count
              end
            else
              # single page
              encountered += 1
              if page_num == encountered
                # it's this page
                return get_page_dict(page_num, kid, encountered)
              end
            end
          end

          raise RuntimeError.new("1-based index not found: #{page_num}")
        else
          raise IndexError.new("1-based index out of bounds: #{page_num}")
        end
      else
        if encountered == page_num
          @page_set.clear
          node
        else
          raise RuntimeError.new("1-based index not found: #{page_num}")
        end
      end
    end

    # Returns true if the node is a page tree node (i.e. an intermediate).
    private def page_tree_node?(node : Cos::Dictionary?) : Bool
      return false unless node
      # Some files such as PDFBOX-2250-229205.pdf don't have Pages set as the Type,
      # so we have to check for the presence of Kids too
      Cos::Name.new("Pages") == node[Cos::Name.new("Type")] ||
        node.has_key?(Cos::Name.new("Kids"))
    end

    # Get count from a page tree node
    private def node_count(node : Cos::Dictionary) : Int32
      count = node[Cos::Name.new("Count")]
      return 0 unless count.is_a?(Cos::Integer)
      count.value.to_i32
    end

    # Returns the index of the given page, or -1 if it does not exist.
    def index_of(page : Page) : Int32
      context = SearchContext.new(page)
      find_page(context, @root)
      context.index
    end

    private def find_page(context : SearchContext, node : Cos::Dictionary) : Bool
      get_kids(node).each do |kid|
        break if context.found?

        if page_tree_node?(kid)
          find_page(context, kid)
        else
          context.visit_page(kid)
        end
      end
      context.found?
    end

    # Returns the number of leaf nodes (page objects) that are descendants of this root within the page tree.
    def count : Int32
      node_count(@root)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @root
    end

    # Removes the page with the given index from the page tree.
    def remove(index : Int32) : Nil
      node = get_page_dict(index + 1, @root, 0)
      remove_node(node)
    end

    # Removes the given page from the page tree.
    def remove(page : Page) : Nil
      cos_page = page.cos_object
      return unless cos_page
      remove_node(cos_page)
    end

    # Removes the given COS page.
    private def remove_node(node : Cos::Dictionary) : Nil
      # remove from parent's kids
      parent = get_parent_node(node)
      return unless parent

      kids = parent[Cos::Name.new("Kids")]
      return unless kids.is_a?(Cos::Array)

      if kids.remove_object(node)
        # update ancestor counts
        current = parent
        while current
          current.set_int(Cos::Name.new("Count"), node_count(current) - 1)
          current = get_parent_node(current)
        end
      end
    end

    # Adds the given page to this page tree.
    def add(page : Page) : Nil
      cos_page = page.cos_object
      return unless cos_page

      # set parent
      cos_page[Cos::Name.new("Parent")] = @root

      # add to parent's kids
      kids = @root[Cos::Name.new("Kids")]
      unless kids.is_a?(Cos::Array)
        kids = Cos::Array.new
        @root[Cos::Name.new("Kids")] = kids
      end
      kids.add(cos_page)

      # update ancestor counts
      current = @root
      while current
        current.set_int(Cos::Name.new("Count"), node_count(current) + 1)
        current = get_parent_node(current)
      end
    end

    # Adds a page at the given index.
    def add(index : Int32, page : Page) : Nil
      cos_page = page.cos_object
      return unless cos_page

      # set parent
      cos_page[Cos::Name.new("Parent")] = @root

      # add to parent's kids at index
      kids = @root[Cos::Name.new("Kids")]
      unless kids.is_a?(Cos::Array)
        kids = Cos::Array.new
        @root[Cos::Name.new("Kids")] = kids
      end
      kids.add(index, cos_page)

      # update ancestor counts
      current = @root
      while current
        current.set_int(Cos::Name.new("Count"), node_count(current) + 1)
        current = get_parent_node(current)
      end
    end

    # Insert a page before another page within a page tree.
    def insert_before(new_page : Page, next_page : Page) : Nil
      next_page_dict = next_page.cos_object
      return unless next_page_dict

      parent = get_parent_node(next_page_dict)
      return unless parent

      kids = parent[Cos::Name.new("Kids")]
      return unless kids.is_a?(Cos::Array)

      found = false
      kids.size.times do |i|
        page_dict = kids[i]?
        if page_dict.is_a?(Cos::Dictionary) && page_dict.same?(next_page_dict)
          new_page_dict = new_page.cos_object
          if new_page_dict
            kids.add(i, new_page_dict)
            new_page_dict[Cos::Name.new("Parent")] = parent
            found = true
            break
          end
        end
      end

      raise ArgumentError.new("attempted to insert before orphan page") unless found
      increase_parents(parent)
    end

    # Insert a page after another page within a page tree.
    def insert_after(new_page : Page, prev_page : Page) : Nil
      prev_page_dict = prev_page.cos_object
      return unless prev_page_dict

      parent = get_parent_node(prev_page_dict)
      return unless parent

      kids = parent[Cos::Name.new("Kids")]
      return unless kids.is_a?(Cos::Array)

      found = false
      kids.size.times do |i|
        page_dict = kids[i]?
        if page_dict.is_a?(Cos::Dictionary) && page_dict.same?(prev_page_dict)
          new_page_dict = new_page.cos_object
          if new_page_dict
            kids.add(i + 1, new_page_dict)
            new_page_dict[Cos::Name.new("Parent")] = parent
            found = true
            break
          end
        end
      end

      raise ArgumentError.new("attempted to insert before orphan page") unless found
      increase_parents(parent)
    end

    private def increase_parents(parent_dict : Cos::Dictionary) : Nil
      current = parent_dict
      while current
        cnt = node_count(current)
        current.set_int(Cos::Name.new("Count"), cnt + 1)
        current = get_parent_node(current)
      end
    end

    private def create_page(dict : Cos::Dictionary) : Page
      Page.new(dict)
    end

    # Iterator which walks all pages in the tree, in order.
    private class PageIterator
      include Iterator(Page)

      @queue : Deque(Cos::Dictionary) = Deque(Cos::Dictionary).new
      @set : Set(Cos::Dictionary) = Set(Cos::Dictionary).new

      def initialize(node : Cos::Dictionary, @document : Document?)
        enqueue_kids(node)
        @set.clear # release memory, we don't use this anymore
      end

      private def enqueue_kids(node : Cos::Dictionary) : Nil
        if page_tree_node?(node)
          get_kids(node).each do |kid|
            if @set.includes?(kid)
              # PDFBOX-5009, PDFBOX-3953: prevent stack overflow with malformed PDFs
              Log.error { "This page tree node has already been visited" }
              next
            elsif kid.has_key?(Cos::Name.new("Kids"))
              @set.add(kid)
            end
            enqueue_kids(kid)
          end
        else
          if node && Cos::Name.new("Page") == node[Cos::Name.new("Type")]
            @queue.push(node)
          else
            type = node ? node[Cos::Name.new("Type")] : "(null)"
            Log.error { "Page skipped due to an invalid or missing type #{type}" }
          end
        end
      end

      def next : Page | Iterator::Stop
        return stop if @queue.empty?
        next_dict = @queue.shift
        sanitize_type(next_dict)
        Page.new(next_dict)
      end

      private def page_tree_node?(node : Cos::Dictionary?) : Bool
        return false unless node
        Cos::Name.new("Pages") == node[Cos::Name.new("Type")] ||
          node.has_key?(Cos::Name.new("Kids"))
      end

      private def get_kids(node : Cos::Dictionary) : Array(Cos::Dictionary)
        kids = node[Cos::Name.new("Kids")]
        unless kids.is_a?(Cos::Array)
          return [] of Cos::Dictionary
        end

        result = [] of Cos::Dictionary
        kids.size.times do |i|
          base = kids[i]?
          next unless base

          if base.is_a?(Cos::Dictionary)
            result << base
          elsif base.is_a?(Cos::Object)
            obj = base.object
            result << obj if obj.is_a?(Cos::Dictionary)
          end
        end

        result
      end

      private def sanitize_type(dictionary : Cos::Dictionary) : Nil
        type = dictionary[Cos::Name.new("Type")]
        if type.nil?
          dictionary[Cos::Name.new("Type")] = Cos::Name.new("Page")
        end
      end
    end

    # Search context for finding page index
    private class SearchContext
      property index : Int32 = -1
      getter? found : Bool = false

      @searched : Cos::Dictionary
      @visited_index : Int32 = -1

      def initialize(page : Page)
        cos_page = page.cos_object
        @searched = cos_page || Cos::Dictionary.new
      end

      def visit_page(current : Cos::Dictionary) : Nil
        @visited_index += 1
        return unless @searched.same?(current)

        @index = @visited_index
        @found = true
      end
    end
  end
end
