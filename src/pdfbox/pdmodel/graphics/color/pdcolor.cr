# A color value, consisting of one or more color components, or for pattern color spaces,
# a name and optional color components.
# Color values are not associated with any given color space.
# Instances of PDColor are immutable.
module Pdfbox::Pdmodel::Graphics::Color
  class PDColor
    @components : Array(Float32)
    @pattern_name : Cos::Name?
    @color_space : PDColorSpace?

    # Creates a PDColor containing the given color value from COSArray
    def initialize(array : Cos::Array, color_space : PDColorSpace?)
      if !array.items.empty? && array.items.last.is_a?(Cos::Name)
        # color components (optional), for the color of an uncoloured tiling pattern
        @components = Array(Float32).new(array.size - 1, 0.0_f32)
        init_components(array)

        # pattern name (required)
        base = array.items.last
        @pattern_name = base.is_a?(Cos::Name) ? base : Cos::Name.new("Unknown")
      else
        # color components only
        @components = Array(Float32).new(array.size, 0.0_f32)
        init_components(array)
        @pattern_name = nil
      end
      @color_space = color_space
    end

    private def init_components(array : Cos::Array)
      @components.each_index do |i|
        base = array[i]
        @components[i] = case base
                         when Cos::Integer
                           base.value.to_f32
                         when Cos::Float
                           base.value.to_f32
                         else
                           0.0_f32
                         end
      end
    end

    # Creates a PDColor containing the given color component values
    def initialize(components : Array(Float32), color_space : PDColorSpace?)
      @components = components.dup
      @pattern_name = nil
      @color_space = color_space
    end

    # Creates a PDColor containing the given pattern name
    def initialize(pattern_name : Cos::Name, color_space : PDColorSpace?)
      @components = [] of Float32
      @pattern_name = pattern_name
      @color_space = color_space
    end

    # Creates a PDColor containing the given color component values and pattern name
    def initialize(components : Array(Float32), pattern_name : Cos::Name, color_space : PDColorSpace?)
      @components = components.dup
      @pattern_name = pattern_name
      @color_space = color_space
    end

    # Returns the components of this color value
    def components : Array(Float32)
      if @color_space.is_a?(PDPattern) || @color_space.nil?
        # colorspace of the pattern color isn't known, so just clone
        # null colorspace can happen with empty annotation color
        @components.dup
      else
        # Return array sized to match color space component count
        count = @color_space.not_nil!.number_of_components
        result = Array(Float32).new(count, 0.0_f32)
        @components.each_with_index do |val, i|
          break if i >= count
          result[i] = val
        end
        result
      end
    end

    # Returns the pattern name from this color value
    def pattern_name : Cos::Name?
      @pattern_name
    end

    # Returns true if this color value is a pattern
    def pattern? : Bool
      !@pattern_name.nil?
    end

    # Returns the packed RGB value for this color
    def to_rgb : Int32
      raise "Cannot convert pattern to RGB" if pattern?
      floats = @color_space.not_nil!.to_rgb(@components)
      r = (floats[0] * 255).round.to_i32
      g = (floats[1] * 255).round.to_i32
      b = (floats[2] * 255).round.to_i32
      (r << 16) | (g << 8) | b
    end

    # Returns the color component values as a COS array
    def to_cos_array : Cos::Array
      array = Cos::Array.new
      @components.each do |comp|
        array.add(Cos::Float.new(comp))
      end
      if pattern = @pattern_name
        array.add(pattern)
      end
      array
    end

    # Returns the color space in which this color value is defined
    def color_space : PDColorSpace?
      @color_space
    end

    def to_s : String
      "PDColor{components=#{@components}, patternName=#{@pattern_name}, colorSpace=#{@color_space}}"
    end
  end
end
