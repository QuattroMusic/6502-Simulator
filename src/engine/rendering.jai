draw_rect :: inline (pos: Vec2, size: Vec2, col: Col) {
	uv :: #run 8.0 * 8 / texture_width;
	element_add(*font_buffer, .{pos.x, pos.y, size.x, size.y, col.data, uv});
}

draw_rect_lines :: (pos: Vec2, size: Vec2, col: Col, t: f32 = 1) {
	draw_rect(pos, .{size.x, t}, col);
	draw_rect(pos, .{t, size.y}, col);
	draw_rect(pos + .{size.x - t, 0}, .{t, size.y}, col);
	draw_rect(pos + .{0, size.y - t}, .{size.x, t}, col);
}

draw_character :: inline ($$c: u8, pos: Vec2, scale: f32, col: Col, $range_check := true) {
	#if is_constant(c) { #if c == #char " " || c == #char "\t" || c == #char "\r" then return; }
	else               {  if c == #char " " || c == #char "\t" || c == #char "\r" then return; }
	
	#if is_constant(c) {
		uv :: #run get_char_mapping(c, range_check);
	} else {
		uv := get_char_mapping(c, range_check);
	}

	element_add(*font_buffer, .{pos.x, pos.y, scale, scale, col.data, uv});
} @NoProfile

draw_text :: (text: string, pos: Vec2, scale: f32, color: Col, $wrap: f32 = 0, $range_check := true) {
	x_pos: f32;
	y_pos: f32;

	for text {
		draw_character(cast,trunc(u8)it, pos + .{x_pos, y_pos}, scale, color, range_check);
		x_pos += scale;
		
		#if wrap if x_pos + scale > wrap {
			x_pos = 0;
			y_pos += scale;
		}
	}
}

draw_icon :: ($$icon: Icon, pos: Vec2, $scale: f32, col: Col) {
	#if is_constant(icon) {
		uv :: #run get_icon_mapping(icon);
	} else {
		uv := get_icon_mapping(icon);
	}
	
	element_add(*font_buffer, .{pos.x, pos.y, scale, scale, col.data, uv});
}

get_icon_mapping :: (icon: Icon) -> uvx: f32 {
	if #complete icon == {
		case .REDUCE;      return #run  0.0 / texture_width;
		case .MINIMIZE;    return #run  8.0 / texture_width;
		case .MAXIMIZE;    return #run 16.0 / texture_width;
		case .CLOSE;       return #run 24.0 / texture_width;
		case .ARROW_LEFT;  return #run 32.0 / texture_width;
		case .ARROW_DOWN;  return #run 40.0 / texture_width;
	}
}

get_char_mapping :: inline ($$c: u8, $range_check: bool) -> uvx: f32 {
	// since the font is monospace, there's no need to return the size
	// Todo - Quattro - check for unrecognized characters
	
	t :: #run FONT_SIZE_GRANULARITY / texture_width;

	#if range_check then char := clamp(c, 32, 127);
	else char := c;
	
	return char * t;
} @NoProfile

measure_text :: ($$text: string, $scale: f32) -> Vec2 {
	_internal :: (t: string, s: f32) -> Vec2 {
		w: f32;
		max_w: f32;
		h: f32 = s;
		
		for t {
			if it == #char "\n" {
				max_w = max(w, max_w);
				w = 0;
				h += s;
			} else {
				w += s;
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
	ARROW_LEFT;
	ARROW_DOWN;
}
