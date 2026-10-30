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
      stroke_area(stroke_color)
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
      stroke_area(stroke_color)
      @path.clear
      @pt = nil
    end

    def clip(winding_rule : Int32) : Nil
      # Java PageDrawer#clip: hand the current path to the graphics state's
      # clipping paths. The path is not consumed here — the following painting
      # operator or `n` clears it.
      path = collect_clip_path(winding_rule)
      return unless path
      graphics_state.intersect_clipping_path(path)
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
        clip_paths = graphics_state.clipping_paths

        h.times do |row|
          w.times do |col|
            si = (row * w + col) * bpp
            break if si + 2 >= data.size
            px = ox + col
            py = oy + h - 1 - row
            if px >= 0 && px < @width && py >= 0 && py < @height &&
               clipped_at?(clip_paths, px + 0.5, py + 0.5)
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

    # Java PageDrawer#fillPath hands the device-space path to
    # `Graphics2D#fill(Shape)` with the path's winding rule
    # (`linePath.setWindingRule`). The port rasterizes the same area with a
    # scanline fill: for every device row it collects the edge crossings, orders
    # them by x and paints the spans that the winding rule reports as inside.
    private def fill_area(color : CrImage::Color::Color?, winding_rule : Int32) : Nil
      edges, min_y, max_y = collect_fill_edges
      scan_fill(edges, min_y, max_y, winding_rule, color)
    end

    # Paints the area enclosed by *edges* with the given winding rule. Pixel
    # centres are sampled at the integer device coordinates.
    private def scan_fill(edges : Array(FillEdge), min_y : Float64, max_y : Float64,
                          winding_rule : Int32, color : CrImage::Color::Color?) : Nil
      return unless c = color
      return unless img = @image
      # a path with no area (e.g. a single horizontal line) paints nothing
      return if edges.empty? || max_y < min_y

      first_row = {min_y.floor.to_i32, 0}.max
      last_row = {max_y.ceil.to_i32, @height - 1}.min
      return if last_row < first_row

      even_odd = winding_rule == 1
      clip_paths = graphics_state.clipping_paths
      crossings = [] of Tuple(Float64, Int32)

      (first_row..last_row).each do |row|
        y = row.to_f64
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
              fill_span(img, start, x, row, c, clip_paths)
              span_start = nil
            end
          end
        end
      end
    end

    private def inside?(winding : Int32, even_odd : Bool) : Bool
      even_odd ? winding.odd? : winding != 0
    end

    # Whether a device-space point survives the current clipping paths (Java
    # `PageDrawer#setClip` + `Area#contains`). Written as a plain loop so the
    # per-pixel test does not allocate a closure on unclipped pages.
    private def clipped_at?(clip_paths : Array(Pdfbox::Util::ClipPath),
                            x : Float64, y : Float64) : Bool
      return true if clip_paths.empty?
      clip_paths.each do |clip_path|
        return false unless clip_path.contains?(x, y)
      end
      true
    end

    private def fill_span(img : CrImage::RGBA, x_start : Float64, x_end : Float64,
                          py : Int32, c : CrImage::Color::Color,
                          clip_paths : Array(Pdfbox::Util::ClipPath)) : Nil
      return if x_end <= x_start
      # pixel centres are sampled at the integer device coordinates
      first = {x_start.ceil.to_i32, 0}.max
      last = {x_end.ceil.to_i32 - 1, @width - 1}.min
      return if last < first
      if clip_paths.empty?
        (first..last).each { |col| img[col, py] = c }
      else
        (first..last).each do |col|
          img[col, py] = c if clipped_at?(clip_paths, col.to_f64, py.to_f64)
        end
      end
    end

    # Collects the path as device-space edges for a scanline fill, plus their
    # combined y range. Every subpath is implicitly closed, like Java's
    # `Graphics2D#fill`.
    private def collect_fill_edges : Tuple(Array(FillEdge), Float64, Float64)
      edges = [] of FillEdge
      min_y = Float64::MAX
      max_y = -Float64::MAX

      each_subpath do |points|
        points.each_with_index do |(x1, y1), i|
          x2, y2 = points[(i + 1) % points.size]
          edges << FillEdge.new(x1, y1, x2, y2)
          low = y1 < y2 ? y1 : y2
          high = y1 < y2 ? y2 : y1
          min_y = low if low < min_y
          max_y = high if high > max_y
        end
      end
      {edges, min_y, max_y}
    end

    # Collects the path as one device-space clipping path (nil when the path has
    # no area, like Java's empty-path check before intersecting).
    private def collect_clip_path(winding_rule : Int32) : Pdfbox::Util::ClipPath?
      subpaths = [] of Array(Tuple(Float64, Float64))
      each_subpath { |points| subpaths << points }
      return nil if subpaths.empty?
      path = Pdfbox::Util::ClipPath.new(subpaths, winding_rule)
      path.empty? ? nil : path
    end

    # Walks the path and yields each subpath as its point list, implicitly
    # closing open subpaths (Java `Graphics2D#fill` and `Area` both do).
    private def each_subpath(&) : Nil
      points = [] of Tuple(Float64, Float64)
      px = 0.0
      py = 0.0
      start_x = 0.0
      start_y = 0.0

      @path.each do |seg|
        case seg.kind
        when :move
          yield points if points.size >= 3
          points = [{seg.x1, seg.y1}]
          start_x, start_y = seg.x1, seg.y1
          px, py = seg.x1, seg.y1
        when :line
          points << {seg.x1, seg.y1}
          px, py = seg.x1, seg.y1
        when :curve
          bezier_segments(px, py, seg.x1, seg.y1, seg.x2, seg.y2, seg.x3, seg.y3).each do |_, _, bx2, by2|
            points << {bx2, by2}
          end
          px, py = seg.x3, seg.y3
        when :close
          yield points if points.size >= 3
          # a closed subpath starts over at its start point
          points = [{start_x, start_y}]
          px, py = start_x, start_y
        end
      end
      yield points if points.size >= 3
    end

    # --- Stroking ---

    # The stroke parameters Java builds a `BasicStroke` from
    # (PageDrawer#getStroke): width and dash lengths are already scaled to device
    # space, the cap/join are clamped to their legal 0..2 range, an out-of-range
    # miter limit falls back to 10, and `visible` is false for an all-zero dash
    # array (PDFBOX-5168 paints those invisible).
    private record StrokeStyle, width : Float64, cap : Int32, join : Int32,
      miter_limit : Float64, dashes : Array(Float64), phase : Float64, visible : Bool

    private def stroke_style : StrokeStyle
      state = graphics_state
      # Adobe Reader's minimum line width (Java PageDrawer#getStroke)
      width = transform_width(state.line_width.to_f64)
      width = 0.25 if width < 0.25

      cap = state.line_cap.clamp(0, 2)
      join = state.line_join.clamp(0, 2)
      miter_limit = state.miter_limit.to_f64
      miter_limit = 10.0 if miter_limit < 1.0

      pattern = state.line_dash_pattern
      raw_dashes = pattern.dash_array
      dashes = [] of Float64
      visible = true
      unless raw_dashes.empty?
        if raw_dashes.any? { |dash| !dash.finite? }
          # Java getDashArray: unusable values fall back to a solid line
        else
          visible = false if raw_dashes.all? { |dash| dash == 0.0 }
          # Java getDashArray scales every element and clamps it to a small
          # minimum; it picks 0.2 when xformScalingFactorX < 0.5 (a JVM workaround),
          # the port always uses the 0.062 minimum.
          dashes = raw_dashes.map { |dash| Math.max(transform_width(dash), 0.062) }
        end
      end
      phase = transform_width(pattern.phase.to_f64)

      StrokeStyle.new(width, cap, join, miter_limit, dashes, phase, visible)
    end

    # Java PageDrawer#strokePath: `Graphics2D#draw(linePath)` with the current
    # stroke. The port builds the stroke outline as polygons and scanline-fills
    # them, which is what `draw` does for an unantialiased rasterizer.
    private def stroke_area(color : CrImage::Color::Color?) : Nil
      return unless color
      return unless @image

      style = stroke_style
      return unless style.visible

      half_width = style.width / 2.0
      polygons = [] of Array(Tuple(Float64, Float64))
      each_polyline do |points, closed|
        if style.dashes.empty?
          stroke_run(points, closed, style, half_width, polygons)
        else
          dash_runs(points, closed, style).each do |run|
            stroke_run(run, false, style, half_width, polygons)
          end
        end
      end
      return if polygons.empty?

      edges = [] of FillEdge
      min_y = Float64::MAX
      max_y = -Float64::MAX
      polygons.each do |polygon|
        polygon.each_with_index do |(x1, y1), i|
          x2, y2 = polygon[(i + 1) % polygon.size]
          edges << FillEdge.new(x1, y1, x2, y2)
          low = y1 < y2 ? y1 : y2
          high = y1 < y2 ? y2 : y1
          min_y = low if low < min_y
          max_y = high if high > max_y
        end
      end
      scan_fill(edges, min_y, max_y, Pdfbox::Util::ClipPath::WIND_NON_ZERO, color)
    end

    # Strokes one polyline: a quad per segment, a join at every interior vertex
    # and a cap at the free ends of an open subpath.
    private def stroke_run(points : Array(Tuple(Float64, Float64)), closed : Bool,
                           style : StrokeStyle, half_width : Float64,
                           polygons : Array(Array(Tuple(Float64, Float64)))) : Nil
      return if points.size < 2

      segments = closed ? points.size : points.size - 1
      segments.times do |i|
        x0, y0 = points[i]
        x1, y1 = points[(i + 1) % points.size]
        emit_segment(x0, y0, x1, y1, half_width, polygons)
      end

      # joins only happen between two segments: every vertex of a closed path,
      # the interior vertices of an open one
      if closed
        points.size.times do |i|
          prev = points[(i - 1 + points.size) % points.size]
          upcoming = points[(i + 1) % points.size]
          emit_join(prev, points[i], upcoming, style, half_width, polygons)
        end
      else
        (1...(points.size - 1)).each do |i|
          emit_join(points[i - 1], points[i], points[i + 1], style, half_width, polygons)
        end
      end

      return if closed
      emit_cap(points[0], points[1], true, style, half_width, polygons)
      emit_cap(points[-1], points[-2], false, style, half_width, polygons)
    end

    private def emit_segment(x0 : Float64, y0 : Float64, x1 : Float64, y1 : Float64,
                             half_width : Float64,
                             polygons : Array(Array(Tuple(Float64, Float64)))) : Nil
      dx = x1 - x0
      dy = y1 - y0
      length = Math.sqrt(dx * dx + dy * dy)
      return if length < 1e-9
      nx = -dy / length * half_width
      ny = dx / length * half_width
      emit_polygon([
        {x0 + nx, y0 + ny},
        {x1 + nx, y1 + ny},
        {x1 - nx, y1 - ny},
        {x0 - nx, y0 - ny},
      ], polygons)
    end

    # Java `BasicStroke` join: 0 = miter (falling back to bevel past the miter
    # limit), 1 = round, 2 = bevel.
    private def emit_join(prev : Tuple(Float64, Float64), vertex : Tuple(Float64, Float64),
                          upcoming : Tuple(Float64, Float64), style : StrokeStyle,
                          half_width : Float64,
                          polygons : Array(Array(Tuple(Float64, Float64)))) : Nil
      direction0 = unit_vector(prev, vertex)
      return unless direction0
      direction1 = unit_vector(vertex, upcoming)
      return unless direction1
      d0x, d0y = direction0
      d1x, d1y = direction1

      cross = d0x * d1y - d0y * d1x
      return if cross.abs < 1e-9 # collinear, the segment quads already meet

      # the outer side of the turn
      if cross > 0
        n0x = d0y * half_width
        n0y = -d0x * half_width
        n1x = d1y * half_width
        n1y = -d1x * half_width
      else
        n0x = -d0y * half_width
        n0y = d0x * half_width
        n1x = -d1y * half_width
        n1y = d1x * half_width
      end

      vx, vy = vertex
      case style.join
      when 1 # round
        from = Math.atan2(n0y, n0x)
        to = Math.atan2(n1y, n1x)
        emit_arc(vx, vy, half_width, from, sweep_towards(from, to, cross > 0), polygons)
      when 2 # bevel
        emit_polygon([{vx, vy}, {vx + n0x, vy + n0y}, {vx + n1x, vy + n1y}], polygons)
      else # miter
        miter = miter_point(vx, vy, d0x, d0y, n0x, n0y, d1x, d1y, n1x, n1y)
        if miter && distance(vx, vy, miter[0], miter[1]) <= style.miter_limit * half_width
          emit_polygon([
            {vx, vy},
            {vx + n0x, vy + n0y},
            miter,
            {vx + n1x, vy + n1y},
          ], polygons)
        else
          emit_polygon([{vx, vy}, {vx + n0x, vy + n0y}, {vx + n1x, vy + n1y}], polygons)
        end
      end
    end

    # Intersection of the two offset edges, i.e. the outer miter tip.
    private def miter_point(vx : Float64, vy : Float64,
                            d0x : Float64, d0y : Float64, n0x : Float64, n0y : Float64,
                            d1x : Float64, d1y : Float64, n1x : Float64, n1y : Float64) : Tuple(Float64, Float64)?
      ax = vx + n0x
      ay = vy + n0y
      bx = vx + n1x
      by = vy + n1y
      denominator = d0x * d1y - d0y * d1x
      return nil if denominator.abs < 1e-9
      t = ((bx - ax) * d1y - (by - ay) * d1x) / denominator
      {ax + d0x * t, ay + d0y * t}
    end

    # Java `BasicStroke` cap: 0 = butt (nothing), 1 = round, 2 = square.
    private def emit_cap(end_point : Tuple(Float64, Float64), neighbour : Tuple(Float64, Float64),
                         at_start : Bool, style : StrokeStyle, half_width : Float64,
                         polygons : Array(Array(Tuple(Float64, Float64)))) : Nil
      return if style.cap == 0
      direction = unit_vector(end_point, neighbour)
      return unless direction
      dx, dy = direction
      # point away from the line
      dx = -dx if at_start
      dy = -dy if at_start

      ex, ey = end_point
      case style.cap
      when 1 # round
        from = Math.atan2(-dy * half_width, -dx * half_width)
        # sweep through the outward direction (-d, pointing away from the line)
        outward = Math.atan2(dy, dx)
        delta = (outward - from) % (2 * Math::PI)
        sweep = delta < Math::PI ? Math::PI : -Math::PI
        emit_arc(ex, ey, half_width, from, sweep, polygons)
      else # square
        nx = -dy * half_width
        ny = dx * half_width
        emit_polygon([
          {ex + nx, ey + ny},
          {ex + nx + dx * half_width, ey + ny + dy * half_width},
          {ex - nx + dx * half_width, ey - ny + dy * half_width},
          {ex - nx, ey - ny},
        ], polygons)
      end
    end

    # Emits a fan polygon approximating an arc of `sweep` radians (signed)
    # starting at angle `from` around the centre.
    private def emit_arc(cx : Float64, cy : Float64, radius : Float64,
                         from : Float64, sweep : Float64,
                         polygons : Array(Array(Tuple(Float64, Float64)))) : Nil
      steps = 8
      points = [{cx, cy}] of Tuple(Float64, Float64)
      (0..steps).each do |step|
        angle = from + sweep * step / steps
        points << {cx + radius * Math.cos(angle), cy + radius * Math.sin(angle)}
      end
      emit_polygon(points, polygons)
    end

    # Adds a polygon, oriented consistently so the non-zero winding of the
    # overlapping stroke pieces is their union.
    private def emit_polygon(points : Array(Tuple(Float64, Float64)),
                             polygons : Array(Array(Tuple(Float64, Float64)))) : Nil
      return if points.size < 3
      area = 0.0
      points.each_with_index do |(x1, y1), i|
        x2, y2 = points[(i + 1) % points.size]
        area += x1 * y2 - x2 * y1
      end
      polygons << (area < 0 ? points.reverse : points)
    end

    # The signed sweep from `first` to `second`, in (0, 2pi) when `positive` and
    # in (-2pi, 0) otherwise.
    private def sweep_towards(first : Float64, second : Float64, positive : Bool) : Float64
      two_pi = 2 * Math::PI
      delta = second - first
      if positive
        while delta <= 0
          delta += two_pi
        end
        while delta > two_pi
          delta -= two_pi
        end
      else
        while delta >= 0
          delta -= two_pi
        end
        while delta < -two_pi
          delta += two_pi
        end
      end
      delta
    end

    private def unit_vector(from : Tuple(Float64, Float64),
                            to : Tuple(Float64, Float64)) : Tuple(Float64, Float64)?
      dx = to[0] - from[0]
      dy = to[1] - from[1]
      length = Math.sqrt(dx * dx + dy * dy)
      return nil if length < 1e-9
      {dx / length, dy / length}
    end

    private def distance(x1 : Float64, y1 : Float64, x2 : Float64, y2 : Float64) : Float64
      Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
    end

    # Splits a polyline into the painted runs of the dash pattern (Java
    # `BasicStroke` dashing): the array alternates on/off lengths and `phase`
    # shifts the pattern along the path.
    private def dash_runs(points : Array(Tuple(Float64, Float64)), closed : Bool,
                          style : StrokeStyle) : Array(Array(Tuple(Float64, Float64)))
      path = closed ? points + [points[0]] : points
      dashes = style.dashes
      total = dashes.sum
      return [path] if total <= 0

      # starting position inside the pattern
      offset = style.phase % total
      index = 0
      while offset >= dashes[index]
        offset -= dashes[index]
        index = (index + 1) % dashes.size
      end
      remaining = dashes[index] - offset
      on = index.even?

      runs = [] of Array(Tuple(Float64, Float64))
      run = [] of Tuple(Float64, Float64)
      run << path[0] if on

      (0...(path.size - 1)).each do |i|
        x0, y0 = path[i]
        x1, y1 = path[i + 1]
        dx = x1 - x0
        dy = y1 - y0
        length = Math.sqrt(dx * dx + dy * dy)
        next if length < 1e-9
        ux = dx / length
        uy = dy / length
        travelled = 0.0
        while travelled < length
          step = Math.min(remaining, length - travelled)
          travelled += step
          remaining -= step
          if on
            run << {x0 + ux * travelled, y0 + uy * travelled}
          end
          next if remaining > 1e-9
          # this dash element ends here
          if on
            runs << run if run.size >= 2
            run = [] of Tuple(Float64, Float64)
          else
            run = [{x0 + ux * travelled, y0 + uy * travelled}]
          end
          on = !on
          index = (index + 1) % dashes.size
          remaining = dashes[index]
        end
      end
      runs << run if on && run.size >= 2
      runs
    end

    # Walks the path and yields every subpath as an open or closed polyline
    # (stroke paths are not implicitly closed, unlike fills).
    private def each_polyline(&) : Nil
      points = [] of Tuple(Float64, Float64)
      px = 0.0
      py = 0.0
      start_x = 0.0
      start_y = 0.0

      @path.each do |seg|
        case seg.kind
        when :move
          yield points, false if points.size >= 2
          points = [{seg.x1, seg.y1}]
          start_x, start_y = seg.x1, seg.y1
          px, py = seg.x1, seg.y1
        when :line
          points << {seg.x1, seg.y1}
          px, py = seg.x1, seg.y1
        when :curve
          bezier_segments(px, py, seg.x1, seg.y1, seg.x2, seg.y2, seg.x3, seg.y3).each do |_, _, bx2, by2|
            points << {bx2, by2}
          end
          px, py = seg.x3, seg.y3
        when :close
          yield points, true if points.size >= 2
          points = [{start_x, start_y}]
          px, py = start_x, start_y
        end
      end
      yield points, false if points.size >= 2
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
  end
end
