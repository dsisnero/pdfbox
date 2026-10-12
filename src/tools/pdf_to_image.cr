require "../pdfbox"
require "./imageio"
require "option_parser"

module Tools
  class PDFToImage
    @password = ""
    @image_format = "jpg"
    @output_prefix : String? = nil
    @page = -1
    @start_page = 1
    @end_page = Int32::MAX
    @image_type = "RGB" # RGB, ARGB, GRAY, BINARY
    @dpi = 0
    @quality = -1.0_f32
    @cropbox : Array(Int32)? = nil
    @show_time = false
    @subsampling = false
    @infile : String? = nil

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      parser = build_option_parser
      parser.parse(extract_cropbox(normalize_args(args)))

      infile = @infile
      unless infile
        @err.puts("Missing required option: -i")
        return 1
      end

      process_document(infile)
    rescue ex : IO::Error
      @err.puts("Error converting PDF to image [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @password = ""
      @image_format = "jpg"
      @output_prefix = nil
      @page = -1
      @start_page = 1
      @end_page = Int32::MAX
      @image_type = "RGB"
      @dpi = 0
      @quality = -1.0_f32
      @cropbox = nil
      @show_time = false
      @subsampling = false
      @infile = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("--password PASSWORD", "The password to decrypt the document") do |value|
          @password = value
        end
        parser.on("--format FORMAT", "The image file format (default: jpg)") do |value|
          @image_format = value
        end
        parser.on("--prefix PREFIX", "--outputPrefix PREFIX", "The filename prefix for image files") do |value|
          @output_prefix = value
        end
        parser.on("--page PAGE", "The only page to extract (1-based)") do |value|
          @page = value.to_i
        end
        parser.on("--startPage PAGE", "The first page to start extraction (1-based)") do |value|
          @start_page = value.to_i
        end
        parser.on("--endPage PAGE", "The last page to extract (inclusive)") do |value|
          @end_page = value.to_i
        end
        parser.on("--color COLOR", "The color depth (RGB, ARGB, GRAY, BINARY) (default: RGB)") do |value|
          @image_type = value.upcase
        end
        parser.on("--dpi DPI", "--resolution DPI", "The DPI of the output image, default: screen resolution or 96 if unknown") do |value|
          @dpi = value.to_i
        end
        parser.on("--quality QUALITY", "The quality to be used when compressing the image (0 <= quality <= 1)") do |value|
          @quality = value.to_f32
        end
        parser.on("--cropbox", "The page area to export (X0 Y0 X1 Y1)") do
          # Consumed by extract_cropbox before parsing.
        end
        parser.on("--time", "Print timing information to stdout") do
          @show_time = true
        end
        parser.on("--subsampling", "Activate subsampling (for PDFs with huge images)") do
          @subsampling = true
        end
        parser.on("-i FILE", "--input FILE", "The PDF file to convert (required)") do |value|
          @infile = value
        end
        parser.on("-h", "--help", "Show this help") do
          @out.puts <<-HELP
          Usage: pdfbox pdftoimage [options]

          Converts a PDF document to image(s).

          Options:
            --password PASSWORD       The password to decrypt the document
            --format FORMAT           The image file format (default: jpg)
            --prefix PREFIX           The filename prefix for image files
            --page PAGE               The only page to extract (1-based)
            --startPage PAGE          The first page to start extraction (1-based)
            --endPage PAGE            The last page to extract (inclusive)
            --color COLOR             The color depth (RGB, ARGB, GRAY, BINARY) (default: RGB)
            --dpi DPI                 The DPI of the output image, default: screen resolution or 96 if unknown
            --quality QUALITY         The quality to be used when compressing the image (0 <= quality <= 1)
            --cropbox X0 Y0 X1 Y1     The page area to export
            --time                    Print timing information to stdout
            --subsampling             Activate subsampling (for PDFs with huge images)
            -i, --input FILE          The PDF file to convert (required)
            -h, --help                Show this help

          Examples:
            # Convert all pages to JPEG images
            pdfbox pdftoimage -i document.pdf

            # Convert only page 3 to PNG
            pdfbox pdftoimage -i document.pdf --page 3 --format png

            # Convert pages 1-5 with custom DPI
            pdfbox pdftoimage -i document.pdf --startPage 1 --endPage 5 --dpi 300
          HELP
          exit 0
        end
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      # Convert single-dash long options to double-dash for compatibility
      args.map do |arg|
        if arg.starts_with?('-') && !arg.starts_with?("--") && arg.size > 2 && !{"-i", "-h"}.includes?(arg)
          "--#{arg.byte_slice(1)}"
        else
          arg
        end
      end
    end

    # Java's `-cropbox` option has arity 4. Crystal's OptionParser cannot bind
    # four values to a single option, so consume the four integers here and
    # remove the option (and its values) before parsing.
    private def extract_cropbox(args : Array(String)) : Array(String)
      result = [] of String
      i = 0
      while i < args.size
        arg = args[i]
        if arg == "--cropbox"
          values = args[i + 1, 4]?
          unless values && values.size == 4
            raise ArgumentError.new("Invalid value for --cropbox: expected 4 integers")
          end
          @cropbox = values.map(&.to_i)
          i += 5
        else
          result << arg
          i += 1
        end
      end
      result
    end

    private def process_document(infile : String) : Int32
      unless File.exists?(infile)
        @err.puts("Input file not found: #{infile}")
        return 1
      end

      abs_input = File.expand_path(infile)
      output_prefix = @output_prefix || File.join(File.dirname(abs_input), File.basename(abs_input, File.extname(abs_input)))

      image_format = @image_format
      unless Tools::Imageio::ImageIOUtil.supported_format?(image_format)
        @err.puts("Error: Invalid image format #{image_format} - supported formats: " +
                  Tools::Imageio::ImageIOUtil::WRITER_FORMAT_NAMES.join(", "))
        return 2
      end

      quality = @quality
      quality = Tools::Imageio::ImageIOUtil.default_compression_quality(image_format) if quality < 0

      dpi = @dpi
      dpi = 96 if dpi == 0

      document = Pdfbox::Loader.load_pdf(infile, @password)

      if cropbox = @cropbox
        change_crop_box(document, cropbox[0], cropbox[1], cropbox[2], cropbox[3])
      end

      start_time = Time.instant

      start_page = @page != -1 ? @page : @start_page
      end_page = @page != -1 ? @page : @end_page
      end_page = Math.min(end_page, document.number_of_pages)

      renderer = Pdfbox::Rendering::PDFRenderer.new(document)
      renderer.subsampling_allowed = @subsampling

      success = true
      i = start_page - 1
      while i < end_page
        image = renderer.render_image_with_dpi(i, dpi)
        image = convert_color(image, @image_type)
        filename = "#{output_prefix}-#{i + 1}.#{image_format}"
        success = Tools::Imageio::ImageIOUtil.write_image(image, filename, dpi, quality) && success
        i += 1
      end

      duration = Time.instant - start_time
      count = 1 + end_page - start_page
      if @show_time
        @err.puts("Rendered #{count} page#{count == 1 ? "" : "s"} in #{duration.total_milliseconds.round.to_i}ms")
      end

      unless success
        @err.puts("Error: no writer found for image format '#{image_format}'")
        return 1
      end

      0
    end

    # Port of PDFToImage#changeCropBox: set the same crop box on every page.
    private def change_crop_box(document : Pdfbox::Pdmodel::Document, a : Int32, b : Int32, c : Int32, d : Int32) : Nil
      document.get_pages.each do |page|
        page.crop_box = Pdfbox::Pdmodel::Rectangle.new(a.to_f64, b.to_f64, c.to_f64, d.to_f64)
      end
    end

    # Maps the requested color depth to a CrImage raster. RGB and ARGB keep the
    # rendered RGBA raster; GRAY and BINARY produce an 8-bit grayscale raster.
    private def convert_color(image : CrImage::RGBA, color_type : String) : CrImage::Image
      return image unless color_type == "GRAY" || color_type == "BINARY"

      bounds = image.bounds
      gray = CrImage.gray(bounds.width, bounds.height)
      binary = color_type == "BINARY"
      image.each_pixel do |x, y, color|
        value = color.to_rgba8.luminance
        value = value >= 128 ? 255_u8 : 0_u8 if binary
        gray.set_gray(x, y, CrImage::Color::Gray.new(value))
      end
      gray
    end
  end
end
