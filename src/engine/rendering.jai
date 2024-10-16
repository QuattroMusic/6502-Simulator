draw_rect :: (pos: Vec2, size: Vec2, layer: f32, col: Col) {
	vert_count := cast(u32)quad_buffer.vertices_view.count;

	vertices_add(*quad_buffer, .{pos.x         , pos.y         , layer, col.data});
	vertices_add(*quad_buffer, .{pos.x + size.x, pos.y         , layer, col.data});
	vertices_add(*quad_buffer, .{pos.x + size.x, pos.y + size.y, layer, col.data});
	vertices_add(*quad_buffer, .{pos.x         , pos.y + size.y, layer, col.data});

	indices_add(*quad_buffer, vert_count + 1);
	indices_add(*quad_buffer, vert_count    );
	indices_add(*quad_buffer, vert_count + 2);
	indices_add(*quad_buffer, vert_count + 2);
	indices_add(*quad_buffer, vert_count    );
	indices_add(*quad_buffer, vert_count + 3);
}

draw_rect2 :: (pos: Vec2, size: Vec2, z: f32, col: Col) {
	vertices_add(*test_buffer, .{pos.x, pos.y, z, size.x, size.y, col.data});
}

draw_triangle :: (p1: Vec2, p2: Vec2, p3: Vec2, layer: f32, col: Col) {
	vert_count := cast(u32)quad_buffer.vertices_view.count;
	
	vertices_add(*quad_buffer, .{p1.x, p1.y, layer, col.data});
	vertices_add(*quad_buffer, .{p2.x, p2.y, layer, col.data});
	vertices_add(*quad_buffer, .{p3.x, p3.y, layer, col.data});
	
	indices_add(*quad_buffer, vert_count + 1);
	indices_add(*quad_buffer, vert_count    );
	indices_add(*quad_buffer, vert_count + 2);
}

