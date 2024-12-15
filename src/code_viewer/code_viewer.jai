get_width_of_line_count_bar :: () -> f32 {
	return (viewer.row_digits + 1.0) * 8 + 5;
}

calculate_rows_length :: () {
	len: u32 = 0;
	longest_line: u32 = 0;
	
	for viewer.content {
		if it == #char "\n" {
			array_add(*viewer.rows_length, len);
			longest_line = max(longest_line, len);
			len = 0;
			continue;
		}
		len += 1;
	}
	array_add(*viewer.rows_length, len);
	viewer.longest_line = longest_line;
}

handle_displayed_file :: () {
	if !viewer.file_path then return;
	
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
			if seconds_since_init() - init > 1 {  // time out if operation took more than 1 second
				display_error_panel(.READING_FILE_TIMED_OUT, "timed out");
				deinit_code_viewer();
				return;
			}
		}
		
		t := copy_string(viewer.file_path,, allocator = temp);
		deinit_code_viewer();
		init_code_viewer(t);
	}
}

init_code_viewer :: (path: string) {
	viewer.file_path = copy_string(path);
	viewer.file_name = split_from_right(viewer.file_path, #char "\\");

	data, success := read_entire_file(path);
	
	modtime := file_modtime_and_size(path);
	viewer.file_modtime = modtime;
	
	if !success {
		viewer.content.count = 0;
		viewer.file_name = "";
		display_error_panel(.ERROR_OPENING_FILE, "error opening file");
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
	ext := split_from_right(file, #char ".");
	if ext != "s" {  // allow only '.s' as extension
		display_error_panel(.GIVEN_FILE_NOT_VALID, "unsupported file");
		return;
	}

	deinit_code_viewer();
	init_code_viewer(file);
	
	if settings.platform.at_startup == .OPEN_LAST_FILE {
		save_options_file();
	}
}
