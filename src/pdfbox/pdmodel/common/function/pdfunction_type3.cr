# Type 3 (stitching) function in a PDF document
# Corresponds to PDFunctionType3 in Apache PDFBox
module Pdfbox::Pdmodel::Common::Function
  class PDFunctionType3 < PDFunction
    @functions : Cos::Array?
    @encode : Cos::Array?
    @bounds : Cos::Array?
    @functions_array : Array(PDFunction)?
    @bounds_values : Array(Float32)?

    # Constructor.
    def initialize(function : Cos::Base)
      super(function)
    end

    # Returns the function type (3 for stitching)
    def function_type : Int32
      3
    end

    # Returns all functions values as COSArray.
    def functions : Cos::Array
      if funcs = @functions
        return funcs
      end
      funcs = cos_object[Cos::Name::FUNCTIONS].as?(Cos::Array)
      @functions = funcs || Cos::Array.new
      @functions.as(Cos::Array)
    end

    # Returns all bounds values as COSArray.
    def bounds : Cos::Array
      if b = @bounds
        return b
      end
      b = cos_object[Cos::Name::BOUNDS].as?(Cos::Array)
      @bounds = b || Cos::Array.new
      @bounds.as(Cos::Array)
    end

    # Returns all encode values as COSArray.
    def encode : Cos::Array
      if enc = @encode
        return enc
      end
      enc = cos_object[Cos::Name::ENCODE].as?(Cos::Array)
      @encode = enc || Cos::Array.new
      @encode.as(Cos::Array)
    end

    # Get the encode for the input parameter.
    private def encode_for_parameter(n : Int32) : PDRange
      PDRange.new(encode, n)
    end

    # Evaluate the stitching function
    def eval(input : Array(Float32)) : Array(Float32)
      # This function is known as a "stitching" function. Based on the input, it decides which child function to call.
      # All functions in the array are 1-value-input functions
      # See PDF Reference section 3.9.3.
      function = nil.as(PDFunction?)
      x = input[0]
      domain = domain_for_input(0)
      # clip input value to domain
      x = clip_to_range(x, domain.min.to_f32, domain.max.to_f32)

      funcs_array = @functions_array ||= Array(PDFunction).new(functions.size) do |i|
        PDFunction.create(functions[i])
      end

      if funcs_array.size == 1
        # This doesn't make sense but it may happen ...
        function = funcs_array[0]
        enc_range = encode_for_parameter(0)
        x = interpolate(x, domain.min.to_f32, domain.max.to_f32, enc_range.min.to_f32, enc_range.max.to_f32)
      else
        bounds_vals = @bounds_values ||= bounds.items.map do |item|
          case item
          when Cos::Integer then item.value.to_f32
          when Cos::Float   then item.value.to_f32
          else                   0.0_f32
          end
        end
        bounds_size = bounds_vals.size
        # create a combined array containing the domain and the bounds values
        # domain.min, bounds[0], bounds[1], ...., bounds[bounds_size-1], domain.max
        partition_values = Array(Float32).new(bounds_size + 2, 0.0_f32)
        partition_values[0] = domain.min.to_f32
        partition_values[-1] = domain.max.to_f32
        bounds_vals.each_with_index do |val, i|
          partition_values[i + 1] = val
        end
        partition_values_size = partition_values.size
        # find the partition
        found = false
        (partition_values_size - 1).times do |i|
          if x >= partition_values[i] &&
             (x < partition_values[i + 1] || (i == partition_values_size - 2 && (x - partition_values[i + 1]).abs < 1e-9))
            function = funcs_array[i]
            enc_range = encode_for_parameter(i)
            x = interpolate(x, partition_values[i], partition_values[i + 1], enc_range.min.to_f32, enc_range.max.to_f32)
            found = true
            break
          end
        end
        unless found
          raise "partition not found in type 3 function"
        end
      end

      if function.nil?
        raise "partition not found in type 3 function"
      end
      function_values = [x]
      # calculate the output values using the chosen function
      function_result = function.as(PDFunction).eval(function_values)
      # clip to range if available
      clip_to_range(function_result)
    end
  end
end
