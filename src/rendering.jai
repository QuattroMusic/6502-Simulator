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

draw_sprite :: () {
	vert_count := font_buffer.vertices_count;
	
	vertices_add(*font_buffer, .{0  ,  0, 0, .[1, 1, 1, 1], .[0, 0]});
	vertices_add(*font_buffer, .{16,   0, 0, .[1, 1, 1, 1], .[8.0 / texture_width, 0]});
	vertices_add(*font_buffer, .{16,  16, 0, .[1, 1, 1, 1], .[8.0 / texture_width, 1]});
	vertices_add(*font_buffer, .{0  , 16, 0, .[1, 1, 1, 1], .[0, 1]});
	
	indices_add(*font_buffer, vert_count + 1);
	indices_add(*font_buffer, vert_count    );
	indices_add(*font_buffer, vert_count + 2);
	indices_add(*font_buffer, vert_count + 2);
	indices_add(*font_buffer, vert_count    );
	indices_add(*font_buffer, vert_count + 3);
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
