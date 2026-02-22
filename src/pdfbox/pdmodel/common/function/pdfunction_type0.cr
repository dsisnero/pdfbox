# Type 0 (sampled) function in a PDF document
# Corresponds to PDFunctionType0 in Apache PDFBox
module Pdfbox::Pdmodel::Common::Function
  class PDFunctionType0 < PDFunction
    Log = ::Log.for(self)

    @encode : Cos::Array?
    @decode : Cos::Array?
    @size : Cos::Array?
    @samples : Array(Array(Int32))?

    # Constructor.
    def initialize(function : Cos::Base)
      super(function)
    end

    # Returns the function type (0 for sampled)
    def function_type : Int32
      0
    end

    # The "Size" entry, which is the number of samples in each input dimension
    # of the sample table.
    def size : Cos::Array
      if sz = @size
        return sz
      end
      sz = cos_object[Cos::Name::SIZE].as?(Cos::Array)
      @size = sz || Cos::Array.new
      @size.as(Cos::Array)
    end

    # Get the number of bits that the output value will take up.
    # Valid values are 1,2,4,8,12,16,24,32.
    def bits_per_sample : Int32
      value = cos_object[Cos::Name::BITS_PER_SAMPLE]
      if value && value.is_a?(Cos::Number)
        value.value.to_i32
      else
        1
      end
    end

    # Get the order of interpolation between samples. Valid values are 1 and 3,
    # specifying linear and cubic spline interpolation, respectively. Default
    # is 1.
    def order : Int32
      value = cos_object[Cos::Name::ORDER]
      if value && value.is_a?(Cos::Number)
        value.value.to_i32
      else
        1
      end
    end

    # Set the number of bits that the output value will take up. Valid values
    # are 1,2,4,8,12,16,24,32.
    def bits_per_sample=(bps : Int32)
      cos_object.set_int(Cos::Name::BITS_PER_SAMPLE, bps)
    end

    # Returns all encode values as COSArray.
    private def encode_values : Cos::Array
      if enc = @encode
        return enc
      end
      enc = cos_object[Cos::Name::ENCODE].as?(Cos::Array)
      # the default value is [0 (size[0]-1) 0 (size[1]-1) ...]
      unless enc
        enc = Cos::Array.new
        size_values = size
        size_values_size = size_values.size
        size_values_size.times do |i|
          enc.add(Cos::Integer::ZERO)
          enc.add(Cos::Integer.get(size_values.get_int(i) - 1))
        end
      end
      @encode = enc
      enc
    end

    # Returns all decode values as COSArray.
    private def decode_values : Cos::Array
      if dec = @decode
        return dec
      end
      dec = cos_object[Cos::Name::DECODE].as?(Cos::Array)
      # if decode is null, the default values are the range values
      unless dec
        dec = range_values
      end
      @decode = dec || Cos::Array.new
      @decode.as(Cos::Array)
    end

    # Get the encode for the input parameter.
    def encode_for_parameter(param_num : Int32) : PDRange?
      encode_vals = encode_values
      return unless encode_vals && encode_vals.size >= param_num * 2 + 1
      PDRange.new(encode_vals, param_num)
    end

    # This will set the encode values.
    def encode_values=(encode_values : Cos::Array)
      @encode = encode_values
      cos_object.set_item(Cos::Name::ENCODE, encode_values)
    end

    # Get the decode for the input parameter.
    def decode_for_parameter(param_num : Int32) : PDRange?
      decode_vals = decode_values
      return unless decode_vals && decode_vals.size >= param_num * 2 + 1
      PDRange.new(decode_vals, param_num)
    end

    # This will set the decode values.
    def decode_values=(decode_values : Cos::Array)
      @decode = decode_values
      cos_object.set_item(Cos::Name::DECODE, decode_values)
    end

    # Inner class to do an interpolation in the Nth dimension by comparing the
    # content size of N-1 dimensional objects. This is done with the help of
    # recursive calls.
    private class RInterpol
      @in : Array(Float32)
      @in_prev : Array(Int32)
      @in_next : Array(Int32)
      @number_of_input_values : Int32
      @number_of_output_values : Int32
      @parent : PDFunctionType0

      # Constructor.
      def initialize(parent : PDFunctionType0, input : Array(Float32), input_prev : Array(Int32), input_next : Array(Int32))
        @parent = parent
        @in = input
        @in_prev = input_prev
        @in_next = input_next
        @number_of_input_values = input.size
        @number_of_output_values = parent.number_of_output_parameters
      end

      # Calculate the interpolation.
      def rinterpolate : Array(Float32)
        rinterpol(Array(Int32).new(@number_of_input_values, 0), 0)
      end

      # Do a linear interpolation if the two coordinates can be known, or
      # call itself recursively twice.
      private def rinterpol(coord : Array(Int32), step : Int32) : Array(Float32)
        result_sample = Array(Float32).new(@number_of_output_values, 0.0_f32)
        if step == @in.size - 1
          # leaf
          if @in_prev[step] == @in_next[step]
            coord[step] = @in_prev[step]
            tmp_sample = @parent.samples[calc_sample_index(coord)]
            @number_of_output_values.times do |i|
              result_sample[i] = tmp_sample[i].to_f32
            end
            return result_sample
          end
          coord[step] = @in_prev[step]
          sample1 = @parent.samples[calc_sample_index(coord)]
          coord[step] = @in_next[step]
          sample2 = @parent.samples[calc_sample_index(coord)]
          @number_of_output_values.times do |i|
            result_sample[i] = interpolate(@in[step], @in_prev[step].to_f32, @in_next[step].to_f32, sample1[i].to_f32, sample2[i].to_f32)
          end
          result_sample
        else
          # branch
          if @in_prev[step] == @in_next[step]
            coord[step] = @in_prev[step]
            return rinterpol(coord, step + 1)
          end
          coord[step] = @in_prev[step]
          sample1 = rinterpol(coord, step + 1)
          coord[step] = @in_next[step]
          sample2 = rinterpol(coord, step + 1)
          @number_of_output_values.times do |i|
            result_sample[i] = interpolate(@in[step], @in_prev[step].to_f32, @in_next[step].to_f32, sample1[i], sample2[i])
          end
          result_sample
        end
      end

      # Calculate array index (structure described in p.171 PDF spec 1.7) in multiple dimensions.
      private def calc_sample_index(vector : Array(Int32)) : Int32
        # inspiration: http://stackoverflow.com/a/12113479/535646
        # but used in reverse
        size_values = @parent.size_values_float
        index = 0
        size_product = 1
        dimension = vector.size
        (dimension - 2).downto(0) do |i|
          size_product *= size_values[i].to_i32
        end
        (dimension - 1).downto(0) do |i|
          index += size_product * vector[i]
          if i - 1 >= 0
            size_product //= size_values[i - 1].to_i32
          end
        end
        index
      end

      # Linear interpolation helper
      private def interpolate(x : Float32, x_min : Float32, x_max : Float32, y_min : Float32, y_max : Float32) : Float32
        if x_max == x_min
          return y_min
        end
        y_min + ((x - x_min) * (y_max - y_min) / (x_max - x_min))
      end
    end

    # Bit reader for reading packed bits from a stream
    private class BitReader
      @io : ::IO
      @current_byte : UInt8 = 0_u8
      @bits_remaining : Int32 = 0

      def initialize(@io : ::IO)
      end

      # Read the specified number of bits (1-32)
      def read_bits(num_bits : Int32) : Int32
        raise ArgumentError.new("num_bits must be between 1 and 32") if num_bits < 1 || num_bits > 32

        result = 0_i32
        bits_needed = num_bits

        while bits_needed > 0
          if @bits_remaining == 0
            byte = @io.read_byte
            if byte.nil?
              raise "Unexpected end of stream while reading bits"
            end
            @current_byte = byte
            @bits_remaining = 8
          end

          bits_to_take = Math.min(bits_needed, @bits_remaining)
          shift = @bits_remaining - bits_to_take
          mask = (((1_u16 << bits_to_take) - 1_u16) << shift).to_u8
          bits = (@current_byte & mask) >> shift

          result = (result << bits_to_take) | bits.to_i32
          bits_needed -= bits_to_take
          @bits_remaining -= bits_to_take

          if @bits_remaining == 0
            @current_byte = 0_u8
          end
        end

        result
      end
    end

    # Get all sample values of this function.
    protected def samples : Array(Array(Int32))
      if samps = @samples
        return samps
      end

      array_size = 1
      n_in = number_of_input_parameters
      n_out = number_of_output_parameters
      sizes = size
      n_in.times do |i|
        array_size *= sizes.get_int(i)
      end

      samps = Array(Array(Int32)).new(array_size) { Array(Int32).new(n_out, 0) }
      bps = bits_per_sample

      stream = pd_stream
      if stream.nil?
        # Function might be a dictionary without stream data
        # This shouldn't happen for valid Type 0 functions
        @samples = samps
        return samps
      end

      begin
        io = stream.create_input_stream
        bit_reader = BitReader.new(io)

        array_size.times do |i|
          n_out.times do |k|
            samps[i][k] = bit_reader.read_bits(bps)
          end
        end
      rescue ex
        # Log error and return empty samples
        Log.error { "IOException while reading the sample values of this function: #{ex.message}" }
      end

      @samples = samps
      samps
    end

    # Helper method to get size values as float array
    protected def size_values_float : Array(Float32)
      size.items.map do |item|
        case item
        when Cos::Integer then item.value.to_f32
        when Cos::Float   then item.value.to_f32
        else                   0.0_f32
        end
      end
    end

    # Evaluate the sampled function
    def eval(input : Array(Float32)) : Array(Float32)
      # This involves linear interpolation based on a set of sample points.
      size_vals = size_values_float
      bits_per_sample_val = bits_per_sample
      max_sample = (2 ** bits_per_sample_val - 1).to_f32
      n_in = input.size
      n_out = number_of_output_parameters

      input_prev = Array(Int32).new(n_in, 0)
      input_next = Array(Int32).new(n_in, 0)
      input = input.clone

      n_in.times do |i|
        domain = domain_for_input(i)
        encode_vals = encode_for_parameter(i)
        raise "Encode missing for parameter #{i}" unless encode_vals
        min = domain.min.to_f32
        max = domain.max.to_f32
        input[i] = clip_to_range(input[i], min, max)
        input[i] = interpolate(input[i], min, max, encode_vals.min.to_f32, encode_vals.max.to_f32)
        input[i] = clip_to_range(input[i], 0.0_f32, size_vals[i] - 1.0_f32)
        input_prev[i] = input[i].floor.to_i32
        input_next[i] = input[i].ceil.to_i32
      end

      output_values = RInterpol.new(self, input, input_prev, input_next).rinterpolate

      n_out.times do |i|
        range = range_for_output(i)
        decode_vals = decode_for_parameter(i)
        raise "Range missing in function /Decode entry" unless decode_vals
        output_values[i] = interpolate(output_values[i], 0.0_f32, max_sample, decode_vals.min.to_f32, decode_vals.max.to_f32)
        output_values[i] = clip_to_range(output_values[i], range.min.to_f32, range.max.to_f32)
      end

      output_values
    end

    def to_s : String
      "FunctionType0{size: #{size}, bitsPerSample: #{bits_per_sample}, order: #{order}}"
    end
  end
end
