module Fontbox
  module AFM
    class Parser
      # This is a comment in a AFM file.
      COMMENT = "Comment"
      # This is the constant used in the AFM file to start a font metrics item.
      START_FONT_METRICS = "StartFontMetrics"
      # This is the constant used in the AFM file to end a font metrics item.
      END_FONT_METRICS = "EndFontMetrics"
      # This is the font name.
      FONT_NAME = "FontName"
      # This is the full name.
      FULL_NAME = "FullName"
      # This is the Family name.
      FAMILY_NAME = "FamilyName"
      # This is the weight.
      WEIGHT = "Weight"
      # This is the font bounding box.
      FONT_BBOX = "FontBBox"
      # This is the version of the font.
      VERSION = "Version"
      # This is the notice.
      NOTICE = "Notice"
      # This is the encoding scheme.
      ENCODING_SCHEME = "EncodingScheme"
      # This is the mapping scheme.
      MAPPING_SCHEME = "MappingScheme"
      # This is the escape character.
      ESC_CHAR = "EscChar"
      # This is the character set.
      CHARACTER_SET = "CharacterSet"
      # This is the characters attribute.
      CHARACTERS = "Characters"
      # This will determine if this is a base font.
      IS_BASE_FONT = "IsBaseFont"
      # This is the V Vector attribute.
      V_VECTOR = "VVector"
      # This will tell if the V is fixed.
      IS_FIXED_V = "IsFixedV"
      # This is the cap height attribute.
      CAP_HEIGHT = "CapHeight"
      # This is the X height.
      X_HEIGHT = "XHeight"
      # This is ascender attribute.
      ASCENDER = "Ascender"
      # This is the descender attribute.
      DESCENDER = "Descender"

      # The underline position.
      UNDERLINE_POSITION = "UnderlinePosition"
      # This is the Underline thickness.
      UNDERLINE_THICKNESS = "UnderlineThickness"
      # This is the italic angle.
      ITALIC_ANGLE = "ItalicAngle"
      # This is the char width.
      CHAR_WIDTH = "CharWidth"
      # This will determine if this is fixed pitch.
      IS_FIXED_PITCH = "IsFixedPitch"
      # This is the start of character metrics.
      START_CHAR_METRICS = "StartCharMetrics"
      # This is the end of character metrics.
      END_CHAR_METRICS = "EndCharMetrics"
      # The character metrics c value.
      CHARMETRICS_C = "C"
      # The character metrics c value.
      CHARMETRICS_CH = "CH"
      # The character metrics value.
      CHARMETRICS_WX = "WX"
      # The character metrics value.
      CHARMETRICS_W0X = "W0X"
      # The character metrics value.
      CHARMETRICS_W1X = "W1X"
      # The character metrics value.
      CHARMETRICS_WY = "WY"
      # The character metrics value.
      CHARMETRICS_W0Y = "W0Y"
      # The character metrics value.
      CHARMETRICS_W1Y = "W1Y"
      # The character metrics value.
      CHARMETRICS_W = "W"
      # The character metrics value.
      CHARMETRICS_W0 = "W0"
      # The character metrics value.
      CHARMETRICS_W1 = "W1"
      # The character metrics value.
      CHARMETRICS_VV = "VV"
      # The character metrics value.
      CHARMETRICS_N = "N"
      # The character metrics value.
      CHARMETRICS_B = "B"
      # The character metrics value.
      CHARMETRICS_L = "L"
      STD_HW        = "StdHW"
      STD_VW        = "StdVW"
      # This is the start of track kern data.
      START_TRACK_KERN = "StartTrackKern"
      # This is the end of track kern data.
      END_TRACK_KERN = "EndTrackKern"
      # This is the start of kern data.
      START_KERN_DATA = "StartKernData"
      # This is the end of kern data.
      END_KERN_DATA = "EndKernData"
      # This is the start of kern pairs data.
      START_KERN_PAIRS = "StartKernPairs"
      # This is the end of kern pairs data.
      END_KERN_PAIRS = "EndKernPairs"
      # This is the start of kern pairs data.
      START_KERN_PAIRS0 = "StartKernPairs0"
      # This is the start of kern pairs data.
      START_KERN_PAIRS1 = "StartKernPairs1"
      # This is the start composites data section.
      START_COMPOSITES = "StartComposites"
      # This is the end composites data section.
      END_COMPOSITES = "EndComposites"
      # This is a composite character.
      CC = "CC"
      # This is a composite character part.
      PCC = "PCC"
      # This is a kern pair.
      KERN_PAIR_KP = "KP"
      # This is a kern pair.
      KERN_PAIR_KPH = "KPH"
      # This is a kern pair.
      KERN_PAIR_KPX = "KPX"
      # This is a kern pair.
      KERN_PAIR_KPY = "KPY"

      BITS_IN_HEX = 16

      private getter input : IO

      def initialize(@input : IO)
      end

      def parse(reduced_dataset = false) : FontMetrics
        parse_font_metric(reduced_dataset)
      end

      private def parse_font_metric(reduced_dataset : Bool) : FontMetrics
        read_command(START_FONT_METRICS)
        font_metrics = FontMetrics.new
        font_metrics.afm_version = read_float
        char_metrics_read = false
        loop do
          next_command = read_string
          break if next_command == END_FONT_METRICS
          case next_command
          when FONT_NAME
            font_metrics.font_name = read_line
          when FULL_NAME
            font_metrics.full_name = read_line
          when FAMILY_NAME
            font_metrics.family_name = read_line
          when WEIGHT
            font_metrics.weight = read_line
          when FONT_BBOX
            bbox = Fontbox::Util::BoundingBox.new(read_float, read_float, read_float, read_float)
            font_metrics.font_b_box = bbox
          when VERSION
            font_metrics.font_version = read_line
          when NOTICE
            font_metrics.notice = read_line
          when ENCODING_SCHEME
            font_metrics.encoding_scheme = read_line
          when MAPPING_SCHEME
            font_metrics.mapping_scheme = read_int
          when ESC_CHAR
            font_metrics.esc_char = read_int
          when CHARACTER_SET
            font_metrics.character_set = read_line
          when CHARACTERS
            font_metrics.characters = read_int
          when IS_BASE_FONT
            font_metrics.is_base_font = read_boolean
          when V_VECTOR
            font_metrics.v_vector = [read_float, read_float]
          when IS_FIXED_V
            font_metrics.is_fixed_v = read_boolean
          when CAP_HEIGHT
            font_metrics.cap_height = read_float
          when X_HEIGHT
            font_metrics.x_height = read_float
          when ASCENDER
            font_metrics.ascender = read_float
          when DESCENDER
            font_metrics.descender = read_float
          when STD_HW
            font_metrics.standard_horizontal_width = read_float
          when STD_VW
            font_metrics.standard_vertical_width = read_float
          when COMMENT
            font_metrics.add_comment(read_line)
          when UNDERLINE_POSITION
            font_metrics.underline_position = read_float
          when UNDERLINE_THICKNESS
            font_metrics.underline_thickness = read_float
          when ITALIC_ANGLE
            font_metrics.italic_angle = read_float
          when CHAR_WIDTH
            font_metrics.char_width = [read_float, read_float]
          when IS_FIXED_PITCH
            font_metrics.is_fixed_pitch = read_boolean
          when START_CHAR_METRICS
            char_metrics_read = parse_char_metrics(font_metrics)
          when START_KERN_DATA
            parse_kern_data(font_metrics) unless reduced_dataset
          when START_COMPOSITES
            parse_composites(font_metrics) unless reduced_dataset
          else
            if !reduced_dataset || !char_metrics_read
              raise IO::Error.new("Unknown AFM key '#{next_command}'")
            end
          end
        end
        font_metrics
      end

      private def eol?(byte : Int32) : Bool
        byte == 0x0D || byte == 0x0A
      end

      private def whitespace?(byte : Int32) : Bool
        case byte
        when ' '.ord, '\t'.ord, 0x0D, 0x0A
          true
        else
          false
        end
      end

      private def read_string : String
        # First skip the whitespace
        buf = String::Builder.new
        next_byte = input.read_byte
        while next_byte && whitespace?(next_byte)
          next_byte = input.read_byte
        end
        # If EOF reached while skipping whitespace, return empty string
        return "" unless next_byte
        buf.write_byte(next_byte)

        # now read the data
        while (next_byte = input.read_byte) && !whitespace?(next_byte)
          buf.write_byte(next_byte)
        end
        buf.to_s
      end

      private def read_line : String
        # First skip the whitespace
        buf = String::Builder.new
        next_byte = input.read_byte
        while next_byte && whitespace?(next_byte)
          next_byte = input.read_byte
        end
        # If EOF reached while skipping whitespace, return empty string
        return "" unless next_byte
        buf.write_byte(next_byte)

        # now read the data
        while (next_byte = input.read_byte) && !eol?(next_byte)
          buf.write_byte(next_byte)
        end
        buf.to_s
      end

      private def read_command(expected_command : String)
        command = read_string
        if command != expected_command
          raise IO::Error.new("Error: Expected '#{expected_command}' actual '#{command}'")
        end
      end

      private def read_int : Int32
        parse_int(read_string, 10)
      end

      private def read_float : Float32
        parse_float(read_string)
      end

      private def read_boolean : Bool
        str = read_string
        str == "true"
      end

      private def parse_int(int_value : String, radix = 10) : Int32
        int_value.to_i32(radix)
      rescue ArgumentError
        raise IO::Error.new("Error parsing AFM document: invalid integer '#{int_value}'")
      end

      private def parse_float(float_value : String) : Float32
        float_value.to_f32
      rescue ArgumentError
        raise IO::Error.new("Error parsing AFM document: invalid float '#{float_value}'")
      end

      private def hex_to_string(hex_to_string : String) : String
        if hex_to_string.size < 2
          raise IO::Error.new("Error: Expected hex string of length >= 2 not='#{hex_to_string}'")
        end
        if hex_to_string[0] != '<' || hex_to_string[hex_to_string.size - 1] != '>'
          raise IO::Error.new("String should be enclosed by angle brackets '#{hex_to_string}'")
        end
        hex_string = hex_to_string[1...-1]
        bytes = Bytes.new(hex_string.size // 2)
        i = 0
        while i < hex_string.size
          hex = hex_string[i].to_s + hex_string[i + 1].to_s
          bytes[i // 2] = parse_int(hex, BITS_IN_HEX).to_u8
          i += 2
        end
        String.new(bytes, "ISO-8859-1")
      end

      private def parse_char_metrics(font_metrics : FontMetrics) : Bool
        count_metrics = read_int
        count_metrics.times do
          font_metrics.add_char_metric(parse_char_metric)
        end
        read_command(END_CHAR_METRICS)
        true
      end

      private def parse_char_metric : CharMetric
        char_metric = CharMetric.new
        metrics = read_line
        tokens = metrics.split
        i = 0
        while i < tokens.size
          next_command = tokens[i]
          i += 1
          case next_command
          when CHARMETRICS_C
            char_code_c = tokens[i]
            i += 1
            char_metric.character_code = parse_int(char_code_c)
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_WX
            char_metric.wx = parse_float(tokens[i])
            i += 1
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_N
            char_metric.name = tokens[i]
            i += 1
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_B
            llx = parse_float(tokens[i]); i += 1
            lly = parse_float(tokens[i]); i += 1
            urx = parse_float(tokens[i]); i += 1
            ury = parse_float(tokens[i]); i += 1
            char_metric.bounding_box = Fontbox::Util::BoundingBox.new(llx, lly, urx, ury)
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_L
            successor = tokens[i]; i += 1
            ligature = tokens[i]; i += 1
            char_metric.add_ligature(Ligature.new(successor, ligature))
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_CH
            char_code_ch = tokens[i]
            i += 1
            char_metric.character_code = parse_int(char_code_ch, BITS_IN_HEX)
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_W0X
            char_metric.w0x = parse_float(tokens[i])
            i += 1
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_W1X
            char_metric.w1x = parse_float(tokens[i])
            i += 1
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_WY
            char_metric.wy = parse_float(tokens[i])
            i += 1
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_W0Y
            char_metric.w0y = parse_float(tokens[i])
            i += 1
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_W1Y
            char_metric.w1y = parse_float(tokens[i])
            i += 1
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_W
            w0 = parse_float(tokens[i]); i += 1
            w1 = parse_float(tokens[i]); i += 1
            char_metric.w = [w0, w1]
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_W0
            w00 = parse_float(tokens[i]); i += 1
            w01 = parse_float(tokens[i]); i += 1
            char_metric.w0 = [w00, w01]
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_W1
            w10 = parse_float(tokens[i]); i += 1
            w11 = parse_float(tokens[i]); i += 1
            char_metric.w1 = [w10, w11]
            verify_semicolon(tokens, i)
            i += 1
          when CHARMETRICS_VV
            vv0 = parse_float(tokens[i]); i += 1
            vv1 = parse_float(tokens[i]); i += 1
            char_metric.vv = [vv0, vv1]
            verify_semicolon(tokens, i)
            i += 1
          else
            raise IO::Error.new("Unknown CharMetrics command '#{next_command}'")
          end
        end
        char_metric
      end

      private def verify_semicolon(tokens : Array(String), index : Int32)
        if index < tokens.size
          semicolon = tokens[index]
          if semicolon != ";"
            raise IO::Error.new("Error: Expected semicolon in stream actual='#{semicolon}'")
          end
        else
          raise IO::Error.new("CharMetrics is missing a semicolon after a command")
        end
      end

      private def parse_kern_data(font_metrics : FontMetrics)
        next_command = read_string
        until next_command == END_KERN_DATA
          case next_command
          when START_TRACK_KERN
            count_track_kern = read_int
            count_track_kern.times do
              font_metrics.add_track_kern(TrackKern.new(read_int, read_float, read_float, read_float, read_float))
            end
            read_command(END_TRACK_KERN)
          when START_KERN_PAIRS
            parse_kern_pairs(font_metrics)
          when START_KERN_PAIRS0
            parse_kern_pairs0(font_metrics)
          when START_KERN_PAIRS1
            parse_kern_pairs1(font_metrics)
          else
            raise IO::Error.new("Unknown kerning data type '#{next_command}'")
          end
          next_command = read_string
        end
      end

      private def parse_kern_pairs(font_metrics : FontMetrics)
        count_kern_pairs = read_int
        count_kern_pairs.times do
          font_metrics.add_kern_pair(parse_kern_pair)
        end
        read_command(END_KERN_PAIRS)
      end

      private def parse_kern_pairs0(font_metrics : FontMetrics)
        count_kern_pairs = read_int
        count_kern_pairs.times do
          font_metrics.add_kern_pair0(parse_kern_pair)
        end
        read_command(END_KERN_PAIRS)
      end

      private def parse_kern_pairs1(font_metrics : FontMetrics)
        count_kern_pairs = read_int
        count_kern_pairs.times do
          font_metrics.add_kern_pair1(parse_kern_pair)
        end
        read_command(END_KERN_PAIRS)
      end

      private def parse_kern_pair : KernPair
        cmd = read_string
        case cmd
        when KERN_PAIR_KP
          KernPair.new(read_string, read_string, read_float, read_float)
        when KERN_PAIR_KPH
          KernPair.new(hex_to_string(read_string), hex_to_string(read_string), read_float, read_float)
        when KERN_PAIR_KPX
          KernPair.new(read_string, read_string, read_float, 0.0_f32)
        when KERN_PAIR_KPY
          KernPair.new(read_string, read_string, 0.0_f32, read_float)
        else
          raise IO::Error.new("Error expected kern pair command actual='#{cmd}'")
        end
      end

      private def parse_composites(font_metrics : FontMetrics)
        count_composites = read_int
        count_composites.times do
          font_metrics.add_composite(parse_composite)
        end
        read_command(END_COMPOSITES)
      end

      private def parse_composite : Composite
        part_data = read_line
        tokens = part_data.split(/\s+|;/)
        i = 0
        cc = tokens[i]; i += 1
        if cc != CC
          raise IO::Error.new("Expected '#{CC}' actual='#{cc}'")
        end
        name = tokens[i]; i += 1
        composite = Composite.new(name)
        part_count = parse_int(tokens[i]); i += 1
        part_count.times do
          pcc = tokens[i]; i += 1
          if pcc != PCC
            raise IO::Error.new("Expected '#{PCC}' actual='#{pcc}'")
          end
          part_name = tokens[i]; i += 1
          x = parse_int(tokens[i]); i += 1
          y = parse_int(tokens[i]); i += 1
          composite.add_part(CompositePart.new(part_name, x, y))
        end
        composite
      end
    end
  end
end
