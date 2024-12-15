draw_rect :: inline (pos: Vec2, size: Vec2, z: f32, col: Col) {
	element_add(*quad_buffer, .{floor(pos.x), floor(pos.y), z, floor(size.x), floor(size.y), col.data});
}

draw_color_picker_rect :: inline (pos: Vec2, size: Vec2, z: f32, v: f32) {
	element_add(*spec_buffer, .{floor(pos.x), floor(pos.y), z, floor(size.x), floor(size.x), v});
}

draw_rect :: inline (pos: Vec2, size: Vec2, z: f32, c1: Col, c2: Col, c3: Col, c4: Col) {
	element_add(*flex_buffer, .{floor(pos.x), floor(pos.y), z, floor(size.x), floor(size.y), c1.data, c2.data, c3.data, c4.data});
}

draw_panel :: ($$text: string, pos: Vec2, size: Vec2, layer: f32) {
	p :: 4;

	draw_rect(pos, .{p, 1}, layer, settings.themes.platform_line);
	draw_rect(pos, .{1, size.y}, layer, settings.themes.platform_line);
	draw_rect(pos + .{0, size.y - 1}, .{size.x, 1}, layer, settings.themes.platform_line);
	draw_rect(pos + .{size.x - 1, 0}, .{1, size.y}, layer, settings.themes.platform_line);

	s :: 1;
	m := measure_text(text, s);
	draw_text(text, pos + .{p + 4, -m.y / 2}, layer, s, settings.themes.platform_line);

	draw_rect(pos + .{p + 8 + m.x, 0}, .{size.x - p - 8 - m.x, 1}, layer, settings.themes.platform_line);
}

draw_rect_lines :: (pos: Vec2, size: Vec2, layer: f32, col: Col, t: f32 = 1) {
	draw_rect(pos, .{size.x, t}, layer, col);
	draw_rect(pos, .{t, size.y}, layer, col);
	draw_rect(pos + .{size.x - t, 0}, .{t, size.y}, layer, col);
	draw_rect(pos + .{0, size.y - t}, .{size.x, t}, layer, col);
}

draw_character :: ($$c: u8, pos: Vec2, layer: f32, scale: f32, col: Col) {
	#if is_constant(c) { #if c == #char " " || c == #char "\t" || c == #char "\r" then return; }
	else               {  if c == #char " " || c == #char "\t" || c == #char "\r" then return; }
	
	uv := get_char_mapping(c);

	s := scale * 8;
	
	element_add(*font_buffer, .{floor(pos.x), floor(pos.y), layer, xx s, col.data, uv});
}

draw_text :: (text: string, pos: Vec2, layer: f32, scale: f32, color: Col, $wrap: f32 = 0) {
	x_pos: f32;
	y_pos: f32;

	s := 8.0 * scale;

	for cast([]u8) text {
		if it == #char "\n" {
			x_pos = 0;
			y_pos += s;
			continue;
		} else if it != #char " " && it != #char "\t" && it != #char "\r" {
			draw_character(cast,trunc(u8)it, pos + .{x_pos, y_pos}, layer, scale, color);
		}
		
		x_pos += s;
		#if wrap if x_pos + s > wrap {
			x_pos = 0;
			y_pos += s;
		}
	}
}

draw_icon :: (icon: Icon, pos: Vec2, layer: f32, $scale: f32, col: Col) {
	uv := get_icon_mapping(icon);

	s :: 8.0 * scale;

	element_add(*font_buffer, .{floor(pos.x), floor(pos.y), layer, xx s, col.data, uv});
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

get_char_mapping :: inline ($$c: u8) -> uvx: f32 {
	// since the font is monospace, there's no need to return the size
	char := clamp(c, 32, 127);
	return 8.0 * char / texture_width;
}

measure_text :: ($$text: string, $scale: f32) -> Vec2 {
	_internal :: (t: string, s: f32) -> Vec2 {
		w: f32;
		max_w: f32;
		h: f32 = 8.0 * s;
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
	ARROW_LEFT;
	ARROW_DOWN;
}
