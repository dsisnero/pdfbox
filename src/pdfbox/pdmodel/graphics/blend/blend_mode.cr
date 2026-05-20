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
        name = cos_blend_mode.value
        mode = Mode.from_cos_name(name)
        BlendMode.new(mode)
      when Pdfbox::Cos::Array
        cos_blend_mode.items.each do |item|
          if item.is_a?(Pdfbox::Cos::Name)
            name = item.value
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
