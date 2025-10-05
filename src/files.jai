init_settings :: () {
	init_theming();
	init_options();
}

save_theme_file :: () {
	file, success := file_open(get_asset_path(THEME_FILE_NAME), for_writing = true, keep_existing_content = false);
	assert(success, "An error occurred while saving the theme file");  // Todo - handle better error messages
	
	write_theme_content(*file);
	
	file_close(*file);
}

save_options_file :: () {
	file, success := file_open(get_asset_path(SETTINGS_FILE_NAME), for_writing = true, keep_existing_content = false);
	assert(success, "An error occurred while saving the settings file");  // Todo - handle better error messages
	
	write_options_content(*file);
	
	file_close(*file);
}

get_asset_path :: (file: string) -> string {
	return tprint("%/%", DATA_FOLDER_NAME, file);
}

#scope_file
init_options :: () {
	success := file_exists(get_asset_path(SETTINGS_FILE_NAME));
	
	if !success {
		file, success := file_open(get_asset_path(SETTINGS_FILE_NAME), for_writing = true, keep_existing_content = false);
		assert(success, "An error occurred while saving settings file");  // Todo - handle better error messages
		
		write_options_content(*file);
		
		file_close(*file);
		return;
	}
	
	parse_options_file();
}

init_theming :: () {
	success := file_exists(get_asset_path(THEME_FILE_NAME));
	
	if !success {
		file, success := file_open(get_asset_path(THEME_FILE_NAME), for_writing = true, keep_existing_content = false);
		assert(success, "An error occurred while saving theme file");  // Todo - handle better error messages
		
		write_theme_content(*file);
		
		file_close(*file);
		return;
	}
	
	parse_theme_file();
}

setup_file_header :: (f: *File) {
	// must to be variables for pointers reasons
	maj_version := APP_MAJOR_VERSION;
	min_version := APP_MINOR_VERSION;
	file_write(f, *maj_version, 1);
	file_write(f, *min_version, 2);
}

get_file_header :: (f: *File) -> (maj: u8, min: u16) {
	maj_version: u8  = ---;
	min_version: u16 = ---;
	
	file_read(f, *maj_version, 1);
	file_read(f, *min_version, 2);
	
	return maj_version, min_version;
}

write_options_content :: (file: *File) {
	setup_file_header(file);
	
	p := settings.platform;
	e := settings.editor;
	
	file_write(file, *p.at_startup, size_of(type_of(p.at_startup)));
	if(p.at_startup == .LAST_FILE) {
		file_write(file, *editor.file_path.count, size_of(type_of(editor.file_path.count)));
		file_write(file,  editor.file_path.data, editor.file_path.count);
	}
	
	file_write(file, *p.code_cursor_speed_slow,   size_of(type_of(p.code_cursor_speed_slow)));
	file_write(file, *p.code_cursor_speed_fast,   size_of(type_of(p.code_cursor_speed_fast)));
	file_write(file, *p.memory_cursor_speed_slow, size_of(type_of(p.memory_cursor_speed_slow)));
	file_write(file, *p.memory_cursor_speed_fast, size_of(type_of(p.memory_cursor_speed_fast)));
	
	file_write(file, *e.when_to_save, size_of(type_of(e.when_to_save)));
	file_write(file, *e.save_interval_in_ms, size_of(type_of(e.save_interval_in_ms)));
	file_write(file, *e.lock_content_view, size_of(type_of(e.lock_content_view)));
}

write_theme_content :: (file: *File) {
	setup_file_header(file);
	
	info :: type_info(Theming);
	for info.*.members {
		write_color_to_file(file, cast(*Col)(cast(*u8)(*settings.themes) + it.offset_in_bytes));
	}
	
	memcpy(*settings.themes_saved_state, *settings.themes, size_of(Theming));
}

parse_options_file :: () {
	file, success := file_open(get_asset_path(SETTINGS_FILE_NAME), for_writing = false);
	assert(success, "An error occurred while reading settings file");  // Todo - handle better error messages
	
	maj_version, min_version := get_file_header(*file);
	
	if maj_version == 2 && (min_version == 0 || min_version == 1) {
		parse_settings_version_2(*file);
	} else if maj_version == 3 && (min_version == 0 || min_version == 1) {
		parse_settings_version_3(*file);
	} else {
		assert(false, "Unable to read settings file, corrupted");
	}
	
	file_close(*file);
}

parse_theme_file :: () {
	file, success := file_open(get_asset_path(THEME_FILE_NAME), for_writing = false);
	assert(success, "An error occurred while reading theme file");  // Todo - handle better error messages
	
	maj_version, min_version := get_file_header(*file);
	
	if maj_version == 2 && (min_version == 0 || min_version == 1) {
		parse_theming_version_2(*file);
	} else if maj_version == 3 && min_version == 0 {
		parse_theming_version_2(*file);  // still the same
	} else if maj_version == 3 && min_version == 1 {
		parse_theming_version_3(*file);
	} else {
		assert(false, "Unable to read theming file, corrupted");
	}
	
	file_close(*file);
}

