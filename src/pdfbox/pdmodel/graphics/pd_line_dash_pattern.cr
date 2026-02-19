module Pdfbox::Pdmodel::Graphics
  # Port of Apache PDFBox PDLineDashPattern.
  class PDLineDashPattern
    @phase : Int32
    @array : Array(Float64)

    def initialize
      @array = [] of Float64
      @phase = 0
    end

    def initialize(array : Pdfbox::Cos::Array, phase : Int32 | Int64 | Int)
      @array = array.to_float_array
      @phase = normalize_phase(@array, phase.to_i32)
    end

    def cos_object : Pdfbox::Cos::Base
      dash_array = Pdfbox::Cos::Array.new
      @array.each do |value|
        dash_array.add(Pdfbox::Cos::Float.new(value))
      end

      cos = Pdfbox::Cos::Array.new
      cos.add(dash_array)
      cos.add(Pdfbox::Cos::Integer.get(@phase.to_i64))
      cos
    end

    def phase : Int32
      @phase
    end

    def dash_array : Array(Float64)
      @array.dup
    end

    def to_s(io : ::IO) : Nil
      io << "PDLineDashPattern{array=" << @array << ", phase=" << @phase << "}"
    end

    private def normalize_phase(array : Array(Float64), phase : Int32) : Int32
      return phase if phase >= 0

      sum2 = array.sum * 2
      return 0 if sum2 <= 0

      adjustment =
        if -phase < sum2
          sum2
        else
          ((-phase / sum2).floor + 1) * sum2
        end
      (phase + adjustment).to_i32
    end
  end
end
