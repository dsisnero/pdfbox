module Pdfbox::Pdmodel::Interactive::Action
  class PDTargetDirectory
    include Pdfbox::Pdmodel::Common::COSObjectable

    RELATIONSHIP_PARENT = "P"
    RELATIONSHIP_CHILD  = "C"

    @dict : Cos::Dictionary

    def initialize
      @dict = Cos::Dictionary.new
    end

    def initialize(@dict : Cos::Dictionary)
    end

    def cos_object : Cos::Base
      @dict
    end

    def relationship : Cos::Name?
      @dict["R"]?.as?(Cos::Name)
    end

    def relationship=(relationship : Cos::Name) : Cos::Name
      unless {RELATIONSHIP_PARENT, RELATIONSHIP_CHILD}.includes?(relationship.value)
        raise ArgumentError.new("The only valid are P or C, not #{relationship.value}")
      end
      @dict[Cos::Name.new("R")] = relationship
      relationship
    end

    def filename : String?
      @dict.get_string(Cos::Name.new("N"))
    end

    def filename=(filename : String?) : String?
      if filename
        @dict.set_string("N", filename)
      else
        @dict.delete(Cos::Name.new("N"))
      end
      filename
    end

    def target_directory : PDTargetDirectory?
      @dict["T"]?.as?(Cos::Dictionary).try { |dict| PDTargetDirectory.new(dict) }
    end

    def target_directory=(target_directory : PDTargetDirectory) : PDTargetDirectory
      @dict[Cos::Name.new("T")] = target_directory.cos_object
      target_directory
    end

    def page_number : Int32
      @dict.get_int(Cos::Name.new("P"), -1_i64).to_i
    end

    def page_number=(page_number : Int32) : Int32
      if page_number < 0
        @dict.delete(Cos::Name.new("P"))
      else
        @dict.set_int("P", page_number)
      end
      page_number
    end

    def named_destination : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination?
      base = @dict["P"]?
      if string = base.as?(Cos::String)
        Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination.new(string)
      else
        nil
      end
    end

    def named_destination=(dest : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination?) : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination?
      if dest
        @dict[Cos::Name.new("P")] = dest.cos_object
      else
        @dict.delete(Cos::Name.new("P"))
      end
      dest
    end

    def annotation_index : Int32
      @dict.get_int(Cos::Name.new("A"), -1_i64).to_i
    end

    def annotation_index=(index : Int32) : Int32
      if index < 0
        @dict.delete(Cos::Name.new("A"))
      else
        @dict.set_int("A", index)
      end
      index
    end

    def annotation_name : String?
      @dict.get_string(Cos::Name.new("A"))
    end

    def annotation_name=(name : String?) : String?
      if name
        @dict.set_string("A", name)
      else
        @dict.delete(Cos::Name.new("A"))
      end
      name
    end
  end
end
