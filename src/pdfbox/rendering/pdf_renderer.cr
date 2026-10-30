# PDF page renderer that renders pages to raster images using CrImage.
# Port of Apache PDFBox PDFRenderer.
require "crimage"
require "../contentstream/pdf_stream_engine"
require "../contentstream/pdf_graphics_stream_engine"

module Pdfbox::Rendering
  class PDFRenderer
    getter document : Pdfbox::Pdmodel::Document
    property? subsampling_allowed : Bool = false

    @default_destination : RenderDestination? = nil
    @image_downscaling_optimization_threshold = 0.5_f32

    def initialize(@document : Pdfbox::Pdmodel::Document)
    end

    # The default render destination, nil until set (Java getDefaultDestination,
    # which defaults to null; the effective default is chosen per render call).
    def default_destination : RenderDestination?
      @default_destination
    end

    def default_destination=(value : RenderDestination?) : RenderDestination?
      @default_destination = value
    end

    # The image downscaling optimization threshold (Java
    # getImageDownscalingOptimizationThreshold, default 0.5).
    def image_downscaling_optimization_threshold : Float32
      @image_downscaling_optimization_threshold
    end

    def image_downscaling_optimization_threshold=(value : Float32) : Float32
      @image_downscaling_optimization_threshold = value
    end

    def render_image(page_index : Int32) : CrImage::RGBA
      render_image_with_dpi(page_index, 72)
    end

    def render_image_with_dpi(page_index : Int32, dpi : Number) : CrImage::RGBA
      scale = dpi.to_f / 72.0
      page = @document.get_page(page_index)
      raise "Page #{page_index} not found" unless page

      box = page.crop_box || page.media_box || Pdfbox::Pdmodel::PageSizes::LETTER
      width = (box.width * scale).round.to_i32
      height = (box.height * scale).round.to_i32

      drawer = PageDrawer.new(page, width, height, scale)
      drawer.render
    end

    def render_image_png(page_index : Int32, dpi : Number = 72) : Bytes
      img = render_image_with_dpi(page_index, dpi)
      io = ::IO::Memory.new
      CrImage::PNG.write(io, img)
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

    # A device-space edge of a filled path, kept for the scanline fill.
    private record FillEdge, x1 : Float64, y1 : Float64, x2 : Float64, y2 : Float64

    def initialize(page : Pdfbox::Pdmodel::Page, @width : Int32, @height : Int32,
                   @scale : Float64 = 1.0)
      super(page)
      @image = nil
    end

    def render : CrImage::RGBA
      img = CrImage.rgba(@width, @height)
      @image = img
      page = @page || raise "Page not set on PageDrawer"
      process_page(page)
      process_annotations
      img
    end

    private def process_annotations : Nil
      return unless pg = @page
      pg.annotations.each do |annot|
        next if annot.responds_to?(:hidden?) && annot.hidden?
        stream = annot.normal_appearance_stream
        next unless stream

        stream_obj = stream.stream_object
        next unless stream_obj
        data = stream_obj.create_input_stream.getb_to_end
        next if data.empty?

        # Get annotation rectangle and appearance bbox
        rect = annot.rectangle
        bbox = stream.bbox

        # Save graphics state
        gs = graphics_state
        saved_matrix = gs.current_transformation_matrix.clone

        if rect && bbox && rect.width > 0 && rect.height > 0 &&
           bbox.width > 0 && bbox.height > 0
          # Compute transformation matrix from appearance bbox to annotation rect
          matrix = Pdfbox::Util::Matrix.new
          matrix.translate(rect.lower_left_x, rect.lower_left_y)
          matrix.scale((rect.width / bbox.width).to_f32, (rect.height / bbox.height).to_f32)
          matrix.translate(-bbox.lower_left_x, -bbox.lower_left_y)
          gs.current_transformation_matrix.concatenate(matrix)
        end

        process_stream_operators(data)

        # Restore graphics state
        gs.current_transformation_matrix = saved_matrix
      rescue ex
      end
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
      fill_area(fill_color, winding_rule)
      @path.clear
      @pt = nil
    end

    def fill_and_stroke_path(winding_rule : Int32) : Nil
      fill_area(fill_color, winding_rule)
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

    # Draws a glyph: the outline of the character code through the font's vector
    # interface, transformed from glyph space to device space (Java
    # PageDrawer#showFontGlyph + GlyphCache#getPathForCharacterCode).
    def show_font_glyph(text_rendering_matrix : Pdfbox::Util::Matrix,
                        font : Pdfbox::Pdmodel::Font::PDFont,
                        code : Int32,
                        displacement : Pdfbox::Pdmodel::Font::PDFont::Vector) : Nil
      return unless @image

      vector_font = font.as?(Pdfbox::Pdmodel::Font::PDVectorFont)
      return unless vector_font

      # Java GlyphCache#getPathForCharacterCode may hand back null and
      # PageDrawer#drawGlyph only renders when the path is not null.
      path = vector_font.get_normalized_path(code)
      return if path.nil? || path.empty?

      # glyph space -> text space -> device space
      font_matrix = font.font_matrix
      matrix = text_rendering_matrix.multiply(
        Pdfbox::Util::Matrix.new(
          font_matrix.a, font_matrix.b, font_matrix.c,
          font_matrix.d, font_matrix.e, font_matrix.f
        )
      )

      path.each_command do |cmd_sym, args|
        case cmd_sym
        when :move_to
          point = matrix.transform_point(args[0], args[1])
          move_to(point[0].to_f32, point[1].to_f32)
        when :line_to
          point = matrix.transform_point(args[0], args[1])
          line_to(point[0].to_f32, point[1].to_f32)
        when :curve_to
          c1 = matrix.transform_point(args[0], args[1])
          c2 = matrix.transform_point(args[2], args[3])
          p = matrix.transform_point(args[4], args[5])
          curve_to(c1[0].to_f32, c1[1].to_f32, c2[0].to_f32, c2[1].to_f32,
            p[0].to_f32, p[1].to_f32)
        when :close_path
          close_path
        end
      end

      rendering_mode = graphics_state.text_state.rendering_mode
      if rendering_mode.fills_text?
        fill_path(0)
      end
      stroke_path if rendering_mode.strokes_text?
      if !rendering_mode.fills_text? && !rendering_mode.strokes_text?
        @path.clear
        @pt = nil
      end
    end

    # Java PageDrawer#showType3Glyph: nothing is drawn in the NEITHER rendering
    # mode, otherwise the character procedure stream is processed.
    def show_type3_glyph(text_rendering_matrix : Pdfbox::Util::Matrix,
                         font : Pdfbox::Pdmodel::Font::PDType3Font,
                         code : Int32,
                         displacement : Pdfbox::Pdmodel::Font::PDFont::Vector) : Nil
      super unless graphics_state.text_state.rendering_mode.neither?
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

    # Java PageDrawer#fillPath hands the device-space path to
    # `Graphics2D#fill(Shape)` with the path's winding rule
    # (`linePath.setWindingRule`). The port rasterizes the same area with a
    # scanline fill: for every device row it collects the edge crossings, orders
    # them by x and paints the spans that the winding rule reports as inside.
    private def fill_area(color : CrImage::Color::Color?, winding_rule : Int32) : Nil
      return unless c = color
      return unless img = @image

      edges, min_y, max_y = collect_fill_edges
      # a path with no area (e.g. a single horizontal line) paints nothing
      return if edges.empty? || max_y < min_y

      first_row = {min_y.floor.to_i32, 0}.max
      last_row = {max_y.ceil.to_i32, @height - 1}.min
      return if last_row < first_row

      even_odd = winding_rule == 1
      crossings = [] of Tuple(Float64, Int32)

      (first_row..last_row).each do |row|
        y = row + 0.5
        crossings.clear
        edges.each do |edge|
          # half-open test so a vertex shared by two edges counts once
          next unless (edge.y1 <= y && edge.y2 > y) || (edge.y2 <= y && edge.y1 > y)
          t = (y - edge.y1) / (edge.y2 - edge.y1)
          crossings << {edge.x1 + t * (edge.x2 - edge.x1), edge.y2 > edge.y1 ? 1 : -1}
        end
        next if crossings.empty?
        crossings.sort_by! { |(x, _)| x }

        winding = 0
        span_start = nil.as(Float64?)
        crossings.each do |x, direction|
          inside_before = inside?(winding, even_odd)
          winding += even_odd ? 1 : direction
          inside_after = inside?(winding, even_odd)
          if !inside_before && inside_after
            span_start = x
          elsif inside_before && !inside_after
            if start = span_start
              fill_span(img, start, x, row, c)
              span_start = nil
            end
          end
        end
      end
    end

    private def inside?(winding : Int32, even_odd : Bool) : Bool
      even_odd ? winding.odd? : winding != 0
    end

    private def fill_span(img : CrImage::RGBA, x_start : Float64, x_end : Float64,
                          py : Int32, c : CrImage::Color::Color) : Nil
      return if x_end <= x_start
      # pixel centres are at x + 0.5
      first = {(x_start - 0.5).ceil.to_i32, 0}.max
      last = {(x_end - 0.5).ceil.to_i32 - 1, @width - 1}.min
      return if last < first
      (first..last).each { |col| img[col, py] = c }
    end

    # Collects the path as device-space edges for a scanline fill. Every subpath
    # is implicitly closed, like Java's `Graphics2D#fill`. Returns the edges and
    # their combined y range.
    private def collect_fill_edges : Tuple(Array(FillEdge), Float64, Float64)
      edges = [] of FillEdge
      px = 0.0
      py = 0.0
      start_x = 0.0
      start_y = 0.0

      @path.each do |seg|
        case seg.kind
        when :move
          # close the subpath we were in, if any
          edges << FillEdge.new(px, py, start_x, start_y) if px != start_x || py != start_y
          start_x, start_y = seg.x1, seg.y1
          px, py = seg.x1, seg.y1
        when :line
          edges << FillEdge.new(px, py, seg.x1, seg.y1)
          px, py = seg.x1, seg.y1
        when :curve
          bezier_segments(px, py, seg.x1, seg.y1, seg.x2, seg.y2, seg.x3, seg.y3).each do |bx1, by1, bx2, by2|
            edges << FillEdge.new(bx1, by1, bx2, by2)
          end
          px, py = seg.x3, seg.y3
        when :close
          edges << FillEdge.new(px, py, start_x, start_y)
          px, py = start_x, start_y
        end
      end
      # an unclosed final subpath is closed implicitly
      edges << FillEdge.new(px, py, start_x, start_y) if px != start_x || py != start_y

      min_y = Float64::MAX
      max_y = -Float64::MAX
      edges.each do |edge|
        low = edge.y1 < edge.y2 ? edge.y1 : edge.y2
        high = edge.y1 < edge.y2 ? edge.y2 : edge.y1
        min_y = low if low < min_y
        max_y = high if high > max_y
      end
      {edges, min_y, max_y}
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
