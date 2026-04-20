module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination
  class PDPageDestination < PDDestination
    @array : Cos::Array

    def initialize
      @array = Cos::Array.new
    end

    def initialize(@array : Cos::Array)
    end

    def cos_object : Cos::Array
      @array
    end

    def page : Cos::Dictionary?
      return if @array.empty?
      @array[0]?.as?(Cos::Dictionary)
    end

    def page=(page : Cos::Dictionary) : Cos::Dictionary
      @array.grow_to_size(1, Cos::Null.instance)
      @array[0] = page
      page
    end

    def page_number : Int32
      return -1 if @array.empty?
      @array[0]?.as?(Cos::Integer).try(&.value.to_i32) || -1
    end

    def retrieve_page_number : Int32
      page_number
    end

    def page_number=(page_number : Int32) : Int32
      @array.grow_to_size(1, Cos::Null.instance)
      @array[0] = Cos::Integer.new(page_number)
      page_number
    end
  end
end
