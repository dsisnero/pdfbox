# Type 2 (exponential interpolation) function in a PDF document
# Corresponds to PDFunctionType2 in Apache PDFBox
module Pdfbox::Pdmodel::Common::Function
  class PDFunctionType2 < PDFunction
    @c0 : Cos::Array = Cos::Array.new
    @c1 : Cos::Array = Cos::Array.new
    @exponent : Float32 = 0.0_f32

    # Constructor.
    def initialize(function : Cos::Base)
      super(function)

      cos_object = self.cos_object

      # C0
      c0_entry = cos_object[Cos::Name::C0].as?(Cos::Array)
      @c0 = c0_entry || Cos::Array.new
      if @c0.size == 0
        @c0.add(Cos::Float.new(0.0))
      end

      # C1
      c1_entry = cos_object[Cos::Name::C1].as?(Cos::Array)
      @c1 = c1_entry || Cos::Array.new
      if @c1.size == 0
        @c1.add(Cos::Float.new(1.0))
      end

      # Exponent N
      n_entry = cos_object[Cos::Name::N]
      @exponent = n_entry.is_a?(Cos::Number) ? n_entry.as(Cos::Number).value.to_f32 : 0.0_f32
    end

    # Returns the function type (2 for exponential interpolation)
    def function_type : Int32
      2
    end

    # Performs exponential interpolation
    def eval(input : Array(Float32)) : Array(Float32)
      # exponential interpolation
      x_to_n = input[0] ** @exponent # x^exponent

      result_size = Math.min(@c0.size, @c1.size)
      result = Array(Float32).new(result_size, 0.0_f32)
      result_size.times do |j|
        c0j = @c0[j].as(Cos::Number).value.to_f32
        c1j = @c1[j].as(Cos::Number).value.to_f32
        result[j] = c0j + x_to_n * (c1j - c0j)
      end

      clip_to_range(result)
    end

    # Returns the C0 values of the function, 0 if empty.
    def c0 : Cos::Array
      @c0
    end

    # Returns the C1 values of the function, 1 if empty.
    def c1 : Cos::Array
      @c1
    end

    # Returns the exponent of the function.
    def n : Float32
      @exponent
    end

    def to_s : String
      "FunctionType2{C0: #{c0} C1: #{c1} N: #{n}}"
    end
  end
end
