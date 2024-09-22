get_width_of_line_count_bar :: () -> f32 {
	return (viewer.row_digits + 1.0) * 8 + 5;
}

handle_scrollbar :: () {
	pos := viewer.pos;
	size := viewer.size;
	amt := viewer.rows_length.count;
	
	if is_mouse_inside_rect(pos, size) {
		if mouse_dz {
			amt := mouse_dz * 16 * 3;
			viewer.scrollbar_pos -= amt;
		}
	}
	if is_mouse_pressed(0) && is_mouse_inside_rect(.{pos.x + size.x - 12, pos.y}, .{12, size.y}) {
		viewer.scrollbar_selected = true;
	}
	if viewer.scrollbar_selected {
		aspect_ratio := size.y / (size.y + 16 * amt);
		bar_height := aspect_ratio * size.y;
		viewer.scrollbar_pos = (mouse_y - pos.y - bar_height / 2) / aspect_ratio;
	}
	if is_mouse_released(0) {
		viewer.scrollbar_selected = false;
	}
	viewer.scrollbar_pos = clamp(round_up(viewer.scrollbar_pos, 16), 0, (amt - 1.0) * 16);
}

calculate_rows_length :: () {
	len: u32 = 0;
	
	for viewer.content {
		if it == #char "\n" {
			array_add(*viewer.rows_length, len);
			len = 0;
			continue;
		}
		len += 1;
	}
	array_add(*viewer.rows_length, len);
}

init_code_viewer :: (path: string) {
	viewer.file_path = copy_string(path);
	viewer.file_name = split_from_right(viewer.file_path, #char "\\");

	// Todo - maybe check if file exists
	file := file_open(path, for_writing = false);
	size := file_length(file);
	
	out := round_number_power_of_2(size);
	array_reserve(*viewer.content, size);
	
	file_read(file, viewer.content.data, size);
	viewer.content.count = size;
	
	file_close(*file);
	
	// Todo - remove '\t', or find a way to implement them
	
	calculate_rows_length();
	
	viewer.row_digits = count_digits(xx viewer.rows_length.count);
	
	init_code_viewer_coloring();
}

deinit_code_viewer :: () {
	array_reset(*viewer.rows_length);
	array_reset(*viewer.content);
	free(viewer.file_path);
	deinit_code_viewer_coloring();
}

handle_dropped_file :: (file: string) {
	deinit_code_viewer();
	init_code_viewer(file);
}
