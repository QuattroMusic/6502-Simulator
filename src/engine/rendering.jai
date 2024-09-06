#scope_file
button_internal :: (pos: Vec2, size: Vec2, layer: float, $t: float) -> (bool, Col) {
	Button_State :: enum {
		NORMAL;
		HOVER;
		PRESSED;
	}
	state := Button_State.NORMAL;

	if is_mouse_over_rect(pos, size) {
		state = .HOVER;
	}

	released := is_mouse_released(0);
	fire := false;
	if state == .HOVER && (is_mouse_down(0) || released) {
		state = .PRESSED;
		fire = released;
	}

	bg_col: Col;
	border_col: Col;
	text_col: Col;
	if state == {
		case .NORMAL;
			bg_col = COLOR_BASE_NORMAL;
			border_col = COLOR_BORDER_NORMAL;
			text_col = COLOR_TEXT_NORMAL;
		case .HOVER;
			bg_col = COLOR_BASE_FOCUSED;
			border_col = COLOR_BORDER_FOCUSED;
			text_col = COLOR_TEXT_FOCUSED;
		case .PRESSED;
			bg_col = COLOR_BASE_PRESSED;
			border_col = COLOR_BORDER_PRESSED;
			text_col = COLOR_TEXT_PRESSED;
	}

	draw_rect(pos, size, layer, bg_col);
	draw_rect_lines(pos, size, layer + 1, border_col, 2);

	return fire, text_col;
}

#scope_export
draw_rect :: (pos: Vec2, size: Vec2, layer: float, col: Col) {
	vert_count := quad_buffer.vertices_count;

	vertices_add(*quad_buffer, .{pos.x         , pos.y         , layer, col.component});
	vertices_add(*quad_buffer, .{pos.x + size.x, pos.y         , layer, col.component});
	vertices_add(*quad_buffer, .{pos.x + size.x, pos.y + size.y, layer, col.component});
	vertices_add(*quad_buffer, .{pos.x         , pos.y + size.y, layer, col.component});

	indices_add(*quad_buffer, vert_count + 1);
	indices_add(*quad_buffer, vert_count    );
	indices_add(*quad_buffer, vert_count + 2);
	indices_add(*quad_buffer, vert_count + 2);
	indices_add(*quad_buffer, vert_count    );
	indices_add(*quad_buffer, vert_count + 3);
}

draw_panel :: ($$text: string, pos: Vec2, size: Vec2, layer: float) {
	p :: 4;

	draw_rect(pos, .{p, 1}, layer, COLOR_LINE);
	draw_rect(pos, .{1, size.y}, layer, COLOR_LINE);
	draw_rect(pos + .{0, size.y - 1}, .{size.x, 1}, layer, COLOR_LINE);
	draw_rect(pos + .{size.x - 1, 0}, .{1, size.y}, layer, COLOR_LINE);

	s :: 1;
	m := measure_text(text, s);
	draw_text(text, pos + .{p + 4, -m.y / 2}, layer, s, COLOR_LINE);

	draw_rect(pos + .{p + 8 + m.x, 0}, .{size.x - p - 8 - m.x, 1}, layer, COLOR_LINE);
}

draw_rect_lines :: (pos: Vec2, size: Vec2, layer: float, col: Col, t: float = 1) {
	draw_rect(pos, .{size.x, t}, layer, col);
	draw_rect(pos, .{t, size.y}, layer, col);
	draw_rect(pos + .{size.x - t, 0}, .{t, size.y}, layer, col);
	draw_rect(pos + .{0, size.y - t}, .{size.x, t}, layer, col);
}

button :: ($$text: string, pos: Vec2, size: Vec2, layer: float, $t: float) -> bool {
	fire, text_col := button_internal(pos, size, layer, t);
	
	s := measure_text(text, t);
	draw_text(text, pos + size / 2 - s / 2, layer + 1, t, text_col);
	
	return fire;
}

button :: (icon: Icon, pos: Vec2, size: Vec2, layer: float, $t: float) -> bool {
	fire, icon_col := button_internal(pos, size, layer, t);
	
	s :: Vec2.{8.0 * t, 8.0 * t};
	
	draw_icon(icon, pos + size / 2 - s / 2, layer + 1, t, icon_col);
	return fire;
}

draw_text :: (text: string, pos: Vec2, layer: float, scale: float, color: Col) {
	x_pos: float;
	y_pos: float;

	uv_x := 8.0 / texture_width;
	uv_y := 8.0 / texture_height;

	s := 8.0 * scale;

	for cast([]u8) text {
		if it == #char "\n" {
			x_pos = 0;
		} else if it != #char " " {
			uv := get_char_mapping(it);
			vert_count := font_buffer.vertices_count;

			vertices_add(*font_buffer, .{pos.x + x_pos    , pos.y + y_pos    , layer, color.component, .[uv.x       , uv.y       ]});
			vertices_add(*font_buffer, .{pos.x + x_pos + s, pos.y + y_pos    , layer, color.component, .[uv.x + uv_x, uv.y       ]});
			vertices_add(*font_buffer, .{pos.x + x_pos + s, pos.y + y_pos + s, layer, color.component, .[uv.x + uv_x, uv.y + uv_y]});
			vertices_add(*font_buffer, .{pos.x + x_pos    , pos.y + y_pos + s, layer, color.component, .[uv.x       , uv.y + uv_y]});

			indices_add(*font_buffer, vert_count + 1);
			indices_add(*font_buffer, vert_count    );
			indices_add(*font_buffer, vert_count + 2);
			indices_add(*font_buffer, vert_count + 2);
			indices_add(*font_buffer, vert_count    );
			indices_add(*font_buffer, vert_count + 3);
		}
		x_pos += s;
	}
}

