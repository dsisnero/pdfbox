# Abstract base class for PDF functions
require "../pdstream"

module Pdfbox::Pdmodel::Common::Function
  abstract class PDFunction
    # Factory method to create the appropriate PDFunction subclass
    def self.create(function : Cos::Base) : PDFunction
      # Identity function special case
      if function.is_a?(Cos::Name) && function == Cos::Name::IDENTITY
        return PDFunctionTypeIdentity.new(function)
      end

      base = function
      if base.is_a?(Cos::Object)
        # resolve indirect object
        base = base.object
      end

      unless base && (base.is_a?(Cos::Dictionary) || base.is_a?(Cos::Stream))
        raise "Error: Function must be a Dictionary or Stream, but is #{base ? base.class : "(nil)"}"
      end

      function_type = base[Cos::Name::FUNCTION_TYPE]
      unless function_type.is_a?(Cos::Integer)
        raise "Error: Function type missing or not an integer"
      end

      case function_type.value
      when 0
        PDFunctionType0.new(base)
      when 2
        PDFunctionType2.new(base)
      when 3
        PDFunctionType3.new(base)
      when 4
        PDFunctionType4.new(base)
      else
        raise "Error: Unknown function type #{function_type.value}"
      end
    end

    @function_stream : Common::PDStream?
    @function_dictionary : Cos::Dictionary?
    @domain : Cos::Array?
    @range : Cos::Array?
    @number_of_input_values : Int32 = -1
    @number_of_output_values : Int32 = -1

    # Constructor
    def initialize(function : Cos::Base)
      case function
      when Cos::Stream
        stream = Common::PDStream.new(function)
        @function_stream = stream
        stream.cos_object[Cos::Name::TYPE] = Cos::Name::FUNCTION
      when Cos::Dictionary
        @function_dictionary = function
      end
    end

    # Returns the function type (abstract method)
    # 0 - Sampled function
    # 2 - Exponential interpolation function
    # 3 - Stitching function
    # 4 - PostScript calculator function
    abstract def function_type : Int32

    # Returns the COS dictionary/stream for this function
    def cos_object : Cos::Dictionary
      if stream = @function_stream
        stream.cos_object
      else
        @function_dictionary.as(Cos::Dictionary)
      end
    end

    # Returns the underlying PDStream
    def pd_stream : Common::PDStream?
      @function_stream
    end

    # Get the number of output parameters with range specified
    def number_of_output_parameters : Int32
      if @number_of_output_values == -1
        range_values = range_values()
        @number_of_output_values = range_values.nil? ? 0 : (range_values.size // 2).to_i32
      end
      @number_of_output_values
    end

    # Get the range for a specific output parameter
    def range_for_output(n : Int32) : PDRange
      range_vals = range_values
      raise "No range values for function" unless range_vals
      PDRange.new(range_vals, n)
    end

    # Set the range values
    def range_values=(range_values : Cos::Array)
      @range = range_values
      cos_object[Cos::Name::RANGE] = range_values
    end

    # Get the number of input parameters with domain specified
    def number_of_input_parameters : Int32
      if @number_of_input_values == -1
        domain_values = domain_values()
        @number_of_input_values = (domain_values.size // 2).to_i32
      end
      @number_of_input_values
    end

    # Get the domain for a specific input parameter
    def domain_for_input(n : Int32) : PDRange
      PDRange.new(domain_values(), n)
    end

    # Set the domain values
    def domain_values=(domain_values : Cos::Array)
      @domain = domain_values
      cos_object[Cos::Name::DOMAIN] = domain_values
    end

    # Evaluate the function (abstract method)
    abstract def eval(input : Array(Float32)) : Array(Float32)

    # Returns all range values
    def range_values : Cos::Array?
      if @range.nil?
        range_obj = cos_object[Cos::Name::RANGE]
        @range = range_obj.as?(Cos::Array)
      end
      @range
    end

    # Returns all domain values
    def domain_values : Cos::Array
      if @domain.nil?
        domain_obj = cos_object[Cos::Name::DOMAIN]
        @domain = domain_obj.as(Cos::Array)
      end
      @domain.as(Cos::Array)
    end

    # Clip input values to range
    def clip_to_range(input_values : Array(Float32)) : Array(Float32)
      ranges_array = range_values()
      if ranges_array && !ranges_array.items.empty?
        range_values_float = ranges_array.items.map do |item|
          case item
          when Cos::Integer then item.value.to_f32
          when Cos::Float   then item.value.to_f32
          else
            0.0_f32
          end
        end
        number_of_ranges = range_values_float.size // 2
        result = Array(Float32).new(number_of_ranges, 0.0_f32)
        number_of_ranges.times do |i|
          index = i * 2
          result[i] = clip_to_range(input_values[i], range_values_float[index], range_values_float[index + 1])
        end
        result
      else
        input_values
      end
    end

    # Clip a value to a specific range
    def clip_to_range(x : Float32, range_min : Float32, range_max : Float32) : Float32
      if x < range_min
        range_min
      elsif x > range_max
        range_max
      else
        x
      end
    end

    # Interpolate a value
    def interpolate(x : Float32, x_range_min : Float32, x_range_max : Float32, y_range_min : Float32, y_range_max : Float32) : Float32
      if x_range_max == x_range_min
        return y_range_min
      end
      y_range_min + ((x - x_range_min) * (y_range_max - y_range_min) / (x_range_max - x_range_min))
    end

    def to_s : String
      "FunctionType#{function_type}"
    end
  end
end