parse_settings_version_3 :: (file: *File) {
	size, success := file_length(file);  // don't move the cursor!
	assert(success, "Unable to read settings file");
	
	{
		using settings.platform;
		
		{
			m, M := enum_range(type_of(at_startup));
			at_startup = xx read_in_range(file, type_of(at_startup), xx m, xx M);
			if at_startup == .LAST_FILE {
				file_size: type_of(editor.file_path.count);
				file_read(file, *file_size, size_of(type_of(editor.file_path.count)));
				
				total_size := size_of(type_of(editor.file_path.count)) + file_size + 12;
				assert(size == total_size, "Unable to read settings file, corrupted");
				
				str: string;
				str.data = talloc(file_size);
				str.count = file_size;
				
				file_read(file, str.data, str.count);
				
				if file_exists(str) {
					init_code_editor(str);
				}
			} else {
				assert(size == 12, "Unable to read settings file, corrupted");
			}
		}
		
		code_cursor_speed_slow   = read_in_range(file, u8, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
		code_cursor_speed_fast   = read_in_range(file, u8, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
		memory_cursor_speed_slow = read_in_range(file, u8, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
		memory_cursor_speed_fast = read_in_range(file, u8, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
	}
	
	{
		using settings.editor;
		
		m, M := enum_range(type_of(when_to_save));
		when_to_save = xx read_in_range(file, type_of(when_to_save), xx m, xx M);
		save_interval_in_ms = read_in_range(file, u16, 1, 10_000);
		lock_content_view = cast(bool, read_in_range(file, u8, 0, 1));
	}
}

parse_settings_version_2 :: (file: *File) {
	size, success := file_length(file);  // don't move the cursor!
	assert(success, "Unable to read settings file");
	
	using settings.platform;
	
	{
		m, M := enum_range(type_of(at_startup));
		at_startup = xx read_in_range(file, type_of(at_startup), xx m, xx M);
		if at_startup == .LAST_FILE {
			file_size: type_of(editor.file_path.count);
			file_read(file, *file_size, size_of(type_of(editor.file_path.count)));
			
			total_size := size_of(type_of(editor.file_path.count)) + file_size + 10;
			assert(size == total_size, "Unable to read settings file, corrupted");
			
			str: string;
			str.data = talloc(file_size);
			str.count = file_size;
			
			file_read(file, str.data, str.count);
			
			if file_exists(str) {
				init_code_editor(str);
			}
		} else {
			assert(size == 10, "Unable to read settings file, corrupted");
		}
	}
	
	skip_bytes(file, 2);
	code_cursor_speed_slow   = read_in_range(file, u8, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
	code_cursor_speed_fast   = read_in_range(file, u8, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
	memory_cursor_speed_slow = read_in_range(file, u8, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
	memory_cursor_speed_fast = read_in_range(file, u8, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
}

parse_theming_version_2 :: (file: *File) {
	size, success := file_length(file);  // don't move the cursor!
	assert(success, "Unable to read theming file");
	assert(size == 150, "Unable to read theming file, corrupted");

	using settings.themes;

	general_text              = read_color_from_file(file);
	general_flag_off          = read_color_from_file(file);
	general_flag_on           = read_color_from_file(file);
	general_debug_stack_empty = read_color_from_file(file);
	general_debug_stack_full  = read_color_from_file(file);
	general_stack_focus       = read_color_from_file(file);
	
	platform_widget_bg_normal     = read_color_from_file(file);
	platform_widget_bg_hover      = read_color_from_file(file);
	platform_widget_bg_press      = read_color_from_file(file);
	platform_widget_border_normal = read_color_from_file(file);
	platform_widget_border_hover  = read_color_from_file(file);
	platform_widget_border_press  = read_color_from_file(file);
	platform_text_normal          = read_color_from_file(file);
	platform_text_hover           = read_color_from_file(file);
	platform_text_press           = read_color_from_file(file);
	platform_background           = read_color_from_file(file);
	platform_deep_background      = read_color_from_file(file);
	platform_line                 = read_color_from_file(file);
	platform_disabled             = read_color_from_file(file);
	
	viewer_text        = read_color_from_file(file);
	viewer_number      = read_color_from_file(file);
	viewer_comment     = read_color_from_file(file);
	viewer_dotdir      = read_color_from_file(file);
	viewer_label       = read_color_from_file(file);
	viewer_instruction = read_color_from_file(file);
	viewer_string      = read_color_from_file(file);
	
	memory_normal_empty  = read_color_from_file(file);
	memory_normal_used   = read_color_from_file(file);
	memory_stack_empty   = read_color_from_file(file);
	memory_stack_used    = read_color_from_file(file);
	memory_display_empty = read_color_from_file(file);
	memory_display_used  = read_color_from_file(file);
	memory_input         = read_color_from_file(file);
	
	display_col0  = read_color_from_file(file);
	display_col1  = read_color_from_file(file);
	display_col2  = read_color_from_file(file);
	display_col3  = read_color_from_file(file);
	display_col4  = read_color_from_file(file);
	display_col5  = read_color_from_file(file);
	display_col6  = read_color_from_file(file);
	display_col7  = read_color_from_file(file);
	display_col8  = read_color_from_file(file);
	display_col9  = read_color_from_file(file);
	display_col10 = read_color_from_file(file);
	display_col11 = read_color_from_file(file);
	display_col12 = read_color_from_file(file);
	display_col13 = read_color_from_file(file);
	display_col14 = read_color_from_file(file);
	display_col15 = read_color_from_file(file);
	
	memcpy(*settings.themes_saved_state, *settings.themes, size_of(Theming));
}

parse_theming_version_3 :: (file: *File) {
	size, success := file_length(file);  // don't move the cursor!
	
	assert(success, "Unable to read theming file");
	assert(size == 153, "Unable to read theming file, corrupted");

	using settings.themes;

	general_text              = read_color_from_file(file);
	general_flag_off          = read_color_from_file(file);
	general_flag_on           = read_color_from_file(file);
	general_debug_stack_empty = read_color_from_file(file);
	general_debug_stack_full  = read_color_from_file(file);
	general_stack_focus       = read_color_from_file(file);
	
	platform_widget_bg_normal     = read_color_from_file(file);
	platform_widget_bg_hover      = read_color_from_file(file);
	platform_widget_bg_press      = read_color_from_file(file);
	platform_widget_bg_selected   = read_color_from_file(file);
	platform_widget_border_normal = read_color_from_file(file);
	platform_widget_border_hover  = read_color_from_file(file);
	platform_widget_border_press  = read_color_from_file(file);
	platform_text_normal          = read_color_from_file(file);
	platform_text_hover           = read_color_from_file(file);
	platform_text_press           = read_color_from_file(file);
	platform_background           = read_color_from_file(file);
	platform_deep_background      = read_color_from_file(file);
	platform_line                 = read_color_from_file(file);
	platform_disabled             = read_color_from_file(file);
	
	viewer_text        = read_color_from_file(file);
	viewer_number      = read_color_from_file(file);
	viewer_comment     = read_color_from_file(file);
	viewer_dotdir      = read_color_from_file(file);
	viewer_label       = read_color_from_file(file);
	viewer_instruction = read_color_from_file(file);
	viewer_string      = read_color_from_file(file);
	
	memory_normal_empty  = read_color_from_file(file);
	memory_normal_used   = read_color_from_file(file);
	memory_stack_empty   = read_color_from_file(file);
	memory_stack_used    = read_color_from_file(file);
	memory_display_empty = read_color_from_file(file);
	memory_display_used  = read_color_from_file(file);
	memory_input         = read_color_from_file(file);
	
	display_col0  = read_color_from_file(file);
	display_col1  = read_color_from_file(file);
	display_col2  = read_color_from_file(file);
	display_col3  = read_color_from_file(file);
	display_col4  = read_color_from_file(file);
	display_col5  = read_color_from_file(file);
	display_col6  = read_color_from_file(file);
	display_col7  = read_color_from_file(file);
	display_col8  = read_color_from_file(file);
	display_col9  = read_color_from_file(file);
	display_col10 = read_color_from_file(file);
	display_col11 = read_color_from_file(file);
	display_col12 = read_color_from_file(file);
	display_col13 = read_color_from_file(file);
	display_col14 = read_color_from_file(file);
	display_col15 = read_color_from_file(file);
	
	memcpy(*settings.themes_saved_state, *settings.themes, size_of(Theming));
}

write_color_to_file :: (f: *File, c: *Col) {
	file_write(f, *c.r, 1);
	file_write(f, *c.g, 1);
	file_write(f, *c.b, 1);
}

read_color_from_file :: (f: *File) -> Col {
	c: Col = ---;
	
	file_read(f, *c, 3);
	c.a = 0xFF;
	
	return c;
}

skip_bytes :: (f: File, bytes: s64) {
	pos := file_current_position(f);
	pos += bytes;
	file_set_position(f, pos);
}

read_in_range :: (f: *File, $type: Type, min_value: type, max_value: type) -> type {
	data: type = ---;
	
	file_read(f, *data, size_of(type));
	assert(min_value <= data && data <= max_value, "Unable to read settings file, corrupted");
	
	return data;
}