draw_icon :: (icon: Icon, pos: Vec2, layer: float, $scale: float, color: Col) {
	uv := get_icon_mapping(icon);

	vert_count := font_buffer.vertices_count;

	s :: 8.0 * scale;

	uv_x := 8.0 / texture_width;
	uv_y := 8.0 / texture_height;

	vertices_add(*font_buffer, .{pos.x    , pos.y    , layer, color.component, .[uv.x       , uv.y       ]});
	vertices_add(*font_buffer, .{pos.x + s, pos.y    , layer, color.component, .[uv.x + uv_x, uv.y       ]});
	vertices_add(*font_buffer, .{pos.x + s, pos.y + s, layer, color.component, .[uv.x + uv_x, uv.y + uv_y]});
	vertices_add(*font_buffer, .{pos.x    , pos.y + s, layer, color.component, .[uv.x       , uv.y + uv_y]});

	indices_add(*font_buffer, vert_count + 1);
	indices_add(*font_buffer, vert_count    );
	indices_add(*font_buffer, vert_count + 2);
	indices_add(*font_buffer, vert_count + 2);
	indices_add(*font_buffer, vert_count    );
	indices_add(*font_buffer, vert_count + 3);
}

get_icon_mapping :: (icon: Icon) -> (uv: Vec2) {
	if #complete icon == {
		case .REDUCE;   return .{176.0 / texture_width, 8.0 / texture_height};
		case .MINIMIZE; return .{184.0 / texture_width, 8.0 / texture_height};
		case .MAXIMIZE; return .{192.0 / texture_width, 8.0 / texture_height};
		case .CLOSE;    return .{200.0 / texture_width, 8.0 / texture_height};
	}
}

get_char_mapping :: (c: u8) -> (uv: Vec2) {
	// since the font is monospace, we don't need to return the size, it's always the same

	if c >= #char "a" && c <= #char "z" {
		x: float = ((c - #char "a") * 8.0) / texture_width;
		y: float = 0;
		return .{x, y};
	} else if c >= #char "A" && c <= #char "Z" {
		x: float = ((c - #char "A") * 8.0) / texture_width;
		y: float = 0;
		return .{x, y};
	} else if c >= #char "0" && c <= #char "9" {
		x: float = ((c - #char "0") * 8.0) / texture_width;
		y: float = 8.0 / texture_height;
		return .{x, y};
	} else {
		assert(false);
	}
	return .{0, 0};
}

measure_text :: ($$text: string, $scale: float) -> Vec2 {
	_internal :: (t: string, s: float) -> Vec2 {
		w: float;
		max_w: float;
		h: float = 8.0 * s;
		for cast([]u8) t {
			if it == #char "\n" {
				max_w = max(w, max_w);
				w = 0;
				h += 8.0 * s;
			} else {
				w += 8.0 * s;
			}
		}
		return .{max(w, max_w), h};
	}

	#if is_constant(text) { return #run _internal(text, scale); }
	else                  { return      _internal(text, scale); }
}

Icon :: enum {
	REDUCE;
	MINIMIZE;
	MAXIMIZE;
	CLOSE;
}

COLOR_BORDER_NORMAL   :: #run Col.{ 39, 116, 134, 255} / 255;
COLOR_BORDER_FOCUSED  :: #run Col.{130, 205, 224, 255} / 255;
COLOR_BORDER_PRESSED  :: #run Col.{235, 118,  48, 255} / 255;
COLOR_BORDER_DISABLED :: #run Col.{ 19,  75,  90, 255} / 255;
COLOR_BASE_NORMAL     :: #run Col.{  2,  70,  88, 255} / 255;
COLOR_BASE_FOCUSED    :: #run Col.{ 50, 153, 180, 255} / 255;
COLOR_BASE_PRESSED    :: #run Col.{255, 188,  81, 255} / 255;
COLOR_BASE_DISABLED   :: #run Col.{  2,  49,  61, 255} / 255;
COLOR_TEXT_NORMAL     :: #run Col.{ 81, 191, 211, 255} / 255;
COLOR_TEXT_FOCUSED    :: #run Col.{182, 225, 234, 255} / 255;
COLOR_TEXT_PRESSED    :: #run Col.{216, 111,  54, 255} / 255;
COLOR_TEXT_DISABLED   :: #run Col.{ 23,  80,  95, 255} / 255;
COLOR_LINE            :: #run Col.{129, 192, 208, 255} / 255;
COLOR_BACKGROUND      :: #run Col.{  0,  34,  43, 255} / 255;
COLOR_DEEP_BACKGROUND :: #run Col.{ 10,  10,  10, 255} / 255;

WHITE :: Col.{1, 1, 1, 1};
