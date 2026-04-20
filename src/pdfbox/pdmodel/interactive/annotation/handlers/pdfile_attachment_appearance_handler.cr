module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDFileAttachmentAppearanceHandler < PDAbstractAppearanceHandler
    def generate_normal_appearance : Nil
      annot = wrapped_annotation.as(Annotation::PDAnnotationFileAttachment)
      rect = rectangle
      return unless rect

      content_stream = normal_appearance_as_content_stream
      set_opacity(content_stream, annot.constant_opacity)

      size = 18.0_f32
      rect.upper_right_x = rect.lower_left_x + size
      rect.lower_left_y = rect.upper_right_y - size
      annot.rectangle = rect
      annot.normal_appearance_stream.try(&.bbox = Common::PDRectangle.new(size, size))

      case annot.attachment_name
      when Annotation::PDAnnotationFileAttachment::ATTACHMENT_NAME_PAPERCLIP
        draw_paperclip(content_stream)
      when Annotation::PDAnnotationFileAttachment::ATTACHMENT_NAME_GRAPH
        draw_graph(content_stream)
      when Annotation::PDAnnotationFileAttachment::ATTACHMENT_NAME_TAG
        draw_tag(content_stream)
      else
        draw_push_pin(content_stream)
      end

      content_stream.close
    end

    private def draw_paperclip(content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream) : Nil
      content_stream.move_to(13.574_f32, 9.301_f32)
      content_stream.line_to(8.926_f32, 13.949_f32)
      content_stream.curve_to(7.648_f32, 15.227_f32, 5.625_f32, 15.227_f32, 4.426_f32, 13.949_f32)
      content_stream.curve_to(3.148_f32, 12.676_f32, 3.148_f32, 10.648_f32, 4.426_f32, 9.449_f32)
      content_stream.line_to(10.426_f32, 3.449_f32)
      content_stream.curve_to(11.176_f32, 2.773_f32, 12.301_f32, 2.773_f32, 13.051_f32, 3.449_f32)
      content_stream.curve_to(13.801_f32, 4.199_f32, 13.801_f32, 5.398_f32, 13.051_f32, 6.074_f32)
      content_stream.line_to(7.875_f32, 11.25_f32)
      content_stream.curve_to(7.648_f32, 11.477_f32, 7.273_f32, 11.477_f32, 7.051_f32, 11.25_f32)
      content_stream.curve_to(6.824_f32, 11.023_f32, 6.824_f32, 10.648_f32, 7.051_f32, 10.426_f32)
      content_stream.line_to(10.875_f32, 6.602_f32)
      content_stream.curve_to(11.176_f32, 6.301_f32, 11.176_f32, 5.852_f32, 10.875_f32, 5.551_f32)
      content_stream.curve_to(10.574_f32, 5.25_f32, 10.125_f32, 5.25_f32, 9.824_f32, 5.551_f32)
      content_stream.line_to(6.0_f32, 9.449_f32)
      content_stream.curve_to(5.176_f32, 10.273_f32, 5.176_f32, 11.551_f32, 6.0_f32, 12.375_f32)
      content_stream.curve_to(6.824_f32, 13.125_f32, 8.102_f32, 13.125_f32, 8.926_f32, 12.375_f32)
      content_stream.line_to(14.102_f32, 7.199_f32)
      content_stream.curve_to(15.449_f32, 5.852_f32, 15.449_f32, 3.75_f32, 14.102_f32, 2.398_f32)
      content_stream.curve_to(12.75_f32, 1.051_f32, 10.648_f32, 1.051_f32, 9.301_f32, 2.398_f32)
      content_stream.line_to(3.301_f32, 8.398_f32)
      content_stream.curve_to(2.398_f32, 9.301_f32, 1.949_f32, 10.5_f32, 1.949_f32, 11.699_f32)
      content_stream.curve_to(1.949_f32, 14.324_f32, 4.051_f32, 16.352_f32, 6.676_f32, 16.352_f32)
      content_stream.curve_to(7.949_f32, 16.352_f32, 9.074_f32, 15.824_f32, 9.977_f32, 15.0_f32)
      content_stream.line_to(14.625_f32, 10.352_f32)
      content_stream.curve_to(14.926_f32, 10.051_f32, 14.926_f32, 9.602_f32, 14.625_f32, 9.301_f32)
      content_stream.curve_to(14.324_f32, 9.0_f32, 13.875_f32, 9.0_f32, 13.574_f32, 9.301_f32)
      content_stream.close_path
      content_stream.fill
    end

    private def draw_push_pin(content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream) : Nil
      content_stream.transform(Pdfbox::Util::Matrix.new(0.022_f32, 0.0_f32, 0.0_f32, -0.022_f32, 0.0_f32, 18.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.translate(586.47_f32, 178.97_f32))
      content_stream.move_to(0.0_f32, 0.0_f32)
      content_stream.curve_to(13.0_f32, 0.0_f32, 23.43_f32, -10.58_f32, 23.43_f32, -23.57_f32)
      content_stream.line_to(23.43_f32, -70.53_f32)
      content_stream.curve_to(23.43_f32, -109.32_f32, -8.19_f32, -141.06_f32, -47.03_f32, -141.06_f32)
      content_stream.line_to(-329.17_f32, -141.06_f32)
      content_stream.curve_to(-368.17_f32, -141.06_f32, -399.79_f32, -109.32_f32, -399.79_f32, -70.53_f32)
      content_stream.line_to(-399.79_f32, -23.57_f32)
      content_stream.curve_to(-399.79_f32, -10.58_f32, -389.19_f32, 0.0_f32, -376.19_f32, 0.0_f32)
      content_stream.line_to(-305.74_f32, 0.0_f32)
      content_stream.line_to(-305.74_f32, 129.52_f32)
      content_stream.curve_to(-364.0_f32, 168.47_f32, -399.79_f32, 234.67_f32, -399.79_f32, 305.36_f32)
      content_stream.curve_to(-399.79_f32, 318.34_f32, -389.19_f32, 328.76_f32, -376.19_f32, 328.76_f32)
      content_stream.line_to(-211.69_f32, 328.76_f32)
      content_stream.line_to(-211.69_f32, 555.9_f32)
      content_stream.curve_to(-211.69_f32, 568.88_f32, -201.1_f32, 579.3_f32, -188.1_f32, 579.3_f32)
      content_stream.curve_to(-175.1_f32, 579.3_f32, -164.67_f32, 568.88_f32, -164.67_f32, 555.9_f32)
      content_stream.line_to(-164.67_f32, 328.76_f32)
      content_stream.line_to(0.0_f32, 328.76_f32)
      content_stream.curve_to(13.0_f32, 328.76_f32, 23.43_f32, 318.34_f32, 23.43_f32, 305.36_f32)
      content_stream.curve_to(23.43_f32, 234.67_f32, -12.2_f32, 168.47_f32, -70.62_f32, 129.52_f32)
      content_stream.line_to(-70.62_f32, 0.0_f32)
      content_stream.line_to(0.0_f32, 0.0_f32)
      content_stream.close_path
      content_stream.move_to(-25.2_f32, 281.79_f32)
      content_stream.line_to(-351.0_f32, 281.79_f32)
      content_stream.curve_to(-343.77_f32, 232.42_f32, -314.24_f32, 188.18_f32, -270.43_f32, 162.86_f32)
      content_stream.curve_to(-263.21_f32, 158.69_f32, -258.71_f32, 150.99_f32, -258.71_f32, 142.5_f32)
      content_stream.line_to(-258.71_f32, 0.0_f32)
      content_stream.line_to(-117.64_f32, 0.0_f32)
      content_stream.line_to(-117.64_f32, 142.5_f32)
      content_stream.curve_to(-117.64_f32, 150.99_f32, -113.15_f32, 158.69_f32, -105.77_f32, 162.86_f32)
      content_stream.curve_to(-61.95_f32, 188.18_f32, -32.42_f32, 232.42_f32, -25.2_f32, 281.79_f32)
      content_stream.close_path
      content_stream.move_to(-352.76_f32, -46.97_f32)
      content_stream.line_to(-352.76_f32, -70.53_f32)
      content_stream.curve_to(-352.76_f32, -83.52_f32, -342.17_f32, -93.93_f32, -329.17_f32, -93.93_f32)
      content_stream.line_to(-47.03_f32, -93.93_f32)
      content_stream.curve_to(-34.03_f32, -93.93_f32, -23.59_f32, -83.52_f32, -23.59_f32, -70.53_f32)
      content_stream.line_to(-23.59_f32, -46.97_f32)
      content_stream.line_to(-352.76_f32, -46.97_f32)
      content_stream.line_to(-352.76_f32, -46.97_f32)
      content_stream.close_path
      content_stream.fill
    end

    private def draw_graph(content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream) : Nil
      content_stream.transform(Pdfbox::Util::Matrix.new(0.022_f32, 0.0_f32, 0.0_f32, -0.022_f32, 0.0_f32, 18.0_f32))
      content_stream.transform(Pdfbox::Util::Matrix.translate(736.04_f32, 907.89_f32))
      content_stream.move_to(0.0_f32, 0.0_f32)
      content_stream.line_to(-675.23_f32, 0.0_f32)
      content_stream.curve_to(-679.72_f32, 0.0_f32, -683.41_f32, -3.53_f32, -683.41_f32, -8.01_f32)
      content_stream.line_to(-683.41_f32, -683.37_f32)
      content_stream.line_to(-667.22_f32, -683.37_f32)
      content_stream.line_to(-667.22_f32, -353.95_f32)
      content_stream.curve_to(-583.85_f32, -357.8_f32, -541.53_f32, -419.99_f32, -500.49_f32, -480.27_f32)
      content_stream.curve_to(-459.93_f32, -539.74_f32, -418.09_f32, -601.46_f32, -337.61_f32, -601.46_f32)
      content_stream.curve_to(-257.14_f32, -601.46_f32, -215.3_f32, -539.74_f32, -174.74_f32, -480.27_f32)
      content_stream.curve_to(-132.58_f32, -418.07_f32, -88.81_f32, -353.79_f32, 0.0_f32, -353.79_f32)
      content_stream.line_to(0.0_f32, -337.6_f32)
      content_stream.curve_to(-97.31_f32, -337.6_f32, -143.48_f32, -405.41_f32, -188.2_f32, -471.13_f32)
      content_stream.curve_to(-228.12_f32, -529.8_f32, -265.8_f32, -585.27_f32, -337.61_f32, -585.27_f32)
      content_stream.curve_to(-409.43_f32, -585.27_f32, -447.11_f32, -529.8_f32, -487.03_f32, -471.13_f32)
      content_stream.curve_to(-530.47_f32, -407.33_f32, -575.36_f32, -341.45_f32, -667.22_f32, -337.76_f32)
      content_stream.line_to(-667.22_f32, -16.19_f32)
      content_stream.line_to(-615.76_f32, -16.19_f32)
      content_stream.line_to(-615.76_f32, -255.68_f32)
      content_stream.curve_to(-615.76_f32, -260.17_f32, -612.23_f32, -263.7_f32, -607.74_f32, -263.7_f32)
      content_stream.line_to(-525.82_f32, -263.7_f32)
      content_stream.line_to(-525.82_f32, -345.77_f32)
      content_stream.curve_to(-525.82_f32, -350.26_f32, -522.13_f32, -353.79_f32, -517.64_f32, -353.79_f32)
      content_stream.line_to(-435.73_f32, -353.79_f32)
      content_stream.line_to(-435.73_f32, -458.31_f32)
      content_stream.curve_to(-435.73_f32, -462.8_f32, -432.2_f32, -466.32_f32, -427.71_f32, -466.32_f32)
      content_stream.line_to(-337.61_f32, -466.32_f32)
      content_stream.curve_to(-333.13_f32, -466.32_f32, -329.6_f32, -462.8_f32, -329.6_f32, -458.31_f32)
      content_stream.line_to(-329.6_f32, -421.28_f32)
      content_stream.line_to(-247.68_f32, -421.28_f32)
      content_stream.curve_to(-243.19_f32, -421.28_f32, -239.5_f32, -417.75_f32, -239.5_f32, -413.26_f32)
      content_stream.line_to(-239.5_f32, -331.35_f32)
      content_stream.line_to(-157.58_f32, -331.35_f32)
      content_stream.curve_to(-153.1_f32, -331.35_f32, -149.41_f32, -327.66_f32, -149.41_f32, -323.17_f32)
      content_stream.line_to(-149.41_f32, -218.81_f32)
      content_stream.line_to(-67.49_f32, -218.81_f32)
      content_stream.curve_to(-63.0_f32, -218.81_f32, -59.47_f32, -215.13_f32, -59.47_f32, -210.64_f32)
      content_stream.line_to(-59.47_f32, -16.19_f32)
      content_stream.line_to(0.0_f32, -16.19_f32)
      content_stream.line_to(0.0_f32, 0.0_f32)
      content_stream.close_path
      content_stream.move_to(-149.41_f32, -16.19_f32)
      content_stream.line_to(-75.67_f32, -16.19_f32)
      content_stream.line_to(-75.67_f32, -202.62_f32)
      content_stream.line_to(-149.41_f32, -202.62_f32)
      content_stream.line_to(-149.41_f32, -16.19_f32)
      content_stream.close_path
      content_stream.move_to(-239.5_f32, -16.19_f32)
      content_stream.line_to(-165.76_f32, -16.19_f32)
      content_stream.line_to(-165.76_f32, -315.16_f32)
      content_stream.line_to(-239.5_f32, -315.16_f32)
      content_stream.line_to(-239.5_f32, -16.19_f32)
      content_stream.close_path
      content_stream.move_to(-329.6_f32, -16.19_f32)
      content_stream.line_to(-255.7_f32, -16.19_f32)
      content_stream.line_to(-255.7_f32, -405.09_f32)
      content_stream.line_to(-329.6_f32, -405.09_f32)
      content_stream.line_to(-329.6_f32, -16.19_f32)
      content_stream.close_path
      content_stream.move_to(-419.53_f32, -16.19_f32)
      content_stream.line_to(-345.79_f32, -16.19_f32)
      content_stream.line_to(-345.79_f32, -450.13_f32)
      content_stream.line_to(-419.53_f32, -450.13_f32)
      content_stream.line_to(-419.53_f32, -16.19_f32)
      content_stream.close_path
      content_stream.move_to(-509.63_f32, -16.19_f32)
      content_stream.line_to(-435.73_f32, -16.19_f32)
      content_stream.line_to(-435.73_f32, -337.6_f32)
      content_stream.line_to(-509.63_f32, -337.6_f32)
      content_stream.line_to(-509.63_f32, -16.19_f32)
      content_stream.close_path
      content_stream.move_to(-599.56_f32, -16.19_f32)
      content_stream.line_to(-525.82_f32, -16.19_f32)
      content_stream.line_to(-525.82_f32, -247.51_f32)
      content_stream.line_to(-599.56_f32, -247.51_f32)
      content_stream.line_to(-599.56_f32, -16.19_f32)
      content_stream.close_path
      content_stream.fill
    end

    private def draw_tag(content_stream : Pdfbox::Pdmodel::PDAppearanceContentStream) : Nil
      content_stream.transform(Pdfbox::Util::Matrix.new(0.022_f32, 0.0_f32, 0.0_f32, -0.022_f32, 0.0_f32, 18.0_f32))
      content_stream.save_graphics_state
      content_stream.transform(Pdfbox::Util::Matrix.translate(209.26_f32, 128.32_f32))
      content_stream.move_to(0.0_f32, 0.0_f32)
      content_stream.curve_to(-44.73_f32, 0.0_f32, -80.64_f32, 36.23_f32, -80.64_f32, 80.64_f32)
      content_stream.curve_to(-80.64_f32, 125.2_f32, -44.57_f32, 161.27_f32, 0.0_f32, 161.27_f32)
      content_stream.curve_to(44.56_f32, 161.27_f32, 80.47_f32, 125.04_f32, 80.47_f32, 80.64_f32)
      content_stream.curve_to(80.63_f32, 36.07_f32, 44.56_f32, 0.0_f32, 0.0_f32, 0.0_f32)
      content_stream.close_path
      content_stream.move_to(0.0_f32, 132.74_f32)
      content_stream.curve_to(-28.7_f32, 132.74_f32, -52.1_f32, 109.33_f32, -52.1_f32, 80.64_f32)
      content_stream.curve_to(-52.1_f32, 51.94_f32, -28.7_f32, 28.54_f32, 0.0_f32, 28.54_f32)
      content_stream.curve_to(28.69_f32, 28.54_f32, 51.93_f32, 51.94_f32, 51.93_f32, 80.64_f32)
      content_stream.curve_to(51.93_f32, 109.33_f32, 28.85_f32, 132.74_f32, 0.0_f32, 132.74_f32)
      content_stream.close_path
      content_stream.fill
      content_stream.restore_graphics_state
      content_stream.save_graphics_state
      content_stream.transform(Pdfbox::Util::Matrix.translate(382.22_f32, 79.91_f32))
      content_stream.move_to(0.0_f32, 0.0_f32)
      content_stream.curve_to(-14.58_f32, -16.19_f32, -35.1_f32, -24.85_f32, -57.22_f32, -24.85_f32)
      content_stream.line_to(-208.23_f32, -26.45_f32)
      content_stream.curve_to(-240.45_f32, -26.45_f32, -271.23_f32, -14.75_f32, -293.35_f32, 8.66_f32)
      content_stream.curve_to(-316.76_f32, 30.78_f32, -328.46_f32, 61.56_f32, -328.46_f32, 93.78_f32)
      content_stream.line_to(-327.02_f32, 244.95_f32)
      content_stream.curve_to(-325.57_f32, 265.47_f32, -318.2_f32, 285.98_f32, -302.17_f32, 302.18_f32)
      content_stream.line_to(58.68_f32, 663.02_f32)
      content_stream.line_to(360.85_f32, 360.69_f32)
      content_stream.line_to(0.0_f32, 0.0_f32)
      content_stream.line_to(0.0_f32, 0.0_f32)
      content_stream.close_path
      content_stream.move_to(57.23_f32, 621.82_f32)
      content_stream.line_to(-283.09_f32, 281.5_f32)
      content_stream.curve_to(-293.35_f32, 271.24_f32, -299.12_f32, 258.09_f32, -299.12_f32, 243.34_f32)
      content_stream.line_to(-300.57_f32, 93.78_f32)
      content_stream.curve_to(-300.57_f32, 70.38_f32, -290.31_f32, 46.81_f32, -274.12_f32, 29.34_f32)
      content_stream.curve_to(-256.64_f32, 11.7_f32, -233.08_f32, 1.44_f32, -208.23_f32, 1.44_f32)
      content_stream.line_to(-58.67_f32, 2.89_f32)
      content_stream.curve_to(-44.08_f32, 2.89_f32, -30.77_f32, 8.66_f32, -20.51_f32, 19.08_f32)
      content_stream.line_to(319.81_f32, 359.4_f32)
      content_stream.line_to(57.23_f32, 621.82_f32)
      content_stream.close_path
      content_stream.fill
      content_stream.restore_graphics_state
    end
  end
end
