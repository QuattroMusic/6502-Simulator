init_code_editor :: (path: string) {
	data, success := read_entire_file(path);

	if !success {
		editor.content.count = 0;
		editor.file_name = "";
		display_error_panel(.ERROR_OPENING_FILE, "error opening file");
		return;
	}

	editor.file_path = copy_string(path);
	editor.file_name = split_from_right(editor.file_path, #char "\\");

	editor.content.data      = data.data;
	editor.content.count     = data.count;
	editor.content.allocated = data.count;

	remove_bad_characters();

	calculate_rows_length();

	editor.row_digits = count_digits(xx editor.rows_length.count);

	init_code_editor_coloring();
}

deinit_code_editor :: () {
	array_reset(*editor.rows_length);
	array_reset(*editor.content);
	free(editor.file_path);
	deinit_code_editor_coloring();
}

handle_displayed_file :: () {
	// Todo - Quattro - change from polling to File_Wiewer
	// if !viewer.file_path then return;

	// modtime := file_modtime_and_size(viewer.file_path);

	// if compare_apollo_times(modtime, viewer.file_modtime) {
		// viewer.file_modtime = modtime;

		// init := seconds_since_init();

		// while true {
			// file, success := file_open(viewer.file_path);
			// if success {
				// file_close(*file);
				// break;
			// }
			// if seconds_since_init() - init > 1 {  // time out if operation took more than 1 second
				// display_error_panel(.READING_FILE_TIMED_OUT, "timed out");
				// deinit_code_viewer();
				// return;
			// }
		// }

		// t := copy_string(viewer.file_path,, allocator = temp);
		// deinit_code_viewer();
		// init_code_viewer(t);
	// }
}

get_width_of_line_count_bar :: () -> f32 {
	return (editor.row_digits + 1.0) * 8 + 5;
}

calculate_rows_length :: () {
	len: u32 = 0;
	longest_line: u32 = 0;

	it_index := 0;
	
	while it_index < editor.content.count {
		it := editor.content[it_index];
		defer it_index += 1;
		
		if it == #char "\n" {
			array_add(*editor.rows_length, len);
			longest_line = max(longest_line, len);
			len = 0;
			continue;
		}
		
		len += 1;
	}

	array_add(*editor.rows_length, len);
	editor.longest_line = longest_line;
}

remove_bad_characters :: () {
	it_index := 0;
	
	while it_index < editor.content.count {
		it := editor.content[it_index];
		defer it_index += 1;
		
		if it == #char "\r" {
			array_ordered_remove_by_index(*editor.content, it_index);
		}
	}
}

handle_dropped_file :: (file: string) {
	ext := split_from_right(file, #char ".");
	if ext != "s" {  // allow only '.s' as extension
		display_error_panel(.GIVEN_FILE_NOT_VALID, "unsupported file");
		return;
	}

	deinit_code_editor();
	init_code_editor(file);

	if settings.platform.at_startup == .LAST_FILE {
		save_options_file();  // just to save the name of the file
	}
}
