# Blend mode for compositing.
# Port of Apache PDFBox BlendMode.
module Pdfbox::Pdmodel::Graphics::Blend
  # Represents a PDF blend mode for compositing operations.
  class BlendMode
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

      COS_NAME_MAP = {
        "Normal"     => Normal,
        "Compatible" => Normal,
        "Multiply"   => Multiply,
        "Screen"     => Screen,
        "Overlay"    => Overlay,
        "Darken"     => Darken,
        "Lighten"    => Lighten,
        "ColorDodge" => ColorDodge,
        "ColorBurn"  => ColorBurn,
        "HardLight"  => HardLight,
        "SoftLight"  => SoftLight,
        "Difference" => Difference,
        "Exclusion"  => Exclusion,
        "Hue"        => Hue,
        "Saturation" => Saturation,
        "Color"      => Color,
        "Luminosity" => Luminosity,
      }

      MODE_TO_COS_NAME = {
        Normal     => "Normal",
        Multiply   => "Multiply",
        Screen     => "Screen",
        Overlay    => "Overlay",
        Darken     => "Darken",
        Lighten    => "Lighten",
        ColorDodge => "ColorDodge",
        ColorBurn  => "ColorBurn",
        HardLight  => "HardLight",
        SoftLight  => "SoftLight",
        Difference => "Difference",
        Exclusion  => "Exclusion",
        Hue        => "Hue",
        Saturation => "Saturation",
        Color      => "Color",
        Luminosity => "Luminosity",
      }

      def self.from_cos_name(name : String) : Mode
        COS_NAME_MAP.fetch(name, Normal)
      end

      def to_cos_name : String
        MODE_TO_COS_NAME.fetch(self, "Normal")
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

    property mode : Mode

    def initialize(@mode : Mode = Mode::Normal)
    end

    def self.normal : BlendMode
      @@normal ||= BlendMode.new(Mode::Normal)
    end

    # Returns the blend mode from a COSBase name or array.
    def self.get_instance(cos_blend_mode : Pdfbox::Cos::Base) : BlendMode
      case cos_blend_mode
      when Pdfbox::Cos::Name
        name = cos_blend_mode.name
        mode = Mode.from_cos_name(name)
        BlendMode.new(mode)
      when Pdfbox::Cos::Array
        cos_blend_mode.items.each do |item|
          if item.is_a?(Pdfbox::Cos::Name)
            name = item.name
            mode = Mode.from_cos_name(name)
            return BlendMode.new(mode) unless mode.normal?
          end
        end
        BlendMode.new(Mode::Normal)
      else
        BlendMode.new(Mode::Normal)
      end
    end

    def to_s(io : ::IO) : Nil
      io << "BlendMode{" << mode.to_s << "}"
    end
  end
end
