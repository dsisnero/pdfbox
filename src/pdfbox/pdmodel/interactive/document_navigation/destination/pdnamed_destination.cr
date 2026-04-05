module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination
  class PDNamedDestination < PDDestination
    @named_destination : Cos::Base?

    def initialize(@named_destination : Cos::String)
    end

    def initialize(@named_destination : Cos::Name)
    end

    def initialize
    end

    def initialize(dest : String)
      @named_destination = Cos::String.new(dest)
    end

    def cos_object : Cos::Base
      @named_destination || Cos::String.new("")
    end

    def named_destination : String?
      case current = @named_destination
      when Cos::String
        current.value
      when Cos::Name
        current.value
      else
        nil
      end
    end

    def named_destination=(dest : String?) : String?
      @named_destination = dest.nil? ? nil : Cos::String.new(dest)
      dest
    end
  end
end