draw_panel :: ($$text: string, pos: Vec2, size: Vec2, layer: f32) {
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

draw_rect_lines :: (pos: Vec2, size: Vec2, layer: f32, col: Col, t: f32 = 1) {
	draw_rect(pos, .{size.x, t}, layer, col);
	draw_rect(pos, .{t, size.y}, layer, col);
	draw_rect(pos + .{size.x - t, 0}, .{t, size.y}, layer, col);
	draw_rect(pos + .{0, size.y - t}, .{size.x, t}, layer, col);
}

draw_character :: ($$c: u8, pos: Vec2, layer: f32, scale: f32, color: Col) {
	#if is_constant(c) { #if c == #char " " || c == #char "\t" || c == #char "\r" then return; }
	else               {  if c == #char " " || c == #char "\t" || c == #char "\r" then return; }
	
	uv := get_char_mapping(c);
	vert_count := cast(u32)font_buffer.vertices_view.count;

	s := scale * 8.0;
	
	p1: Vec2 = pos;
	p2: Vec2 = pos + .{s, 0};
	p3: Vec2 = pos + .{s, s};
	p4: Vec2 = pos + .{0, s};
	
	uv_x :: 8.0 / texture_width;
	uv_y :: 8.0 / texture_height;

	vertices_add(*font_buffer, .{p1.x, p1.y, layer, color.data, .[uv.x       , uv.y       ]});
	vertices_add(*font_buffer, .{p2.x, p2.y, layer, color.data, .[uv.x + uv_x, uv.y       ]});
	vertices_add(*font_buffer, .{p3.x, p3.y, layer, color.data, .[uv.x + uv_x, uv.y + uv_y]});
	vertices_add(*font_buffer, .{p4.x, p4.y, layer, color.data, .[uv.x       , uv.y + uv_y]});
	
	indices_add(*font_buffer, vert_count + 1);
	indices_add(*font_buffer, vert_count    );
	indices_add(*font_buffer, vert_count + 2);
	indices_add(*font_buffer, vert_count + 2);
	indices_add(*font_buffer, vert_count    );
	indices_add(*font_buffer, vert_count + 3);
}

draw_character2 :: ($$c: u8, pos: Vec2, z: f32, scale: u32, col: Col) {
	#if is_constant(c) { #if c == #char " " || c == #char "\t" || c == #char "\r" then return; }
	else               {  if c == #char " " || c == #char "\t" || c == #char "\r" then return; }
	
	uv := get_char_mapping(c);
	vert_count := cast(u32)font_buffer.vertices_view.count;

	s := scale * 8;
	
	// p1: Vec2 = pos;
	// p2: Vec2 = pos + .{s, 0};
	// p3: Vec2 = pos + .{s, s};
	// p4: Vec2 = pos + .{0, s};
	
	uv_x :: 8.0 / texture_width;
	uv_y :: 8.0 / texture_height;

	// vertices_add(*font_buffer, .{p1.x, p1.y, z, color.data, .[uv.x       , uv.y       ]});
	// vertices_add(*font_buffer, .{p2.x, p2.y, z, color.data, .[uv.x + uv_x, uv.y       ]});
	// vertices_add(*font_buffer, .{p3.x, p3.y, z, color.data, .[uv.x + uv_x, uv.y + uv_y]});
	// vertices_add(*font_buffer, .{p4.x, p4.y, z, color.data, .[uv.x       , uv.y + uv_y]});
	
	// indices_add(*font_buffer, vert_count + 1);
	// indices_add(*font_buffer, vert_count    );
	// indices_add(*font_buffer, vert_count + 2);
	// indices_add(*font_buffer, vert_count + 2);
	// indices_add(*font_buffer, vert_count    );
	// indices_add(*font_buffer, vert_count + 3);
	vertices_add(*test_font_buffer, .{pos.x, pos.y, z, s, col.data, uv.component});
}

draw_text :: (text: string, pos: Vec2, layer: f32, scale: f32, color: Col, $wrap: f32 = 0) {
	x_pos: f32;
	y_pos: f32;

	uv_x :: 8.0 / texture_width;
	uv_y :: 8.0 / texture_height;

	s := 8.0 * scale;

	for cast([]u8) text {
		if it == #char "\n" {
			x_pos = 0;
			y_pos += s;
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

draw_icon :: (icon: Icon, pos: Vec2, layer: f32, $scale: f32, color: Col) {
	uv := get_icon_mapping(icon);

	vert_count := cast(u32)font_buffer.vertices_view.count;

	s :: 8.0 * scale;

	uv_x :: 8.0 / texture_width;
	uv_y :: 8.0 / texture_height;

	vertices_add(*font_buffer, .{pos.x    , pos.y    , layer, color.data, .[uv.x       , uv.y       ]});
	vertices_add(*font_buffer, .{pos.x + s, pos.y    , layer, color.data, .[uv.x + uv_x, uv.y       ]});
	vertices_add(*font_buffer, .{pos.x + s, pos.y + s, layer, color.data, .[uv.x + uv_x, uv.y + uv_y]});
	vertices_add(*font_buffer, .{pos.x    , pos.y + s, layer, color.data, .[uv.x       , uv.y + uv_y]});

	indices_add(*font_buffer, vert_count + 1);
	indices_add(*font_buffer, vert_count    );
	indices_add(*font_buffer, vert_count + 2);
	indices_add(*font_buffer, vert_count + 2);
	indices_add(*font_buffer, vert_count    );
	indices_add(*font_buffer, vert_count + 3);
}

get_icon_mapping :: (icon: Icon) -> (uv: Vec2) {
	if #complete icon == {
		case .REDUCE;      return #run Vec2.{64.0 / texture_width, 16.0 / texture_height};
		case .MINIMIZE;    return #run Vec2.{72.0 / texture_width, 16.0 / texture_height};
		case .MAXIMIZE;    return #run Vec2.{80.0 / texture_width, 16.0 / texture_height};
		case .CLOSE;       return #run Vec2.{88.0 / texture_width, 16.0 / texture_height};
	}
}

get_char_mapping :: ($$c: u8) -> (uv: Vec2) {
	// since the font is monospace, there's no need to return the size

	if c >= #char "a" && c <= #char "z" {
		x: f32 = ((c - #char "a") * 8.0) / texture_width;
		y: f32 = 0;
		return .{x, y};
	} else if c >= #char "A" && c <= #char "Z" {
		x: f32 = ((c - #char "A") * 8.0) / texture_width;
		y: f32 = 0;
		return .{x, y};
	} else if c >= #char "!" && c <= #char "@" {
		x: f32 = ((c - #char "!") * 8.0) / texture_width;
		y: f32 = 8.0 / texture_height;
		return .{x, y};
	} else if c >= #char "[" && c <= #char "`" {
		x: f32 = (208.0 + ((c - #char "[") * 8.0)) / texture_width;
		y: f32 = 0.0 / texture_height;
		return .{x, y};
	} else if c >= #char "{" && c <= #char "~" {
		x: f32 = ((c - #char "{") * 8.0) / texture_width;
		y: f32 = 16.0 / texture_height;
		return .{x, y};
	} else {
		x: f32 = 32.0 / texture_width;
		y: f32 = 16.0 / texture_height;
		return .{x, y};
	}
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
}

COLOR_WIDGET_BG_NORMAL      :: Col.{  73,  62,  51, 255 };
COLOR_WIDGET_BG_HOVERED     :: Col.{ 188, 126,  59, 255 };
COLOR_WIDGET_BG_PRESSED     :: Col.{ 246, 164,  76, 255 };
COLOR_WIDGET_BORDER_NORMAL  :: Col.{ 196, 126,  43, 255 };
COLOR_WIDGET_BORDER_HOVERED :: Col.{  49,  43,  40, 255 };
COLOR_WIDGET_BORDER_PRESSED :: Col.{  80,  77,  73, 255 };

COLOR_TEXT_NORMAL     :: Col.{ 246, 151,  48, 255 };
COLOR_TEXT_HOVERED    :: Col.{ 216, 210, 206, 255 };
COLOR_TEXT_PRESSED    :: Col.{ 104,  95,  93, 255 };

COLOR_BACKGROUND      :: Col.{  32,  30,  28, 255 };
COLOR_DEEP_BACKGROUND :: Col.{  10,  10,   5, 255 };

COLOR_LINE            :: Col.{ 254, 170,  55, 255 };
COLOR_DISABLED        :: Col.{  73,  85,  97, 255 };

WHITE  :: Col.{240, 240, 220, 255};
GREEN  :: Col.{ 59, 187,  20, 255};
RED    :: Col.{202,  45,  31, 255};
PURPLE :: Col.{130, 102, 193, 255};
ORANGE :: Col.{221, 119,  17, 255};
YELLOW :: Col.{238, 210,   5, 255};
PINK   :: Col.{255, 110, 199, 255};
GRAY   :: Col.{110, 110, 110, 255};
BLUE   :: Col.{ 64, 104, 200, 255};
AMBER  :: Col.{234, 191,  21, 255};
BLACK  :: Col.{ 12,  12,  12, 255};

DISPLAY_COLOR :: Col.[
	BLACK, WHITE, GRAY, RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE, PINK
];
