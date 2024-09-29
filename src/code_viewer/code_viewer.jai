get_width_of_line_count_bar :: () -> f32 {
	return (viewer.row_digits + 1.0) * 8 + 5;
}

handle_scrollbar :: () {
	pos := viewer.pos;
	size := viewer.size;
	amt := viewer.rows_length.count;
	
	if is_mouse_inside_rect(pos, size) {
		if mouse_dz && !ui.show_popup {
			amt := mouse_dz * 16 * 3;
			viewer.scrollbar_pos -= amt;
		}
	}
	if is_mouse_pressed(0) && can_interact_with_widget(0) && is_mouse_inside_rect(.{pos.x + size.x - 12, pos.y}, .{12, size.y}) {
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

handle_displayed_file :: () {
	if viewer.file_path {
		modtime := file_modtime_and_size(viewer.file_path);
		
		if compare_apollo_times(modtime, viewer.file_modtime) {
			viewer.file_modtime = modtime;
			
			init := seconds_since_init();
			
			while true {
				file, success := file_open(viewer.file_path);
				if success {
					file_close(*file);
					break;
				}
				if seconds_since_init() - init > 1 {
					ui.show_popup = true;
					ui.popup_title = "timed out";
					ui.popup_error_type = .READING_FILE_TIMED_OUT;
					deinit_code_viewer();
					return;
				}
			}
			
			t := copy_string(viewer.file_path,, allocator = temp);
			deinit_code_viewer();
			init_code_viewer(t);
		}
	}
}

init_code_viewer :: (path: string) {
	viewer.file_path = copy_string(path);
	viewer.file_name = split_from_right(viewer.file_path, #char "\\");

	data, success := read_entire_file(path);
	
	modtime := file_modtime_and_size(path);
	viewer.file_modtime = modtime;
	
	if !success {
		ui.show_popup = true;
		ui.popup_title = "error opening file";
		ui.popup_error_type = .ERROR_OPENING_FILE;
		viewer.content.count = 0;
		viewer.file_name = "";
		return;
	}
	viewer.content.data = data.data;
	viewer.content.count = data.count;

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
