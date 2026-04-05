require "../pdfbox"
require "crimage"
require "option_parser"

module Tools
  class ExtractImages
    FILTER_SUFFIX = {
      "DCTDecode"      => "jpg",
      "DCT"            => "jpg",
      "JPXDecode"      => "jp2",
      "CCITTFaxDecode" => "tiff",
    } of String => String

    @password = ""
    @prefix : String? = nil
    @use_direct_jpeg = false
    @no_color_convert = false
    @infile : String? = nil

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      parser = build_option_parser
      parser.parse(normalize_args(args))

      infile = @infile
      unless infile
        @err.puts("Missing required option: -i")
        return 1
      end

      process_document(infile)
    rescue ex : IO::Error
      @err.puts("Error extracting images [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @password = ""
      @prefix = nil
      @use_direct_jpeg = false
      @no_color_convert = false
      @infile = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("--password PASSWORD", "The password for the PDF or certificate in keystore") { |value| @password = value }
        parser.on("--prefix PREFIX", "The image prefix (default to pdf name)") { |value| @prefix = value }
        parser.on("--useDirectJPEG", "Forces direct extraction of JPEG/JPX images") { @use_direct_jpeg = true }
        parser.on("--noColorConvert", "Extract images with original colorspace") { @no_color_convert = true }
        parser.on("-i FILE", "--input FILE", "The PDF file (required)") { |value| @infile = value }
        parser.on("-h", "--help", "Show this help") do
          @out.puts <<-HELP
          Usage: pdfbox extractimages [options]

          Extracts the images from a PDF document.

          Options:
            -password PASSWORD        The password for the PDF
            -prefix PREFIX            The image prefix (default to pdf name)
            -useDirectJPEG            Direct extraction of JPEG/JPX images
            -noColorConvert           Original colorspace if possible
            -i, --input FILE          The PDF file (required)
            -h, --help                Show this help
          HELP
          exit 0
        end
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      args.map do |arg|
        if arg.starts_with?('-') && !arg.starts_with?("--") && arg.size > 2 && !{"-i", "-h"}.includes?(arg)
          "--#{arg.byte_slice(1)}"
        else
          arg
        end
      end
    end

    private def process_document(infile : String) : Int32
      unless File.exists?(infile)
        @err.puts("Input file not found: #{infile}")
        return 1
      end

      prefix = @prefix
      unless prefix
        base = File.basename(infile, File.extname(infile))
        dir = File.dirname(infile)
        prefix = File.join(dir, base)
      end

      begin
        document = Pdfbox::Loader.load_pdf(infile, @password)
        seen = Set(Pdfbox::Cos::Stream).new
        image_counter = 0

        document.pages.each do |page|
          extractor = ImageGraphicsEngine.new(
            page, prefix, @use_direct_jpeg, @no_color_convert,
            seen, ->(count : Int32) { image_counter = count },
            -> { image_counter },
            @out, @err
          )
          extractor.run
        end

        if image_counter == 0
          @out.puts("No images found in the document.")
        else
          @out.puts("Extracted #{image_counter} image(s).")
        end

        document.close
        0
      rescue ex : Pdfbox::Error
        if ex.message.try(&.includes?("password"))
          @err.puts("Error: Invalid password for encrypted PDF")
          3
        else
          raise ex
        end
      end
    end

    # Source of truth: vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/ExtractImages.java
    # Inner class ImageGraphicsEngine extends PDFGraphicsStreamEngine
    class ImageGraphicsEngine < Pdfbox::Contentstream::PDFGraphicsStreamEngine
      @seen : Set(Pdfbox::Cos::Stream)
      @prefix : String
      @use_direct_jpeg : Bool
      @no_color_convert : Bool
      @image_counter : Int32 = 0
      @on_counter : Proc(Int32, Nil)
      @get_counter : Proc(Int32)
      @out : IO
      @err : IO

      def initialize(
        page : Pdfbox::Pdmodel::Page,
        @prefix : String,
        @use_direct_jpeg : Bool,
        @no_color_convert : Bool,
        @seen : Set(Pdfbox::Cos::Stream),
        @on_counter : Proc(Int32, Nil),
        @get_counter : Proc(Int32),
        @out : IO,
        @err : IO,
      )
        super(page)
        @image_counter = @get_counter.call
      end

      # Java: run() - processes page content stream and soft masks
      def run : Nil
        pg = page
        return unless pg
        process_page(pg)

        # Process soft masks in extended graphics states
        # Source of truth: ExtractImages.java:run lines 172-193
        resources = pg.resources
        return unless resources

        # Iterate ext gstate names to find soft masks
        cos_dict = resources.cos_object
        ext_gstate_dict = cos_dict[Pdfbox::Cos::Name.new("ExtGState")]?
        return unless ext_gstate_dict
        ext_gstate_dict = ext_gstate_dict.as(Pdfbox::Cos::Object).object if ext_gstate_dict.is_a?(Pdfbox::Cos::Object)
        return unless ext_gstate_dict.is_a?(Pdfbox::Cos::Dictionary)

        ext_gstate_dict.entries.each do |_name, value|
          next unless value
          value = value.as(Pdfbox::Cos::Object).object if value.is_a?(Pdfbox::Cos::Object)
          next unless value.is_a?(Pdfbox::Cos::Dictionary)

          # Check for SMask -> G (transparency group)
          smask = value[Pdfbox::Cos::Name.new("SMask")]?
          next unless smask
          smask = smask.as(Pdfbox::Cos::Object).object if smask.is_a?(Pdfbox::Cos::Object)
          next unless smask.is_a?(Pdfbox::Cos::Dictionary)

          group = smask[Pdfbox::Cos::Name.new("G")]?
          next unless group
          group = group.as(Pdfbox::Cos::Object).object if group.is_a?(Pdfbox::Cos::Object)
          next unless group.is_a?(Pdfbox::Cos::Dictionary)

          # Process the transparency group content stream
          if group.is_a?(Pdfbox::Cos::Stream)
            process_transparency_group(group)
          end
        end
      end

      # Source of truth: ExtractImages.java:drawImage
      def draw_image(pd_image : Pdfbox::Pdmodel::Graphics::Image::PDImage) : Nil
        # Java: if pdImage instanceof PDImageXObject, check seen and stencil
        if pd_image.is_a?(Pdfbox::Pdmodel::Graphics::Image::PDImageXObject)
          ximg = pd_image.as(Pdfbox::Pdmodel::Graphics::Image::PDImageXObject)
          cos_stream = ximg.cos_object

          if cos_stream.is_a?(Pdfbox::Cos::Stream)
            if @seen.includes?(cos_stream)
              return
            end
            @seen.add(cos_stream)
          end

          if pd_image.stencil?
            # Java: processColor(getGraphicsState().getNonStrokingColor())
            # Process tiling patterns in non-stroking color
            process_color(graphics_state.non_stroking_color)
          end
        end

        # Save image - Java: name = prefix + "-" + imageCounter
        name = "#{@prefix}-#{@image_counter}"
        @image_counter += 1
        @on_counter.call(@image_counter)

        write2file(pd_image, name)
      end

      # Source of truth: ExtractImages.java:write2file
      private def write2file(pd_image : Pdfbox::Pdmodel::Graphics::Image::PDImage, prefix : String) : Nil
        suffix = pd_image.suffix || "png"
        if suffix == "jb2"
          suffix = "png"
        elsif suffix == "jpx"
          suffix = "jp2"
        end

        if pd_image.is_a?(Pdfbox::Pdmodel::Graphics::Image::PDImageXObject)
          ximg = pd_image.as(Pdfbox::Pdmodel::Graphics::Image::PDImageXObject)
          if has_masks?(ximg)
            suffix = "png"
          end
        end

        filename = "#{prefix}.#{suffix}"
        @out.puts("Writing image: #{filename}") if @out.tty?

        begin
          case suffix
          when "jpg"
            # Java: pdImage.createInputStream(JPEG) -> data.transferTo(imageOutput)
            # For RGB/Gray: write raw stream; for CMYK: convert via getImage()
            raw_stream = pd_image.create_input_stream([] of String)
            File.write(filename, raw_stream.getb_to_end)
          when "jp2"
            raw_stream = pd_image.create_input_stream(["JPXDecode"])
            File.write(filename, raw_stream.getb_to_end)
          else
            # Java: BufferedImage image = pdImage.getImage()
            # ImageIOUtil.writeImage(image, suffix, imageOutput)
            write_png_image(pd_image, filename)
          end
        rescue ex : Exception
          @err.puts("Error writing #{filename}: #{ex.message}")
        end
      end

      private def has_masks?(ximg : Pdfbox::Pdmodel::Graphics::Image::PDImageXObject) : Bool
        cos_dict = ximg.cos_object
        return false unless cos_dict.is_a?(Pdfbox::Cos::Dictionary)
        !!(cos_dict[Pdfbox::Cos::Name.new("Mask")]? || cos_dict[Pdfbox::Cos::Name.new("SMask")]?)
      end

      private def write_png_image(pd_image : Pdfbox::Pdmodel::Graphics::Image::PDImage, filename : String) : Nil
        width = pd_image.width
        height = pd_image.height
        return if width == 0 || height == 0

        # Get decoded pixel data
        decoded_io = pd_image.create_input_stream
        pixel_data = decoded_io.getb_to_end

        # PDF raw pixel data: top-to-bottom, left-to-right
        # CrImage RGBA expects R,G,B,A per pixel
        bytes_per_pixel = pixel_data.size // (width * height)

        rgba_buffer = Bytes.new(width * height * 4)
        idx = 0
        height.times do |y|
          width.times do |x|
            src_offset = (y * width + x) * bytes_per_pixel
            if bytes_per_pixel >= 3 && src_offset + 2 < pixel_data.size
              rgba_buffer[idx] = pixel_data[src_offset]         # R
              rgba_buffer[idx + 1] = pixel_data[src_offset + 1] # G
              rgba_buffer[idx + 2] = pixel_data[src_offset + 2] # B
              rgba_buffer[idx + 3] = if bytes_per_pixel >= 4 && src_offset + 3 < pixel_data.size
                                       pixel_data[src_offset + 3] # A
                                     else
                                       255_u8
                                     end
            else
              gray = pixel_data.size > src_offset ? pixel_data[src_offset] : 0_u8
              rgba_buffer[idx] = gray
              rgba_buffer[idx + 1] = gray
              rgba_buffer[idx + 2] = gray
              rgba_buffer[idx + 3] = 255_u8
            end
            idx += 4
          end
        end

        img = CrImage::RGBA.from_buffer(rgba_buffer, width, height)
        CrImage::PNG::Writer.write(filename, img)
      end

      # Process tiling patterns for color (stencil images)
      private def process_color(color : Pdfbox::Pdmodel::Graphics::Color::PDColor) : Nil
        # Java: if color.getColorSpace() instanceof PDPattern, process tiling pattern
        colorspace = color.color_space
        if colorspace.is_a?(Pdfbox::Pdmodel::Graphics::Color::PDPattern)
          # Pattern handling - complex, skip for now
        end
      end

      private def process_transparency_group(stream : Pdfbox::Cos::Stream) : Nil
        # Parse the transparency group's content stream for images
        stream_data = stream.create_input_stream.getb_to_end
        parser = Pdfbox::Pdfparser::PDFStreamParser.new(stream_data)
        tokens = parser.parse
        # Walk tokens for Do operators
        i = 0
        while i < tokens.size
          token = tokens[i]
          if token.is_a?(Pdfbox::ContentStream::Operator) && token.name == Pdfbox::ContentStream::OperatorName::DRAW_OBJECT
            if i > 0
              name_token = tokens[i - 1]
              if name_token.is_a?(Pdfbox::Cos::Name)
                # Look up in stream resources
                resources_dict = stream[Pdfbox::Cos::Name.new("Resources")]?
                if resources_dict
                  resources_dict = resources_dict.as(Pdfbox::Cos::Object).object if resources_dict.is_a?(Pdfbox::Cos::Object)
                  if resources_dict.is_a?(Pdfbox::Cos::Dictionary)
                    xobjects_dict = resources_dict[Pdfbox::Cos::Name.new("XObject")]?
                    if xobjects_dict
                      xobjects_dict = xobjects_dict.as(Pdfbox::Cos::Object).object if xobjects_dict.is_a?(Pdfbox::Cos::Object)
                      if xobjects_dict.is_a?(Pdfbox::Cos::Dictionary)
                        xobject = xobjects_dict[name_token]?
                        if xobject
                          xobject = xobject.as(Pdfbox::Cos::Object).object if xobject.is_a?(Pdfbox::Cos::Object)
                          if xobject.is_a?(Pdfbox::Cos::Stream)
                            subtype = xobject[Pdfbox::Cos::Name.new("Subtype")]?
                            if subtype.is_a?(Pdfbox::Cos::Name) && subtype.value == "Image"
                              if !@seen.includes?(xobject)
                                @seen.add(xobject)
                                name = "#{@prefix}-#{@image_counter}"
                                @image_counter += 1
                                @on_counter.call(@image_counter)
                                # Write image from stream
                                suffix = stream_suffix(xobject)
                                filename = "#{name}.#{suffix}"
                                @out.puts("Writing image: #{filename}") if @out.tty?
                                begin
                                  case suffix
                                  when "jpg"
                                    File.write(filename, String.new(xobject.data))
                                  else
                                    decoded_io = xobject.create_input_stream
                                    pixel_data = decoded_io.getb_to_end
                                    width = xobject[Pdfbox::Cos::Name.new("Width")]?.try(&.as(Pdfbox::Cos::Integer).to_i) || 0
                                    height = xobject[Pdfbox::Cos::Name.new("Height")]?.try(&.as(Pdfbox::Cos::Integer).to_i) || 0
                                    if width > 0 && height > 0
                                      bytes_per_pixel = pixel_data.size // (width * height)
                                      rgba_buffer = Bytes.new(width * height * 4)
                                      idx = 0
                                      height.times do |row|
                                        width.times do |col|
                                          src_offset = (row * width + col) * bytes_per_pixel
                                          if bytes_per_pixel >= 3 && src_offset + 2 < pixel_data.size
                                            rgba_buffer[idx] = pixel_data[src_offset]
                                            rgba_buffer[idx + 1] = pixel_data[src_offset + 1]
                                            rgba_buffer[idx + 2] = pixel_data[src_offset + 2]
                                            rgba_buffer[idx + 3] = bytes_per_pixel >= 4 && src_offset + 3 < pixel_data.size ? pixel_data[src_offset + 3] : 255_u8
                                          else
                                            gray = pixel_data.size > src_offset ? pixel_data[src_offset] : 0_u8
                                            rgba_buffer[idx] = gray
                                            rgba_buffer[idx + 1] = gray
                                            rgba_buffer[idx + 2] = gray
                                            rgba_buffer[idx + 3] = 255_u8
                                          end
                                          idx += 4
                                        end
                                      end
                                      img = CrImage::RGBA.from_buffer(rgba_buffer, width, height)
                                      CrImage::PNG::Writer.write(filename, img)
                                    end
                                  end
                                rescue ex : Exception
                                  @err.puts("Error writing #{filename}: #{ex.message}")
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
          i += 1
        end
      rescue
        # Skip streams that can't be parsed
      end

      private def stream_suffix(stream : Pdfbox::Cos::Stream) : String
        filter = stream[Pdfbox::Cos::Name.new("Filter")]?
        return "png" unless filter

        filter_name = extract_filter_name(filter)
        FILTER_SUFFIX.fetch(filter_name || "", "png")
      end

      private def extract_filter_name(filter : Pdfbox::Cos::Base) : String?
        if filter.is_a?(Pdfbox::Cos::Name)
          filter.value
        elsif filter.is_a?(Pdfbox::Cos::Array) && filter.size > 0
          first = filter[0]
          first = first.as(Pdfbox::Cos::Object).object if first.is_a?(Pdfbox::Cos::Object)
          first.is_a?(Pdfbox::Cos::Name) ? first.value : nil
        end
      end

      # --- Abstract method stubs (required by PDFGraphicsStreamEngine) ---

      def append_rectangle(p0 : Tuple(Float32, Float32),
                           p1 : Tuple(Float32, Float32),
                           p2 : Tuple(Float32, Float32),
                           p3 : Tuple(Float32, Float32)) : Nil
        _ = p0
        _ = p1
        _ = p2
        _ = p3
      end

      def clip(winding_rule : Int32) : Nil
        _ = winding_rule
      end

      def move_to(x : Float32, y : Float32) : Nil
        _ = x
        _ = y
      end

      def line_to(x : Float32, y : Float32) : Nil
        _ = x
        _ = y
      end

      def curve_to(x1 : Float32, y1 : Float32,
                   x2 : Float32, y2 : Float32,
                   x3 : Float32, y3 : Float32) : Nil
        _ = x1
        _ = y1
        _ = x2
        _ = y2
        _ = x3
        _ = y3
      end

      def current_point : Tuple(Float32, Float32)?
        {0.0_f32, 0.0_f32}
      end

      def close_path : Nil
      end

      def end_path : Nil
      end

      def stroke_path : Nil
        # Java: processColor(getGraphicsState().getStrokingColor())
        process_color(graphics_state.stroking_color)
      end

      def fill_path(winding_rule : Int32) : Nil
        _ = winding_rule
        # Java: processColor(getGraphicsState().getNonStrokingColor())
        process_color(graphics_state.non_stroking_color)
      end

      def fill_and_stroke_path(winding_rule : Int32) : Nil
        _ = winding_rule
        process_color(graphics_state.non_stroking_color)
      end

      def shading_fill(shading_name : String) : Nil
        _ = shading_name
      end

      def begin_text : Nil
      end

      def end_text : Nil
      end

      # Java: showGlyph - processes colors for fill/stroke rendering modes
      def show_font_glyph(text_rendering_matrix : Pdfbox::Util::Matrix,
                          font : Pdfbox::Pdmodel::Font::PDFont,
                          code : Int32,
                          displacement : Tuple(Float32, Float32)) : Nil
        _ = text_rendering_matrix
        _ = font
        _ = code
        _ = displacement
        rendering_mode = graphics_state.text_state.rendering_mode
        if rendering_mode.fill?
          process_color(graphics_state.non_stroking_color)
        end
        if rendering_mode.stroke?
          process_color(graphics_state.stroking_color)
        end
      end

      def show_type3_glyph(text_rendering_matrix : Pdfbox::Util::Matrix,
                           font : Pdfbox::Pdmodel::Font::PDType3Font,
                           code : Int32,
                           displacement : Tuple(Float32, Float32)) : Nil
        _ = text_rendering_matrix
        _ = font
        _ = code
        _ = displacement
      end
    end
  end
end
