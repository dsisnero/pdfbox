# PDF page renderer that renders pages to raster images using CrImage.
# Port of Apache PDFBox PDFRenderer.
require "crimage"
require "../contentstream/pdf_stream_engine"
require "../contentstream/pdf_graphics_stream_engine"

module Pdfbox::Rendering
  class PDFRenderer
    getter document : Pdfbox::Pdmodel::Document
    property subsampling_allowed : Bool = false

    def initialize(@document : Pdfbox::Pdmodel::Document)
    end

    def render_image(page_index : Int32) : CrImage::RGBA
      render_image_with_dpi(page_index, 72)
    end

    def render_image_with_dpi(page_index : Int32, dpi : Number) : CrImage::RGBA
      scale = dpi.to_f / 72.0
      page = @document.get_page(page_index)
      raise "Page #{page_index} not found" unless page

      media = page.media_box || Pdfbox::Pdmodel::PageSizes::LETTER
      width = (media.width * scale).round.to_i32
      height = (media.height * scale).round.to_i32

      drawer = PageDrawer.new(page, width, height, scale)
      drawer.render
    end

    def render_image_png(page_index : Int32, dpi : Number = 72) : Bytes
      img = render_image_with_dpi(page_index, dpi)
      io = ::IO::Memory.new
      CrImage::PNG::Writer.write_to(io, img)
      io.to_slice
    end
  end

  # Page rendering engine that draws content stream operations to a raster image.
  class PageDrawer < Pdfbox::Contentstream::PDFGraphicsStreamEngine
    getter width : Int32
    getter height : Int32
    getter image : CrImage::RGBA?

    @scale : Float64
    @path : Array(PathSegment) = [] of PathSegment
    @pt : Tuple(Float32, Float32)? = nil

    private record PathSegment, kind : Symbol, x1 : Float64 = 0.0, y1 : Float64 = 0.0,
      x2 : Float64 = 0.0, y2 : Float64 = 0.0, x3 : Float64 = 0.0, y3 : Float64 = 0.0

    def initialize(page : Pdfbox::Pdmodel::Page, @width : Int32, @height : Int32,
                   @scale : Float64 = 1.0)
      super(page)
      @image = nil
    end

    def render : CrImage::RGBA
      @image = CrImage.rgba(@width, @height)
      process_page(@page.not_nil!)
      @image.not_nil!
    end

    private def tx(x : Float32) : Float64
      (x.to_f64 * @scale).round.to_f64
    end

    private def ty(y : Float32) : Float64
      (@height - 1 - (y.to_f64 * @scale).round).to_f64
    end

    # --- Path building ---

    def move_to(x : Float32, y : Float32) : Nil
      @path << PathSegment.new(kind: :move, x1: tx(x), y1: ty(y))
      @pt = {x, y}
    end

    def line_to(x : Float32, y : Float32) : Nil
      @path << PathSegment.new(kind: :line, x1: tx(x), y1: ty(y))
      @pt = {x, y}
    end

    def curve_to(x1 : Float32, y1 : Float32, x2 : Float32, y2 : Float32,
                 x3 : Float32, y3 : Float32) : Nil
      @path << PathSegment.new(kind: :curve, x1: tx(x1), y1: ty(y1),
        x2: tx(x2), y2: ty(y2), x3: tx(x3), y3: ty(y3))
      @pt = {x3, y3}
    end

    def current_point : Tuple(Float32, Float32)?
      @pt
    end

    def close_path : Nil
      @path << PathSegment.new(kind: :close)
    end

    def end_path : Nil
      @path.clear
      @pt = nil
    end

    def append_rectangle(p0 : Tuple(Float32, Float32), p1 : Tuple(Float32, Float32),
                         p2 : Tuple(Float32, Float32), p3 : Tuple(Float32, Float32)) : Nil
      move_to(p0[0], p0[1])
      line_to(p1[0], p1[1])
      line_to(p2[0], p2[1])
      line_to(p3[0], p3[1])
      close_path
    end

    # --- Drawing ---

    def stroke_path : Nil
      draw_lines(stroke_color)
      @path.clear
      @pt = nil
    end

    def fill_path(winding_rule : Int32) : Nil
      draw_filled(fill_color)
      @path.clear
      @pt = nil
    end

    def fill_and_stroke_path(winding_rule : Int32) : Nil
      draw_filled(fill_color)
      draw_lines(stroke_color)
      @path.clear
      @pt = nil
    end

    def clip(winding_rule : Int32) : Nil
    end

    def shading_fill(shading_name : String) : Nil
    end

    # --- Image ---

    def draw_image(pd_image : Pdfbox::Pdmodel::Graphics::Image::PDImage) : Nil
      img = @image
      return unless img
      return if pd_image.stencil?
      begin
        io = pd_image.create_input_stream
        data = io.getb_to_end
        return if data.empty? || pd_image.width == 0 || pd_image.height == 0

        ctm = graphics_state.current_transformation_matrix
        ox = ctm.translate_x.to_i32
        oy = ctm.translate_y.to_i32
        w = pd_image.width
        h = pd_image.height
        bpp = data.size // (w * h) > 0 ? data.size // (w * h) : 3

        h.times do |row|
          w.times do |col|
            si = (row * w + col) * bpp
            break if si + 2 >= data.size
            px = ox + col
            py = oy + h - 1 - row
            if px >= 0 && px < @width && py >= 0 && py < @height
              c = CrImage::Color::RGBA.new(
                bpp >= 3 ? data[si] : data[si],
                bpp >= 3 ? data[si + 1] : data[si],
                bpp >= 3 ? data[si + 2] : data[si],
                255_u8
              )
              img[px, py] = c
            end
          end
        end
      rescue ex
      end
    end

    # --- Text rendering ---

    def begin_text : Nil
    end

    def end_text : Nil
    end

    def show_font_glyph(text_rendering_matrix : Pdfbox::Util::Matrix,
                        font : Pdfbox::Pdmodel::Font::PDFont,
                        code : Int32,
                        displacement : Tuple(Float32, Float32)) : Nil
      return unless @image

      glyph_name = font.encoding.try(&.name(code)) || font.glyph_name(code) || ""
      path = font.path(glyph_name)
      return if path.empty?

      gs = graphics_state
      font_size = gs.text_state.font_size
      scale = font_size / 1000.0
      trm_x = text_rendering_matrix.translate_x
      trm_y = text_rendering_matrix.translate_y

      path.each_command do |cmd_sym, args|
        case cmd_sym
        when :move_to
          move_to((args[0] * scale + trm_x).to_f32, (args[1] * scale + trm_y).to_f32)
        when :line_to
          line_to((args[0] * scale + trm_x).to_f32, (args[1] * scale + trm_y).to_f32)
        when :curve_to
          curve_to((args[0] * scale + trm_x).to_f32, (args[1] * scale + trm_y).to_f32,
            (args[2] * scale + trm_x).to_f32, (args[3] * scale + trm_y).to_f32,
            (args[4] * scale + trm_x).to_f32, (args[5] * scale + trm_y).to_f32)
        when :close_path
          close_path
        end
      end

      rm = gs.text_state.rendering_mode
      if rm.fill?
        fill_path(0)
      elsif rm.stroke?
        stroke_path
      elsif rm.fill_stroke?
        fill_and_stroke_path(0)
      else
        @path.clear
        @pt = nil
      end
    end

    def show_type3_glyph(text_rendering_matrix : Pdfbox::Util::Matrix,
                         font : Pdfbox::Pdmodel::Font::PDType3Font,
                         code : Int32,
                         displacement : Tuple(Float32, Float32)) : Nil
    end

    # --- Private drawing helpers ---

    private def stroke_color : CrImage::Color::Color?
      pd_to_color(graphics_state.stroking_color)
    end

    private def fill_color : CrImage::Color::Color?
      pd_to_color(graphics_state.non_stroking_color)
    end

    private def pd_to_color(c : Pdfbox::Pdmodel::Graphics::Color::PDColor) : CrImage::Color::Color?
      comps = c.components
      case c.color_space
      when Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray
        g = (comps[0] * 255).clamp(0, 255).to_u8
        CrImage::Color::RGBA.new(g, g, g, 255_u8).as(CrImage::Color::Color)
      when Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB
        r = (comps[0] * 255).clamp(0, 255).to_u8
        g = (comps[1] * 255).clamp(0, 255).to_u8
        b = (comps[2] * 255).clamp(0, 255).to_u8
        CrImage::Color::RGBA.new(r, g, b, 255_u8).as(CrImage::Color::Color)
      when Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK
        fc = comps[0]; fm = comps[1]; fy = comps[2]; fk = comps[3]
        r = ((1.0 - fc) * (1.0 - fk) * 255).clamp(0, 255).to_u8
        g = ((1.0 - fm) * (1.0 - fk) * 255).clamp(0, 255).to_u8
        b = ((1.0 - fy) * (1.0 - fk) * 255).clamp(0, 255).to_u8
        CrImage::Color::RGBA.new(r, g, b, 255_u8).as(CrImage::Color::Color)
      else
        nil
      end
    end

    private def draw_lines(color : CrImage::Color::Color?) : Nil
      return unless c = color
      return unless img = @image
      segments = collect_segments
      segments.each do |seg|
        bresenham(img, seg[0], seg[1], seg[2], seg[3], c)
      end
    end

    private def draw_filled(color : CrImage::Color::Color?) : Nil
      draw_lines(color) # simplified: fill using line drawing
    end

    private def collect_segments : Array(Tuple(Int32, Int32, Int32, Int32))
      result = [] of Tuple(Int32, Int32, Int32, Int32)
      fx = 0.0; fy = 0.0; px = 0.0; py = 0.0; started = false
      @path.each do |seg|
        case seg.kind
        when :move
          fx = seg.x1; fy = seg.y1; px = seg.x1; py = seg.y1; started = true
        when :line
          if started
            result << {px.to_i32, py.to_i32, seg.x1.to_i32, seg.y1.to_i32}
            px = seg.x1; py = seg.y1
          end
        when :curve
          if started
            bezier_segments(px, py, seg.x1, seg.y1, seg.x2, seg.y2, seg.x3, seg.y3).each do |bx1, by1, bx2, by2|
              result << {bx1.to_i32, by1.to_i32, bx2.to_i32, by2.to_i32}
            end
            px = seg.x3; py = seg.y3
          end
        when :close
          if started
            result << {px.to_i32, py.to_i32, fx.to_i32, fy.to_i32}
            px = fx; py = fy
          end
        end
      end
      result
    end

    private def bezier_segments(x0 : Float64, y0 : Float64, x1 : Float64, y1 : Float64,
                                x2 : Float64, y2 : Float64, x3 : Float64, y3 : Float64,
                                steps : Int32 = 8) : Array(Tuple(Float64, Float64, Float64, Float64))
      result = [] of Tuple(Float64, Float64, Float64, Float64)
      px, py = x0, y0
      (1..steps).each do |i|
        t = i.to_f64 / steps
        u = 1.0 - t
        bx = u*u*u*x0 + 3*u*u*t*x1 + 3*u*t*t*x2 + t*t*t*x3
        by = u*u*u*y0 + 3*u*u*t*y1 + 3*u*t*t*y2 + t*t*t*y3
        result << {px, py, bx, by}
        px, py = bx, by
      end
      result
    end

    private def bresenham(img : CrImage::RGBA, x1 : Int32, y1 : Int32,
                          x2 : Int32, y2 : Int32, c : CrImage::Color::Color) : Nil
      dx = (x2 - x1).abs; dy = -(y2 - y1).abs
      sx = x1 < x2 ? 1 : -1; sy = y1 < y2 ? 1 : -1
      err = dx + dy
      cx, cy = x1, y1
      loop do
        img[cx, cy] = c if cx >= 0 && cx < @width && cy >= 0 && cy < @height
        break if cx == x2 && cy == y2
        e2 = 2 * err
        if e2 >= dy
          err += dy; cx += sx
        end
        if e2 <= dx
          err += dx; cy += sy
        end
      end
    end
  end
end
