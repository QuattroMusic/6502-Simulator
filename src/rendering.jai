draw_rect :: (pos: Vec2, size: Vec2, layer: float, col: Col) {
	vert_count := quad_buffer.vertices_count;
	
	vertices_add(*quad_buffer, .{pos.x         , pos.y         , 0, col.component});
	vertices_add(*quad_buffer, .{pos.x + size.x, pos.y         , 0, col.component});
	vertices_add(*quad_buffer, .{pos.x + size.x, pos.y + size.y, 0, col.component});
	vertices_add(*quad_buffer, .{pos.x         , pos.y + size.y, 0, col.component});
	
	indices_add(*quad_buffer, vert_count + 1);
	indices_add(*quad_buffer, vert_count    );
	indices_add(*quad_buffer, vert_count + 2);
	indices_add(*quad_buffer, vert_count + 2);
	indices_add(*quad_buffer, vert_count    );
	indices_add(*quad_buffer, vert_count + 3);
}

draw_text :: (text: string, pos: Vec2, scale: u32, color: Col) {
	x_pos: float;
	y_pos: float;
	
	uv_x := 8.0 / texture_width;
	uv_y := 8.0 / texture_height;
	
	s := 8.0 * scale;
	
	for cast([]u8) text {
		if it == #char " " {
			x_pos += s;
		} else if it == #char "\n" {
			x_pos = 0;
			y_pos += s;
		} else {
			uv := get_char_mapping(it);
			vert_count := font_buffer.vertices_count;
			
			vertices_add(*font_buffer, .{pos.x + x_pos    , pos.y + y_pos    , 0, color.component, .[uv.x       , uv.y       ]});
			vertices_add(*font_buffer, .{pos.x + x_pos + s, pos.y + y_pos    , 0, color.component, .[uv.x + uv_x, uv.y       ]});
			vertices_add(*font_buffer, .{pos.x + x_pos + s, pos.y + y_pos + s, 0, color.component, .[uv.x + uv_x, uv.y + uv_y]});
			vertices_add(*font_buffer, .{pos.x + x_pos    , pos.y + y_pos + s, 0, color.component, .[uv.x       , uv.y + uv_y]});

			indices_add(*font_buffer, vert_count + 1);
			indices_add(*font_buffer, vert_count    );
			indices_add(*font_buffer, vert_count + 2);
			indices_add(*font_buffer, vert_count + 2);
			indices_add(*font_buffer, vert_count    );
			indices_add(*font_buffer, vert_count + 3);
			x_pos += s;
		}
	}
}

get_char_mapping :: (c: u8) -> (uv: Vec2) {
	// since the font is monospace, we don't need to
	// return the size, it's always the same
	
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

draw_line :: () {}

draw_triangle :: () {}

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
