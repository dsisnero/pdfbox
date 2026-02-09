module Fontbox
  module AFM
    class FontMetrics
      property afm_version, font_name, full_name, family_name, weight, font_b_box, font_version,
        notice, encoding_scheme, mapping_scheme, esc_char, character_set, characters,
        is_base_font, v_vector, is_fixed_v, cap_height, x_height, ascender, descender,
        standard_horizontal_width, standard_vertical_width, underline_position,
        underline_thickness, italic_angle, char_width, is_fixed_pitch, comments,
        char_metrics, kern_pairs, kern_pairs0, kern_pairs1, composites, track_kern,
        metric_sets
      property char_metrics_map

      def initialize
        @afm_version = 0.0_f32
        @font_name = ""
        @full_name = ""
        @family_name = ""
        @weight = ""
        @font_b_box = Fontbox::Util::BoundingBox.new(0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32)
        @font_version = ""
        @notice = ""
        @encoding_scheme = ""
        @mapping_scheme = 0
        @esc_char = 0
        @character_set = ""
        @characters = 0
        @is_base_font = false
        @v_vector = [] of Float32
        @is_fixed_v = false
        @cap_height = 0.0_f32
        @x_height = 0.0_f32
        @ascender = 0.0_f32
        @descender = 0.0_f32
        @standard_horizontal_width = 0.0_f32
        @standard_vertical_width = 0.0_f32
        @underline_position = 0.0_f32
        @underline_thickness = 0.0_f32
        @italic_angle = 0.0_f32
        @char_width = [] of Float32
        @is_fixed_pitch = false
        @comments = [] of String
        @char_metrics = [] of CharMetric
        @char_metrics_map = {} of String => CharMetric
        @kern_pairs = [] of KernPair
        @kern_pairs0 = [] of KernPair
        @kern_pairs1 = [] of KernPair
        @composites = [] of Composite
        @track_kern = [] of TrackKern
        @metric_sets = 0
      end

      def add_comment(comment : String)
        @comments << comment
      end

      def add_char_metric(char_metric : CharMetric)
        @char_metrics << char_metric
        @char_metrics_map[char_metric.name] = char_metric
      end

      def add_composite(composite : Composite)
        @composites << composite
      end

      def add_kern_pair(kern_pair : KernPair)
        @kern_pairs << kern_pair
      end

      def add_kern_pair0(kern_pair : KernPair)
        @kern_pairs0 << kern_pair
      end

      def add_kern_pair1(kern_pair : KernPair)
        @kern_pairs1 << kern_pair
      end

      def add_track_kern(track_kern : TrackKern)
        @track_kern << track_kern
      end

      def character_width(name : String) : Float32
        result = 0.0_f32
        metric = @char_metrics_map[name]?
        if metric
          result = metric.wx
        end
        result
      end

      def character_height(name : String) : Float32
        result = 0.0_f32
        metric = @char_metrics_map[name]?
        if metric
          result = metric.wy
          if result == 0.0_f32
            result = metric.bounding_box.height
          end
        end
        result
      end

      def average_character_width : Float32
        average = 0.0_f32
        total_widths = 0.0_f32
        character_count = 0.0_f32
        @char_metrics.each do |metric|
          if metric.wx > 0.0_f32
            total_widths += metric.wx
            character_count += 1.0_f32
          end
        end
        if total_widths > 0.0_f32
          average = total_widths / character_count
        end
        average
      end
    end
  end
end
