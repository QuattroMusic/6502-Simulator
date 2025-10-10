init_code_editor :: (path: string) {
	data, success := read_entire_file(path);

	if !success {
		editor.content.count = 0;
		editor.file_name = "";
		display_error_window(.ERROR_OPENING_FILE, "error opening file");
		return;
	}

	editor.file_path = copy_string(path);
	editor.file_name = split_from_right(editor.file_path, #char "\\");

	editor.content.data      = data.data;
	editor.content.count     = data.count;
	editor.content.allocated = data.count;

	editor.caret_row = 0;
	editor.caret_col = 0;
	editor.caret_row_selection = 0;
	editor.caret_col_selection = 0;
	editor.scrollbar_pos = .{0, 0};

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

get_width_of_line_count_bar :: () -> f32 {
	// Todo - Quattro - robustness
	return (editor.row_digits + 1.0) * FONT_SIZE_SMALL + 5;
}

calculate_rows_length :: () {
	len: u32 = 0;
	longest_line: u32 = 0;
	longest_visually: u32 = 0;
	visually_longest_line: u32 = 0;

	it_index := 0;
	
	editor.rows_length.count = 0;
	
	while it_index < editor.content.count {
		it := editor.content[it_index];
		defer it_index += 1;
		
		if it == #char "\n" {
			array_add(*editor.rows_length, len);
			
			longest_line = max(longest_line, len);
			visually_longest_line = max(visually_longest_line, longest_visually);
			
			len = 0;
			longest_visually = 0;
			continue;
		} else if it == #char "\t" {
			longest_visually += 3;
		}
		
		len += 1;
		longest_visually += 1;
	}

	array_add(*editor.rows_length, len);
	editor.longest_line = longest_line;
	editor.visually_longest_line = visually_longest_line;
}

remove_bad_characters :: () {
	it_index := editor.content.count - 1;
	
	while it_index >= 0 {
		it := editor.content[it_index];
		defer it_index -= 1;
		
		if it == #char "\r" then array_ordered_remove_by_index(*editor.content, it_index);
	}
}

handle_dropped_file :: (file: string) {
	ext := split_from_right(file, #char ".");
	if ext != "s" {  // allow only '.s' as extension
		display_error_window(.GIVEN_FILE_NOT_VALID, "unsupported file");
		return;
	}

	deinit_code_editor();
	init_code_editor(file);

	if settings.platform.at_startup == .LAST_FILE {
		save_options_file();  // just to save the name of the file
	}
}

save_editor_file :: () {
	write_entire_file(editor.file_path, editor.content.data, editor.content.count);
	
	editor.save_animation_time = ms_since_init();
	editor.file_edited = false;
}
