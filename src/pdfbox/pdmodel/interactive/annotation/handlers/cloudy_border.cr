# Port of org.apache.pdfbox.pdmodel.interactive.annotation.handlers.CloudyBorder
# Generates annotation appearances with a cloudy border effect.
require "./pdabstract_appearance_handler"

module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class CloudyBorder
    private ANGLE_180_DEG = Math::PI
    private ANGLE_90_DEG  = Math::PI / 2
    private ANGLE_34_DEG  = Math::PI * 34.0 / 180.0
    private ANGLE_30_DEG  = Math::PI * 30.0 / 180.0
    private ANGLE_12_DEG  = Math::PI * 12.0 / 180.0

    @output : Pdmodel::PDAppearanceContentStream
    @annot_rect : Common::PDRectangle
    @intensity : Float64
    @line_width : Float64
    @rect_with_diff : Common::PDRectangle?
    @output_started = false
    @bbox_min_x = 0.0
    @bbox_min_y = 0.0
    @bbox_max_x = 0.0
    @bbox_max_y = 0.0

    record Point, x : Float64, y : Float64 do
      def distance(other : Point) : Float64
        dx = x - other.x
        dy = y - other.y
        Math.sqrt(dx * dx + dy * dy)
      end
    end

    def initialize(@output : Pdmodel::PDAppearanceContentStream, @intensity : Float64,
                   @line_width : Float64, @annot_rect : Common::PDRectangle)
    end

    def create_cloudy_rectangle(rd : Common::PDRectangle?) : Nil
      @rect_with_diff = apply_rect_diff(rd, (@line_width / 2).to_f32)
      left = @rect_with_diff.as(Common::PDRectangle).lower_left_x.to_f64
      bottom = @rect_with_diff.as(Common::PDRectangle).lower_left_y.to_f64
      right = @rect_with_diff.as(Common::PDRectangle).upper_right_x.to_f64
      top = @rect_with_diff.as(Common::PDRectangle).upper_right_y.to_f64
      cloudy_rectangle_impl(left, bottom, right, top, false)
      finish
    end

    def create_cloudy_polygon(path : Array(Array(Float32))) : Nil
      n = path.size
      polygon = Array(Point).new(n)
      path.each do |array|
        case array.size
        when 2 then polygon << Point.new(array[0].to_f64, array[1].to_f64)
        when 6 then polygon << Point.new(array[4].to_f64, array[5].to_f64)
        end
      end
      cloudy_polygon_impl(polygon, false)
      finish
    end

    def create_cloudy_ellipse(rd : Common::PDRectangle?) : Nil
      @rect_with_diff = apply_rect_diff(rd, 0_f32)
      left = @rect_with_diff.as(Common::PDRectangle).lower_left_x.to_f64
      bottom = @rect_with_diff.as(Common::PDRectangle).lower_left_y.to_f64
      right = @rect_with_diff.as(Common::PDRectangle).upper_right_x.to_f64
      top = @rect_with_diff.as(Common::PDRectangle).upper_right_y.to_f64
      cloudy_ellipse_impl(left, bottom, right, top)
      finish
    end

    def bbox : Common::PDRectangle
      rectangle
    end

    def rectangle : Common::PDRectangle
      Common::PDRectangle.new(@bbox_min_x.to_f32, @bbox_min_y.to_f32,
        (@bbox_max_x - @bbox_min_x).to_f32, (@bbox_max_y - @bbox_min_y).to_f32)
    end

    def matrix : Util::Matrix
      Util::Matrix.translate(-@bbox_min_x.to_f32, -@bbox_min_y.to_f32)
    end

    def rect_difference : Common::PDRectangle
      if @annot_rect.nil?
        d = @line_width.to_f32 / 2
        return Common::PDRectangle.new(d, d, @line_width.to_f32, @line_width.to_f32)
      end
      re = @rect_with_diff || @annot_rect
      left = re.lower_left_x.to_f64 - @bbox_min_x
      bottom = re.lower_left_y.to_f64 - @bbox_min_y
      right = @bbox_max_x - re.upper_right_x.to_f64
      top = @bbox_max_y - re.upper_right_y.to_f64
      Common::PDRectangle.new(left.to_f32, bottom.to_f32,
        (right - left).to_f32, (top - bottom).to_f32)
    end

    private def cosine(dx : Float64, hypot : Float64) : Float64
      return 0.0 if hypot == 0.0
      dx / hypot
    end

    private def sine(dy : Float64, hypot : Float64) : Float64
      return 0.0 if hypot == 0.0
      dy / hypot
    end

    private def cloudy_rectangle_impl(left : Float64, bottom : Float64, right : Float64, top : Float64, is_ellipse : Bool) : Nil
      w = right - left
      h = top - bottom
      if @intensity <= 0.0
        @output.add_rect(left.to_f32, bottom.to_f32, w.to_f32, h.to_f32)
        @bbox_min_x = left; @bbox_min_y = bottom
        @bbox_max_x = right; @bbox_max_y = top
        return
      end

      polygon = if w < 1.0
                  [Point.new(left, bottom), Point.new(left, top), Point.new(left, bottom)]
                elsif h < 1.0
                  [Point.new(left, bottom), Point.new(right, bottom), Point.new(left, bottom)]
                else
                  [Point.new(left, bottom), Point.new(right, bottom),
                   Point.new(right, top), Point.new(left, top),
                   Point.new(left, bottom)]
                end
      cloudy_polygon_impl(polygon, is_ellipse)
    end

    private def cloudy_polygon_impl(vertices : Array(Point), is_ellipse : Bool) : Nil
      polygon = remove_zero_length_segments(vertices)
      get_positive_polygon(polygon)
      num_points = polygon.size
      return if num_points < 2

      if @intensity <= 0.0
        move_to(polygon[0])
        (1...num_points).each { |i| line_to(polygon[i]) }
        return
      end

      cloud_radius = is_ellipse ? get_ellipse_cloud_radius : get_polygon_cloud_radius
      cloud_radius = Math.max(cloud_radius, 0.5)

      k = Math.cos(ANGLE_34_DEG)
      adv_interm_default = 2 * k * cloud_radius
      adv_corner_default = k * cloud_radius
      angle_prev = 0.0

      # First segment uses last point → first point
      n0_val, alpha_val, dx_val = compute_params_polygon(adv_interm_default, adv_corner_default, k, cloud_radius, polygon[num_points - 2].distance(polygon[0]))
      alpha_prev = (n0_val == 0) ? alpha_val : ANGLE_34_DEG

      (0...(num_points - 1)).each do |j|
        pt = polygon[j]
        pt_next = polygon[j + 1]
        length = pt.distance(pt_next)
        if length == 0.0
          alpha_prev = ANGLE_34_DEG
          next
        end

        n_val, alpha_val, dx_val = compute_params_polygon(adv_interm_default, adv_corner_default, k, cloud_radius, length)
        if n_val < 0
          unless @output_started
            move_to(pt)
          end
          next
        end

        alpha = alpha_val
        dx = dx_val

        angle_cur = Math.atan2(pt_next.y - pt.y, pt_next.x - pt.x)
        if j == 0
          pt_prev = polygon[num_points - 2]
          angle_prev = Math.atan2(pt.y - pt_prev.y, pt.x - pt_prev.x)
        end

        cos_a = cosine(pt_next.x - pt.x, length)
        sin_a = sine(pt_next.y - pt.y, length)
        x = pt.x
        y = pt.y

        add_corner_curl(angle_prev, angle_cur, cloud_radius, pt.x, pt.y, alpha, alpha_prev, !@output_started)

        adv = 2 * k * cloud_radius + 2 * dx
        x += adv * cos_a
        y += adv * sin_a

        num_interm = n_val
        if n_val >= 1
          add_first_intermediate_curl(angle_cur, cloud_radius, alpha, x, y)
          x += adv_interm_default * cos_a
          y += adv_interm_default * sin_a
          num_interm = n_val - 1
        end

        template = get_intermediate_curl_template(angle_cur, cloud_radius)
        num_interm.times do
          pointsput_curl_template(template, x, y)
          x += adv_interm_default * cos_a
          y += adv_interm_default * sin_a
        end

        angle_prev = angle_cur
        alpha_prev = (n_val == 0) ? alpha : ANGLE_34_DEG
      end
    end

    private def compute_params_polygon(adv_interm : Float64, adv_corner : Float64, k : Float64,
                                       r : Float64, length : Float64) : {Int32, Float64, Float64}
      if length == 0.0
        return {0, ANGLE_34_DEG, 0.0}
      end

      n = ((length - 2 * adv_corner) / adv_interm).ceil.to_i
      e = length - (2 * adv_corner + n * adv_interm)
      dx_fit = e / 2
      arg = (k * r + dx_fit) / r
      alpha = (arg < -1.0 || arg > 1.0) ? 0.0 : Math.acos(arg)
      {n, alpha, dx_fit}
    end

    private def add_corner_curl(angle_prev : Float64, angle_cur : Float64, radius : Float64,
                                cx : Float64, cy : Float64, alpha : Float64, alpha_prev : Float64,
                                add_move_to : Bool) : Nil
      a = angle_prev + ANGLE_180_DEG + alpha_prev
      b = angle_prev + ANGLE_180_DEG + alpha_prev - Math::PI * 22.0 / 180.0
      get_arc_segment(a, b, cx, cy, radius, radius, nil, add_move_to)
      a = b
      b = angle_cur - alpha
      get_arc(a, b, radius, radius, cx, cy, nil, false)
    end

    private def add_first_intermediate_curl(angle_cur : Float64, r : Float64, alpha : Float64,
                                            cx : Float64, cy : Float64) : Nil
      a = angle_cur + ANGLE_180_DEG
      get_arc_segment(a + alpha, a + alpha - ANGLE_30_DEG, cx, cy, r, r, nil, false)
      get_arc_segment(a + alpha - ANGLE_30_DEG, a + ANGLE_90_DEG, cx, cy, r, r, nil, false)
      get_arc_segment(a + ANGLE_90_DEG, a + ANGLE_180_DEG - ANGLE_34_DEG, cx, cy, r, r, nil, false)
    end

    private def get_intermediate_curl_template(angle_cur : Float64, r : Float64) : Array(Point)
      points = [] of Point
      a = angle_cur + ANGLE_180_DEG
      get_arc_segment(a + ANGLE_34_DEG, a + ANGLE_12_DEG, 0.0, 0.0, r, r, points, false)
      get_arc_segment(a + ANGLE_12_DEG, a + ANGLE_90_DEG, 0.0, 0.0, r, r, points, false)
      get_arc_segment(a + ANGLE_90_DEG, a + ANGLE_180_DEG - ANGLE_34_DEG, 0.0, 0.0, r, r, points, false)
      points
    end

    private def pointsput_curl_template(template : Array(Point), x : Float64, y : Float64) : Nil
      n = template.size
      i = 0
      if (n % 3) == 1
        pt = template[0]
        move_to(pt.x + x, pt.y + y)
        i += 1
      end
      while i + 2 < n
        a = template[i]
        b = template[i + 1]
        c = template[i + 2]
        curve_to(a.x + x, a.y + y, b.x + x, b.y + y, c.x + x, c.y + y)
        i += 3
      end
    end

    private def apply_rect_diff(rd : Common::PDRectangle?, min : Float32) : Common::PDRectangle
      rect_left = Math.min(@annot_rect.lower_left_x, @annot_rect.upper_right_x).to_f32
      rect_bottom = Math.min(@annot_rect.lower_left_y, @annot_rect.upper_right_y).to_f32
      rect_right = Math.max(@annot_rect.lower_left_x, @annot_rect.upper_right_x).to_f32
      rect_top = Math.max(@annot_rect.lower_left_y, @annot_rect.upper_right_y).to_f32

      rd_left = rd ? Math.max(rd.lower_left_x, min) : min
      rd_bottom = rd ? Math.max(rd.lower_left_y, min) : min
      rd_right = rd ? Math.max(rd.upper_right_x, min) : min
      rd_top = rd ? Math.max(rd.upper_right_y, min) : min

      Common::PDRectangle.new(
        rect_left + rd_left, rect_bottom + rd_bottom,
        (rect_right - rd_right) - (rect_left + rd_left),
        (rect_top - rd_top) - (rect_bottom + rd_bottom)
      )
    end

    private def reverse_polygon(points : Array(Point)) : Nil
      len = points.size
      (0...(len // 2)).each do |i|
        j = len - i - 1
        points[i], points[j] = points[j], points[i]
      end
    end

    private def get_positive_polygon(points : Array(Point)) : Nil
      reverse_polygon(points) if get_polygon_direction(points) < 0
    end

    private def get_polygon_direction(points : Array(Point)) : Float64
      a = 0.0
      len = points.size
      len.times do |i|
        j = (i + 1) % len
        a += points[i].x * points[j].y - points[i].y * points[j].x
      end
      a
    end

    private def get_arc(start_ang : Float64, end_ang : Float64, rx : Float64, ry : Float64,
                        cx : Float64, cy : Float64, points : Array(Point)?, add_move_to : Bool) : Nil
      angle_incr = Math::PI / 2
      startx = rx * Math.cos(start_ang) + cx
      starty = ry * Math.sin(start_ang) + cy

      angle_todo = end_ang - start_ang
      while angle_todo < 0
        angle_todo += 2 * Math::PI
      end
      sweep = angle_todo
      angle_done = 0.0

      if add_move_to
        if points
          points << Point.new(startx, starty)
        else
          move_to(startx, starty)
        end
      end

      while angle_todo > angle_incr
        get_arc_segment(start_ang + angle_done, start_ang + angle_done + angle_incr, cx, cy, rx, ry, points, false)
        angle_done += angle_incr
        angle_todo -= angle_incr
      end

      if angle_todo > 0
        get_arc_segment(start_ang + angle_done, start_ang + sweep, cx, cy, rx, ry, points, false)
      end
    end

    # Creates a single Bezier curve for an elliptical arc sweep <= 90 degrees.
    private def get_arc_segment(start_ang : Float64, end_ang : Float64, cx : Float64, cy : Float64,
                                rx : Float64, ry : Float64, points : Array(Point)?, add_move_to : Bool) : Nil
      cos_a = Math.cos(start_ang)
      sin_a = Math.sin(start_ang)
      cos_b = Math.cos(end_ang)
      sin_b = Math.sin(end_ang)
      denom = Math.sin((end_ang - start_ang) / 2.0)
      if denom == 0.0
        if add_move_to
          xs = cx + rx * cos_a
          ys = cy + ry * sin_a
          if points
            points << Point.new(xs, ys)
          else
            move_to(xs, ys)
          end
        end
        return
      end

      bcp = 1.333333333 * (1.0 - Math.cos((end_ang - start_ang) / 2.0)) / denom
      p1x = cx + rx * (cos_a - bcp * sin_a)
      p1y = cy + ry * (sin_a + bcp * cos_a)
      p2x = cx + rx * (cos_b + bcp * sin_b)
      p2y = cy + ry * (sin_b - bcp * cos_b)
      p3x = cx + rx * cos_b
      p3y = cy + ry * sin_b

      if add_move_to
        xs = cx + rx * cos_a
        ys = cy + ry * sin_a
        if points
          points << Point.new(xs, ys)
        else
          move_to(xs, ys)
        end
      end

      if points
        points << Point.new(p1x, p1y) << Point.new(p2x, p2y) << Point.new(p3x, p3y)
      else
        curve_to(p1x, p1y, p2x, p2y, p3x, p3y)
      end
    end

    # Flatten ellipse into polygon using angular sampling (replaces Java Ellipse2D PathIterator)
    private def flatten_ellipse(left : Float64, bottom : Float64, right : Float64, top : Float64) : Array(Point)
      rx = (right - left).abs / 2.0
      ry = (top - bottom).abs / 2.0
      cx = (left + right) / 2.0
      cy = (bottom + top) / 2.0
      flatness = 0.50
      # Number of segments based on perimeter approximation
      perimeter = Math::PI * (3.0 * (rx + ry) - Math.sqrt((3.0 * rx + ry) * (rx + 3.0 * ry)))
      n = Math.max(4, (perimeter / flatness).ceil.to_i)
      points = Array(Point).new(n + 1)
      delta = 2.0 * Math::PI / n
      n.times do |i|
        angle = i * delta
        points << Point.new(cx + rx * Math.cos(angle), cy + ry * Math.sin(angle))
      end
      # Close: repeat first point if too far
      if points.size >= 2 && points.last.distance(points.first) > 0.05
        points << points.first.clone
      end
      points
    end

    private def cloudy_ellipse_impl(left_orig : Float64, bottom_orig : Float64,
                                    right_orig : Float64, top_orig : Float64) : Nil
      if @intensity <= 0.0
        draw_basic_ellipse(left_orig, bottom_orig, right_orig, top_orig)
        return
      end

      left = left_orig; bottom = bottom_orig; right = right_orig; top = top_orig
      width = right - left; height = top - bottom
      cloud_radius = get_ellipse_cloud_radius

      threshold1 = 0.50 * cloud_radius
      if width < threshold1 && height < threshold1
        draw_basic_ellipse(left, bottom, right, top)
        return
      end

      threshold2 = 5.0
      if (width < threshold2 && height > 20) || (width > 20 && height < threshold2)
        cloudy_rectangle_impl(left, bottom, right, top, true)
        return
      end

      radius_adj = Math.sin(ANGLE_12_DEG) * cloud_radius - 1.50
      if width > 2 * radius_adj
        left += radius_adj; right -= radius_adj
      else
        mid = (left + right) / 2
        left = mid - 0.10; right = mid + 0.10
      end
      if height > 2 * radius_adj
        top -= radius_adj; bottom += radius_adj
      else
        mid = (top + bottom) / 2
        top = mid + 0.10; bottom = mid - 0.10
      end

      flat_polygon = flatten_ellipse(left, bottom, right, top)
      num_points = flat_polygon.size
      return if num_points < 2

      tot_len = 0.0
      (1...num_points).each { |i| tot_len += flat_polygon[i - 1].distance(flat_polygon[i]) }

      k = Math.cos(ANGLE_34_DEG)
      curl_advance = 2 * k * cloud_radius
      n = (tot_len / curl_advance).ceil.to_i
      if n < 2
        draw_basic_ellipse(left_orig, bottom_orig, right_orig, top_orig)
        return
      end

      curl_advance = tot_len / n
      cloud_radius = curl_advance / (2 * k)

      if cloud_radius < 0.5
        cloud_radius = 0.5
        curl_advance = 2 * k * cloud_radius
      elsif cloud_radius < 3.0
        draw_basic_ellipse(left_orig, bottom_orig, right_orig, top_orig)
        return
      end

      # Build center points
      center_points = Array(Point).new(n)
      length_remain = 0.0
      comparison_toler = @line_width * 0.10

      (0...(num_points - 1)).each do |i|
        p1 = flat_polygon[i]; p2 = flat_polygon[i + 1]
        dx = p2.x - p1.x; dy = p2.y - p1.y
        length = p1.distance(p2)
        next if length == 0.0

        length_todo = length + length_remain
        if length_todo >= curl_advance - comparison_toler || i == num_points - 2
          cos_a = cosine(dx, length); sin_a = sine(dy, length)
          d = curl_advance - length_remain
          while length_todo >= curl_advance - comparison_toler
            x = p1.x + d * cos_a; y = p1.y + d * sin_a
            center_points << Point.new(x, y) if center_points.size < n
            length_todo -= curl_advance
            d += curl_advance
          end
          length_remain = Math.max(length_todo, 0.0)
        else
          length_remain += length
        end
      end

      # Place curls at center points
      num_cp = center_points.size
      angle_prev = 0.0; alpha_prev = 0.0
      num_cp.times do |i|
        idx_next = (i + 1 >= num_cp) ? 0 : i + 1
        pt = center_points[i]; pt_next = center_points[idx_next]
        if i == 0
          pt_prev = center_points[num_cp - 1]
          angle_prev = Math.atan2(pt.y - pt_prev.y, pt.x - pt_prev.x)
          alpha_prev = compute_params_ellipse(pt_prev, pt, cloud_radius, curl_advance)
        end
        angle_cur = Math.atan2(pt_next.y - pt.y, pt_next.x - pt.x)
        alpha = compute_params_ellipse(pt, pt_next, cloud_radius, curl_advance)
        add_corner_curl(angle_prev, angle_cur, cloud_radius, pt.x, pt.y, alpha, alpha_prev, !@output_started)
        angle_prev = angle_cur; alpha_prev = alpha
      end
    end

    private def compute_params_ellipse(pt : Point, pt_next : Point, r : Float64, curl_adv : Float64) : Float64
      length = pt.distance(pt_next)
      return ANGLE_34_DEG if length == 0.0
      e = length - curl_adv
      arg = (curl_adv / 2 + e / 2) / r
      (arg < -1.0 || arg > 1.0) ? 0.0 : Math.acos(arg)
    end

    private def remove_zero_length_segments(polygon : Array(Point)) : Array(Point)
      np = polygon.size
      return polygon if np <= 2

      toler = 0.50
      new_polygon = [polygon[0]]
      (1...np).each do |i|
        pt = polygon[i]
        prev = polygon[i - 1]
        unless (pt.x - prev.x).abs < toler && (pt.y - prev.y).abs < toler
          new_polygon << pt
        end
      end
      new_polygon
    end

    private def draw_basic_ellipse(left : Float64, bottom : Float64, right : Float64, top : Float64) : Nil
      rx = (right - left).abs / 2
      ry = (top - bottom).abs / 2
      cx = (left + right) / 2
      cy = (bottom + top) / 2
      get_arc(0, 2 * Math::PI, rx, ry, cx, cy, nil, true)
    end

    private def begin_pointsput(x : Float64, y : Float64) : Nil
      @bbox_min_x = x; @bbox_min_y = y
      @bbox_max_x = x; @bbox_max_y = y
      @output_started = true
      @output.line_join_style(2)
    end

    private def update_bbox(x : Float64, y : Float64) : Nil
      @bbox_min_x = Math.min(@bbox_min_x, x)
      @bbox_min_y = Math.min(@bbox_min_y, y)
      @bbox_max_x = Math.max(@bbox_max_x, x)
      @bbox_max_y = Math.max(@bbox_max_y, y)
    end

    private def move_to(pt : Point) : Nil
      move_to(pt.x, pt.y)
    end

    private def move_to(x : Float64, y : Float64) : Nil
      if @output_started
        update_bbox(x, y)
      else
        begin_pointsput(x, y)
      end
      @output.move_to(x.to_f32, y.to_f32)
    end

    private def line_to(pt : Point) : Nil
      line_to(pt.x, pt.y)
    end

    private def line_to(x : Float64, y : Float64) : Nil
      update_bbox(x, y) unless @output_started
      begin_pointsput(x, y) unless @output_started
      update_bbox(x, y)
      @output.line_to(x.to_f32, y.to_f32)
    end

    private def curve_to(ax : Float64, ay : Float64, bx : Float64, by : Float64, cx : Float64, cy : Float64) : Nil
      update_bbox(ax, ay); update_bbox(bx, by); update_bbox(cx, cy)
      @output.curve_to(ax.to_f32, ay.to_f32, bx.to_f32, by.to_f32, cx.to_f32, cy.to_f32)
    end

    private def finish : Nil
      @output.close_path if @output_started
      if @line_width > 0
        d = @line_width / 2
        @bbox_min_x -= d; @bbox_min_y -= d
        @bbox_max_x += d; @bbox_max_y += d
      end
    end

    private def get_ellipse_cloud_radius : Float64
      4.75 * @intensity + 0.5 * @line_width
    end

    private def get_polygon_cloud_radius : Float64
      4 * @intensity + 0.5 * @line_width
    end
  end
end
