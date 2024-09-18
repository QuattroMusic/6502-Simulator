#scope_file
Button_State :: enum {
	NORMAL;
	HOVER;
	PRESSED;
}

button_press :: (pos: Vec2, size: Vec2) -> (bool, Button_State) {
	state := Button_State.NORMAL;

	if is_mouse_inside_rect(pos, size) {
		state = .HOVER;
	}

	released := is_mouse_released(0);
	fire := false;
	if state == .HOVER && (is_mouse_down(0) || released) {
		state = .PRESSED;
		fire = released;
	}

	return fire, state;
}

button_internal :: (pos: Vec2, size: Vec2, layer: float, $t: float) -> (bool, Col) {
	fire, state := button_press(pos, size);

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

checkbox :: (value: *bool, $$text: string, pos: Vec2, size: Vec2, layer: float) {
	s := measure_text(text, 1);
	
	fire, state := button_press(pos, size + .{s.x + 12, 0});

	bg_col: Col;
	text_col: Col;
	if state == {
		case .NORMAL;
			bg_col = COLOR_TEXT_NORMAL;
			text_col = COLOR_TEXT_NORMAL;
		case .HOVER;
			bg_col = COLOR_TEXT_FOCUSED;
			text_col = COLOR_TEXT_FOCUSED;
		case .PRESSED;
			bg_col = COLOR_BASE_PRESSED;
			text_col = COLOR_TEXT_PRESSED;
	}
	
	if value.* || state == .PRESSED then draw_rect(pos + .{4, 4}, size - .{8, 8}, layer, bg_col);
	draw_rect_lines(pos, size, layer + 1, COLOR_LINE);
	draw_text(text, pos + .{size.x + 8, (size.y - s.y) / 2}, layer, 1, text_col);
	
	if fire then value.* = !value.*;
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
		case .LEFT_ARROW;  return .{208.0 / texture_width, 0.0 / texture_height};
		case .RIGHT_ARROW; return .{216.0 / texture_width, 0.0 / texture_height};
		case .REDUCE;      return .{224.0 / texture_width, 0.0 / texture_height};
		case .MINIMIZE;    return .{232.0 / texture_width, 0.0 / texture_height};
		case .MAXIMIZE;    return .{240.0 / texture_width, 0.0 / texture_height};
		case .CLOSE;       return .{248.0 / texture_width, 0.0 / texture_height};
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
	} else if c >= #char "!" && c <= #char "?" {
		x: float = ((c - #char "!") * 8.0) / texture_width;
		y: float = 8.0 / texture_height;
		return .{x, y};
	} else if c == #char "_" {
		x: float = 248.0 / texture_width;
		y: float = 8.0 / texture_height;
		return .{x, y};
	} else {
		assert(false, "unable to get mapping of character %", string.{1, *c});
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
	LEFT_ARROW;
	RIGHT_ARROW;
	REDUCE;
	MINIMIZE;
	MAXIMIZE;
	CLOSE;
}

// COLOR_BORDER_NORMAL   :: #run Col.{ 39, 116, 134, 255} / 255;
COLOR_BORDER_FOCUSED  :: #run Col.{130, 205, 224, 255} / 255;
COLOR_BORDER_PRESSED  :: #run Col.{235, 118,  48, 255} / 255;
COLOR_BORDER_DISABLED :: #run Col.{ 19,  75,  90, 255} / 255;
// COLOR_BASE_NORMAL     :: #run Col.{  2,  70,  88, 255} / 255;
// COLOR_BASE_FOCUSED    :: #run Col.{ 50, 153, 180, 255} / 255;
COLOR_BASE_PRESSED    :: #run Col.{255, 188,  81, 255} / 255;
COLOR_BASE_DISABLED   :: #run Col.{  2,  49,  61, 255} / 255;
// COLOR_TEXT_NORMAL     :: #run Col.{ 81, 191, 211, 255} / 255;
COLOR_TEXT_FOCUSED    :: #run Col.{182, 225, 234, 255} / 255;
COLOR_TEXT_PRESSED    :: #run Col.{216, 111,  54, 255} / 255;
COLOR_TEXT_DISABLED   :: #run Col.{ 23,  80,  95, 255} / 255;
// COLOR_LINE            :: #run Col.{129, 192, 208, 255} / 255;
// COLOR_BACKGROUND      :: #run Col.{  0,  34,  43, 255} / 255;
// COLOR_DEEP_BACKGROUND :: #run Col.{ 10,  10,  10, 255} / 255;

COLOR_BORDER_NORMAL   :: #run Col.{ 202, 128, 35, 255} / 255;
COLOR_BASE_NORMAL     :: #run Col.{  50,  50, 50, 255} / 255;
COLOR_BASE_FOCUSED    :: #run Col.{ 202, 128, 35, 255} / 255;
COLOR_TEXT_NORMAL     :: #run Col.{ 246, 151, 48, 255} / 255;
COLOR_LINE            :: #run Col.{ 254, 170, 55, 255} / 255;
COLOR_BACKGROUND      :: #run Col.{  30,  30, 30, 255} / 255;
COLOR_DEEP_BACKGROUND :: #run Col.{  10,  10,  5, 255} / 255;

WHITE  :: #run Col.{240, 240, 240, 255} / 255;
GREEN  :: #run Col.{ 35, 210,  30, 255} / 255;
RED    :: #run Col.{210,  35,  30, 255} / 255;
PURPLE :: #run Col.{130, 102, 193, 255} / 255;
BLUE   :: #run Col.{ 20,  90, 210, 255} / 255;
// ORANGE :: #run Col.{255, 123,  10, 255} / 255;
ORANGE :: #run Col.{221, 119, 17, 255} / 255;
YELLOW :: #run Col.{238, 210,   5, 255} / 255;
PINK   :: #run Col.{255, 110, 199, 255} / 255;
GRAY   :: #run Col.{110, 110, 110, 255} / 255;
BLUE2 :: #run Col.{64, 104, 200, 255} / 255;
AMBER :: #run Col.{234, 191, 21, 255} / 255;
PURPLE2 :: #run Col.{130, 102, 193, 255} / 255;
