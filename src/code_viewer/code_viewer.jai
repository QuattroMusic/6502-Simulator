get_width_of_line_count_bar :: () -> f32 {
	return (engine.cv.row_digits + 1.0) * 8 + 5;
}

handle_scrollbar :: () {
	pos := engine.cv.pos;
	size := engine.cv.size;
	amt := engine.cv.rows_length.count;
	
	if is_mouse_inside_rect(pos, size) {
		if mouse_dz {
			amt := mouse_dz * 16 * 3;
			engine.cv.scrollbar_pos -= amt;
		}
	}
	if is_mouse_pressed(0) && is_mouse_inside_rect(.{pos.x + size.x - 12, pos.y}, .{12, size.y}) {
		engine.cv.scrollbar_selected = true;
	}
	if engine.cv.scrollbar_selected {
		aspect_ratio := size.y / (size.y + 16 * amt);
		bar_height := aspect_ratio * size.y;
		engine.cv.scrollbar_pos = (mouse_y - pos.y - bar_height / 2) / aspect_ratio;
	}
	if is_mouse_released(0) {
		engine.cv.scrollbar_selected = false;
	}
	engine.cv.scrollbar_pos = clamp(round_up(engine.cv.scrollbar_pos, 16), 0, (amt - 1.0) * 16);
}

calculate_rows_length :: () {
	len: u32 = 0;
	
	for engine.cv.content {
		if it == #char "\n" {
			array_add(*engine.cv.rows_length, len);
			len = 0;
			continue;
		}
		len += 1;
	}
	array_add(*engine.cv.rows_length, len);
}

init_code_viewer :: (path: string) {
	engine.cv.file_name = path;
	
	// Todo - check if file exists
	file := file_open(path, for_writing = false);
	size := file_length(file);
	
	out := round_number_power_of_2(size);
	array_reserve(*engine.cv.content, size);
	
	file_read(file, engine.cv.content.data, size);
	engine.cv.content.count = size;
	
	file_close(*file);
	
	// Todo - remove '\t'
	
	calculate_rows_length();
	
	engine.cv.row_digits = count_digits(xx engine.cv.rows_length.count);
	
	init_code_viewer_coloring();
}
