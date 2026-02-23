# This class will be used to signify a range.  a(min) <= a* <= a(max)
class Pdfbox::Pdmodel::Common::PDRange
  include COSObjectable

  @range_array : Cos::Array
  @starting_index : Int32

  # Constructor with an initial range of 0..1.
  def initialize
    @range_array = Cos::Array.new
    @range_array.add(Cos::Float::ZERO)
    @range_array.add(Cos::Float::ONE)
    @starting_index = 0
  end

  # Constructor assumes a starting index of 0.
  #
  # @param range The array that describes the range.
  def initialize(range : Cos::Array)
    @range_array = range
    @starting_index = 0
  end

  # Constructor with an index into an array.  Because some arrays specify
  # multiple ranges ie [ 0,1,  0,2,  2,3 ] It is convenient for this
  # class to take an index into an array.  So if you want this range to
  # represent 0,2 in the above example then you would say `PDRange.new(array, 1)`.
  #
  # @param range The array that describes the index
  # @param index The range index into the array for the start of the range.
  def initialize(range : Cos::Array, index : Int32)
    @range_array = range
    @starting_index = index
  end

  # Convert this standard java object to a COS object.
  #
  # @return The cos object that matches this Java object.
  def cos_object : Cos::Base
    @range_array
  end

  # This will get the underlying array value.
  #
  # @return The cos object that this object wraps.
  def cos_array : Cos::Array
    @range_array
  end

  # This will get the minimum value of the range.
  #
  # @return The min value.
  def min : Float64
    min_obj = @range_array[@starting_index * 2]
    case min_obj
    when Cos::Float
      min_obj.value
    when Cos::Integer
      min_obj.value.to_f64
    else
      0.0
    end
  end

  # This will set the minimum value for the range.
  #
  # @param min The new minimum for the range.
  def min=(min_value : Float64) : Nil
    @range_array[@starting_index * 2] = Cos::Float.new(min_value)
  end

  # This will get the maximum value of the range.
  #
  # @return The max value.
  def max : Float64
    max_obj = @range_array[@starting_index * 2 + 1]
    case max_obj
    when Cos::Float
      max_obj.value
    when Cos::Integer
      max_obj.value.to_f64
    else
      0.0
    end
  end

  # This will set the maximum value for the range.
  #
  # @param max The new maximum for the range.
  def max=(max_value : Float64) : Nil
    @range_array[@starting_index * 2 + 1] = Cos::Float.new(max_value)
  end

  # Convert to string representation
  def to_s(io : ::IO) : Nil
    io << "PDRange{" << min << ", " << max << "}"
  end
end
