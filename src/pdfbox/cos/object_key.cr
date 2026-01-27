# COSObjectKey for identifying indirect objects
# Corresponds to COSObjectKey in Apache PDFBox
module Pdfbox::Cos
  struct ObjectKey
    NUMBER_OFFSET   = 16 # 16 bits for generation number (0-65535)
    GENERATION_MASK = (1_i64 << NUMBER_OFFSET) - 1

    @number_and_generation : Int64
    @stream_index : Int32

    def initialize(num : Int64, gen : Int64, index : Int32 = -1)
      if num < 0
        raise ArgumentError.new("Object number must not be a negative value")
      end
      if gen < 0
        raise ArgumentError.new("Generation number must not be a negative value")
      end
      @number_and_generation = self.class.compute_internal_hash(num, gen)
      @stream_index = index
    end

    def self.compute_internal_hash(num : Int64, gen : Int64) : Int64
      (num << NUMBER_OFFSET) | (gen & GENERATION_MASK)
    end

    def internal_hash : Int64
      @number_and_generation
    end

    def generation : Int64
      @number_and_generation & GENERATION_MASK
    end

    def number : Int64
      @number_and_generation >> NUMBER_OFFSET
    end

    def stream_index : Int32
      @stream_index
    end

    def ==(other : self) : Bool
      @number_and_generation == other.@number_and_generation
    end

    def_hash @number_and_generation

    def to_s(io : IO) : Nil
      io << number << " " << generation << " R"
    end

    def <=>(other : self) : Int32
      @number_and_generation <=> other.@number_and_generation
    end
  end
end
