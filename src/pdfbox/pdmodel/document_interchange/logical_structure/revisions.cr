module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  # Stores objects together with their revision numbers (Java Revisions<T>).
  class Revisions(T)
    @objects = [] of T
    @revision_numbers = [] of Int32

    def get_object(index : Int32) : T
      @objects[index]
    end

    def get_revision_number(index : Int32) : Int32
      @revision_numbers[index]
    end

    def add_object(object : T, revision_number : Int32) : Nil
      @objects << object
      @revision_numbers << revision_number
    end

    protected def set_revision_number(object : T, revision_number : Int32) : Nil
      index = @objects.index(object)
      if index
        @revision_numbers[index] = revision_number
      end
    end

    def size : Int32
      @objects.size
    end

    def to_s(io : ::IO) : Nil
      io << "{"
      @objects.each_with_index do |object, i|
        io << "object=" << object << ", revisionNumber=" << get_revision_number(i)
        io << "; " if i < @objects.size - 1
      end
      io << "}"
    end
  end
end
