# Blend mode for compositing.
# Port of Apache PDFBox BlendMode.
module Pdfbox::Pdmodel::Graphics::Blend
  # Represents a PDF blend mode for compositing operations.
  class BlendMode
    # Blend channel function for separable blend modes.
    alias BlendChannelFunction = Proc(Float32, Float32, Float32)

    # Blend function for non-separable blend modes.
    alias BlendFunction = Proc(Slice(Float32), Slice(Float32), Slice(Float32), Nil)

    enum Mode
      Normal
      Multiply
      Screen
      Overlay
      Darken
      Lighten
      ColorDodge
      ColorBurn
      HardLight
      SoftLight
      Difference
      Exclusion
      Hue
      Saturation
      Color
      Luminosity

      def self.from_cos_name(name : String) : Mode
        case name
        when "Compatible" then Normal
        when "Multiply"   then Multiply
        when "Screen"     then Screen
        when "Overlay"    then Overlay
        when "Darken"     then Darken
        when "Lighten"    then Lighten
        when "ColorDodge" then ColorDodge
        when "ColorBurn"  then ColorBurn
        when "HardLight"  then HardLight
        when "SoftLight"  then SoftLight
        when "Difference" then Difference
        when "Exclusion"  then Exclusion
        when "Hue"        then Hue
        when "Saturation" then Saturation
        when "Color"      then Color
        when "Luminosity" then Luminosity
        else
          Normal
        end
      end

      def to_cos_name : String
        case self
        when Normal     then "Normal"
        when Multiply   then "Multiply"
        when Screen     then "Screen"
        when Overlay    then "Overlay"
        when Darken     then "Darken"
        when Lighten    then "Lighten"
        when ColorDodge then "ColorDodge"
        when ColorBurn  then "ColorBurn"
        when HardLight  then "HardLight"
        when SoftLight  then "SoftLight"
        when Difference then "Difference"
        when Exclusion  then "Exclusion"
        when Hue        then "Hue"
        when Saturation then "Saturation"
        when Color      then "Color"
        when Luminosity then "Luminosity"
        else
          "Normal"
        end
      end

      # Returns true for separable blend modes.
      def separable? : Bool
        case self
        when .normal?, .multiply?, .screen?, .overlay?, .darken?, .lighten?,
             .color_dodge?, .color_burn?, .hard_light?, .soft_light?,
             .difference?, .exclusion?
          true
        else
          false
        end
      end
    end

    @@instances = {} of Mode => BlendMode
    @@blend_modes : Hash(String, BlendMode)?

    getter mode : Mode
    getter cos_name : Pdfbox::Cos::Name
    getter blend_channel_function : BlendChannelFunction?
    getter blend_function : BlendFunction?

    def initialize(@mode : Mode = Mode::Normal)
      @cos_name = Pdfbox::Cos::Name.new(@mode.to_cos_name)
      case @mode
      when .normal?
        @blend_channel_function = ->(src : Float32, _dest : Float32) { src }
        @blend_function = nil
      when .multiply?
        @blend_channel_function = ->(src : Float32, dest : Float32) { src * dest }
        @blend_function = nil
      when .screen?
        @blend_channel_function = ->(src : Float32, dest : Float32) { src + dest - src * dest }
        @blend_function = nil
      when .overlay?
        @blend_channel_function = ->(src : Float32, dest : Float32) {
          dest <= 0.5 ? 2 * dest * src : 2 * (src + dest - src * dest) - 1
        }
        @blend_function = nil
      when .darken?
        @blend_channel_function = ->(src : Float32, dest : Float32) { Math.min(src, dest) }
        @blend_function = nil
      when .lighten?
        @blend_channel_function = ->(src : Float32, dest : Float32) { Math.max(src, dest) }
        @blend_function = nil
      when .color_dodge?
        @blend_channel_function = ->(src : Float32, dest : Float32) {
          # See PDF 2.0 specification
          return 0.0_f32 if dest == 0.0_f32
          return 1.0_f32 if dest >= 1 - src
          dest / (1 - src)
        }
        @blend_function = nil
      when .color_burn?
        @blend_channel_function = ->(src : Float32, dest : Float32) {
          # See PDF 2.0 specification
          return 1.0_f32 if dest == 1.0_f32
          return 0.0_f32 if 1 - dest >= src
          1 - (1 - dest) / src
        }
        @blend_function = nil
      when .hard_light?
        @blend_channel_function = ->(src : Float32, dest : Float32) {
          src <= 0.5 ? 2 * dest * src : 2 * (src + dest - src * dest) - 1
        }
        @blend_function = nil
      when .soft_light?
        @blend_channel_function = ->(src : Float32, dest : Float32) {
          if src <= 0.5
            dest - (1 - 2 * src) * dest * (1 - dest)
          else
            d = dest <= 0.25 ? ((16 * dest - 12) * dest + 4) * dest : Math.sqrt(dest).to_f32
            dest + (2 * src - 1) * (d - dest)
          end
        }
        @blend_function = nil
      when .difference?
        @blend_channel_function = ->(src : Float32, dest : Float32) { (dest - src).abs }
        @blend_function = nil
      when .exclusion?
        @blend_channel_function = ->(src : Float32, dest : Float32) { dest + src - 2 * dest * src }
        @blend_function = nil
      when .hue?
        @blend_channel_function = nil
        @blend_function = ->(src : Slice(Float32), dest : Slice(Float32), result : Slice(Float32)) {
          temp = Slice(Float32).new(3)
          BlendMode.get_saturation_rgb(dest, src, temp)
          BlendMode.get_luminosity_rgb(dest, temp, result)
        }
      when .saturation?
        @blend_channel_function = nil
        @blend_function = ->(src : Slice(Float32), dest : Slice(Float32), result : Slice(Float32)) {
          BlendMode.get_saturation_rgb(src, dest, result)
        }
      when .color?
        @blend_channel_function = nil
        @blend_function = ->(src : Slice(Float32), dest : Slice(Float32), result : Slice(Float32)) {
          BlendMode.get_luminosity_rgb(dest, src, result)
        }
      when .luminosity?
        @blend_channel_function = nil
        @blend_function = ->(src : Slice(Float32), dest : Slice(Float32), result : Slice(Float32)) {
          BlendMode.get_luminosity_rgb(src, dest, result)
        }
      end
    end

    def self.instance_for(mode : Mode) : BlendMode
      @@instances[mode] ||= BlendMode.new(mode)
    end

    def self.normal : BlendMode
      instance_for(Mode::Normal)
    end

    def self.compatible : BlendMode
      normal
    end

    def self.multiply : BlendMode
      instance_for(Mode::Multiply)
    end

    def self.screen : BlendMode
      instance_for(Mode::Screen)
    end

    def self.overlay : BlendMode
      instance_for(Mode::Overlay)
    end

    def self.darken : BlendMode
      instance_for(Mode::Darken)
    end

    def self.lighten : BlendMode
      instance_for(Mode::Lighten)
    end

    def self.color_dodge : BlendMode
      instance_for(Mode::ColorDodge)
    end

    def self.color_burn : BlendMode
      instance_for(Mode::ColorBurn)
    end

    def self.hard_light : BlendMode
      instance_for(Mode::HardLight)
    end

    def self.soft_light : BlendMode
      instance_for(Mode::SoftLight)
    end

    def self.difference : BlendMode
      instance_for(Mode::Difference)
    end

    def self.exclusion : BlendMode
      instance_for(Mode::Exclusion)
    end

    def self.hue : BlendMode
      instance_for(Mode::Hue)
    end

    def self.saturation : BlendMode
      instance_for(Mode::Saturation)
    end

    def self.luminosity : BlendMode
      instance_for(Mode::Luminosity)
    end

    def self.color : BlendMode
      instance_for(Mode::Color)
    end

    # Returns the blend mode from a COSBase name or array.
    def self.get_instance(cos_blend_mode : Pdfbox::Cos::Base) : BlendMode
      case cos_blend_mode
      when Pdfbox::Cos::Name
        blend_modes[cos_blend_mode.value]? || normal
      when Pdfbox::Cos::Array
        cos_blend_mode.items.each do |item|
          if item.is_a?(Pdfbox::Cos::Name)
            if mode = blend_modes[item.value]?
              return mode
            end
          end
        end
        normal
      else
        normal
      end
    end

    # Determines if the blend mode is a separable blend mode.
    def separable_blend_mode? : Bool
      !@blend_channel_function.nil?
    end

    def to_s(io : ::IO) : Nil
      io << "BlendMode{name=" << @cos_name.value << ", isSeparable=" << separable_blend_mode? << "}"
    end

    private def self.blend_modes : Hash(String, BlendMode)
      @@blend_modes ||= {
        "Normal"     => normal,
        "Compatible" => normal,
        "Multiply"   => multiply,
        "Screen"     => screen,
        "Overlay"    => overlay,
        "Darken"     => darken,
        "Lighten"    => lighten,
        "ColorDodge" => color_dodge,
        "ColorBurn"  => color_burn,
        "HardLight"  => hard_light,
        "SoftLight"  => soft_light,
        "Difference" => difference,
        "Exclusion"  => exclusion,
        "Hue"        => hue,
        "Saturation" => saturation,
        "Luminosity" => luminosity,
        "Color"      => color,
      }
    end

    def self.get_255_value(val : Float32) : Int32
      if val >= 1.0
        255
      else
        (val * 255.0).floor.to_i32
      end
    end

    def self.get_saturation_rgb(src_values : Slice(Float32), dst_values : Slice(Float32), result : Slice(Float32)) : Nil
      rd = get_255_value(dst_values[0])
      gd = get_255_value(dst_values[1])
      bd = get_255_value(dst_values[2])

      minb = Math.min(rd, Math.min(gd, bd))
      maxb = Math.max(rd, Math.max(gd, bd))
      if minb == maxb
        # backdrop has zero saturation, avoid divide by 0
        result[0] = gd / 255.0_f32
        result[1] = gd / 255.0_f32
        result[2] = gd / 255.0_f32
        return
      end

      rs = get_255_value(src_values[0])
      gs = get_255_value(src_values[1])
      bs = get_255_value(src_values[2])

      mins = Math.min(rs, Math.min(gs, bs))
      maxs = Math.max(rs, Math.max(gs, bs))

      scale = ((maxs - mins) << 16) // (maxb - minb)
      y = (rd * 77 + gd * 151 + bd * 28 + 0x80) >> 8
      r = y + ((((rd - y) * scale) + 0x8000) >> 16)
      g = y + ((((gd - y) * scale) + 0x8000) >> 16)
      b = y + ((((bd - y) * scale) + 0x8000) >> 16)

      if ((r | g | b) & 0x100) == 0x100
        min = Math.min(r, Math.min(g, b))
        max = Math.max(r, Math.max(g, b))

        scalemin = min < 0 ? (y << 16) // (y - min) : 0x10000
        scalemax = max > 255 ? ((255 - y) << 16) // (max - y) : 0x10000

        scale = Math.min(scalemin, scalemax)
        r = y + (((r - y) * scale + 0x8000) >> 16)
        g = y + (((g - y) * scale + 0x8000) >> 16)
        b = y + (((b - y) * scale + 0x8000) >> 16)
      end

      result[0] = r / 255.0_f32
      result[1] = g / 255.0_f32
      result[2] = b / 255.0_f32
    end

    def self.get_luminosity_rgb(src_values : Slice(Float32), dst_values : Slice(Float32), result : Slice(Float32)) : Nil
      rd = get_255_value(dst_values[0])
      gd = get_255_value(dst_values[1])
      bd = get_255_value(dst_values[2])
      rs = get_255_value(src_values[0])
      gs = get_255_value(src_values[1])
      bs = get_255_value(src_values[2])
      delta = ((rs - rd) * 77 + (gs - gd) * 151 + (bs - bd) * 28 + 0x80) >> 8
      r = rd + delta
      g = gd + delta
      b = bd + delta

      if ((r | g | b) & 0x100) == 0x100
        y = (rs * 77 + gs * 151 + bs * 28 + 0x80) >> 8
        scale =
          if delta > 0
            max = Math.max(r, Math.max(g, b))
            max == y ? 0 : ((255 - y) << 16) // (max - y)
          else
            min = Math.min(r, Math.min(g, b))
            y == min ? 0 : (y << 16) // (y - min)
          end
        r = y + (((r - y) * scale + 0x8000) >> 16)
        g = y + (((g - y) * scale + 0x8000) >> 16)
        b = y + (((b - y) * scale + 0x8000) >> 16)
      end

      result[0] = r / 255.0_f32
      result[1] = g / 255.0_f32
      result[2] = b / 255.0_f32
    end
  end
end
