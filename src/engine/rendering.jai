draw_rect :: (pos: Vec2, size: Vec2, col: Col) {
	uv :: FONT_SIZE_GRANULARITY * 8 / texture_width;
	element_add(*font_buffer, .{pos.x, pos.y, size.x, size.y, col.data, uv});
}

draw_rect_lines :: (pos: Vec2, size: Vec2, col: Col, t: f32 = 1) {
	draw_rect(pos, .{size.x, t}, col);
	draw_rect(pos, .{t, size.y}, col);
	draw_rect(pos + .{size.x - t, 0}, .{t, size.y}, col);
	draw_rect(pos + .{0, size.y - t}, .{size.x, t}, col);
}

draw_character :: (c: u8, pos: Vec2, scale: f32, col: Col, range_check := true) {
	if c == #char " " || c == #char "\t" then return;
	
	uv := get_char_mapping(c, range_check);

	element_add(*font_buffer, .{pos.x, pos.y, scale, scale, col.data, uv});
}

draw_text :: (text: string, pos: Vec2, scale: f32, color: Col, $wrap: f32 = 0, range_check := true) {
	x_pos: f32;
	y_pos: f32;

	for text {
		if it == #char "\n" {
			x_pos = 0;
			y_pos += scale;
			continue;
		}
		
		draw_character(cast,trunc(u8)it, pos + .{x_pos, y_pos}, scale, color, range_check);
		x_pos += scale;
		
		#if wrap if x_pos + scale > wrap {
			x_pos = 0;
			y_pos += scale;
		}
	}
}

draw_icon :: (icon: Icon, pos: Vec2, scale: f32, col: Col) {
	uv := get_icon_mapping(icon);
	
	element_add(*font_buffer, .{pos.x, pos.y, scale, scale, col.data, uv});
}

get_icon_mapping :: (icon: Icon) -> uvx: f32 {
	if #complete icon == {
		case .REDUCE;      return FONT_SIZE_GRANULARITY * 0 / texture_width;
		case .MINIMIZE;    return FONT_SIZE_GRANULARITY * 1 / texture_width;
		case .MAXIMIZE;    return FONT_SIZE_GRANULARITY * 2 / texture_width;
		case .CLOSE;       return FONT_SIZE_GRANULARITY * 3 / texture_width;
		case .ARROW_LEFT;  return FONT_SIZE_GRANULARITY * 4 / texture_width;
		case .ARROW_DOWN;  return FONT_SIZE_GRANULARITY * 5 / texture_width;
	}
}

get_char_mapping :: (c: u8, range_check: bool) -> uvx: f32 {
	// since the font is monospace, there's no need to return the size
	// Todo - Quattro - check for unrecognized characters
	
	t :: FONT_SIZE_GRANULARITY / texture_width;

	char: u8 = ---;
	if range_check then char = clamp(c, 32, 127);
	else                char = c;
	
	return char * t;
}

measure_text :: (text: string, scale: f32) -> Vec2 {
	return .{text.count * scale, scale};
}

Icon :: enum {
	REDUCE;
	MINIMIZE;
	MAXIMIZE;
	CLOSE;
	ARROW_LEFT;
	ARROW_DOWN;
}
