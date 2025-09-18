draw_rect :: inline (pos: Vec2, size: Vec2, col: Col) {
	uv :: #run FONT_SIZE_GRANULARITY * 8 / texture_width;
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
	
	do_range_check :: #ifx is_constant(c) then false else range_check;
	
	#if is_constant(c) {
		uv :: #run get_char_mapping(c, do_range_check);
	} else {
		uv := get_char_mapping(c, do_range_check);
	}

	element_add(*font_buffer, .{pos.x, pos.y, scale, scale, col.data, uv});
}

draw_text :: ($$text: string, pos: Vec2, scale: f32, color: Col, $wrap: f32 = 0, $range_check := true) {
	x_pos: f32;
	y_pos: f32;

	do_range_check :: #ifx is_constant(text) then false else range_check;

	for text {
		if it == #char "\n" {
			x_pos = 0;
			y_pos += scale;
			continue;
		}
		
		draw_character(cast,trunc(u8)it, pos + .{x_pos, y_pos}, scale, color, do_range_check);
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
		case .REDUCE;      return FONT_SIZE_GRANULARITY * 0 / texture_width;
		case .MINIMIZE;    return FONT_SIZE_GRANULARITY * 1 / texture_width;
		case .MAXIMIZE;    return FONT_SIZE_GRANULARITY * 2 / texture_width;
		case .CLOSE;       return FONT_SIZE_GRANULARITY * 3 / texture_width;
		case .ARROW_LEFT;  return FONT_SIZE_GRANULARITY * 4 / texture_width;
		case .ARROW_DOWN;  return FONT_SIZE_GRANULARITY * 5 / texture_width;
	}
}

get_char_mapping :: inline ($$c: u8, $range_check: bool) -> uvx: f32 {
	// since the font is monospace, there's no need to return the size
	// Todo - Quattro - check for unrecognized characters
	
	t :: FONT_SIZE_GRANULARITY / texture_width;

	#if range_check then char := clamp(c, 32, 127);
	else char := c;
	
	return char * t;
}

measure_text :: inline (text: string, scale: f32) -> Vec2 {
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
