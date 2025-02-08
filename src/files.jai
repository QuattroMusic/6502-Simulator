init_settings :: () {
	init_theming();
	init_options();
}

save_theme_file :: () {
	file, success := file_open(get_asset_path(THEME_FILE_NAME), for_writing = true, keep_existing_content = false);
	assert(success);  // Todo - handle better error messages
	
	write_theme_content(*file);
	
	file_close(*file);
}

save_options_file :: () {
	file, success := file_open(get_asset_path(SETTINGS_FILE_NAME), for_writing = true, keep_existing_content = false);
	assert(success);  // Todo - handle better error messages
	
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
		create_options_file();
		return;
	}
	
	parse_options_file();
}

init_theming :: () {
	success := file_exists(get_asset_path(THEME_FILE_NAME));
	
	if !success {
		create_theme_file();
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
	
	file_write(file, *settings.platform.at_startup, size_of(type_of(settings.platform.at_startup)));
	if(settings.platform.at_startup == .OPEN_LAST_FILE) {
		file_write(file, *viewer.file_path.count, size_of(type_of(viewer.file_path.count)));
		file_write(file, viewer.file_path.data, viewer.file_path.count);
	}
	
	file_write(file, *settings.platform.fps_lock,                 size_of(type_of(settings.platform.fps_lock)));
	file_write(file, *settings.platform.code_cursor_speed_slow,   size_of(type_of(settings.platform.code_cursor_speed_slow)));
	file_write(file, *settings.platform.code_cursor_speed_fast,   size_of(type_of(settings.platform.code_cursor_speed_fast)));
	file_write(file, *settings.platform.memory_cursor_speed_slow, size_of(type_of(settings.platform.memory_cursor_speed_slow)));
	file_write(file, *settings.platform.memory_cursor_speed_fast, size_of(type_of(settings.platform.memory_cursor_speed_fast)));
}

write_theme_content :: (file: *File) {
	setup_file_header(file);
	
	info :: type_info(Theming);
	for info.*.members {
		write_color_to_file(file, cast(*Col)(cast(*u8)(*settings.themes) + it.offset_in_bytes));
	}
}

create_options_file :: () {
	file, success := file_open(get_asset_path(SETTINGS_FILE_NAME), for_writing = true, keep_existing_content = false);
	assert(success);  // Todo - handle better error messages
	
	setup_file_header(*file);
	
	data: Platform_Settings;
	
	file_write(*file, *data.at_startup,               size_of(type_of(data.at_startup)));
	file_write(*file, *data.fps_lock,                 size_of(type_of(data.fps_lock)));
	file_write(*file, *data.code_cursor_speed_slow,   size_of(type_of(data.code_cursor_speed_slow)));
	file_write(*file, *data.code_cursor_speed_fast,   size_of(type_of(data.code_cursor_speed_fast)));
	file_write(*file, *data.memory_cursor_speed_slow, size_of(type_of(data.memory_cursor_speed_slow)));
	file_write(*file, *data.memory_cursor_speed_fast, size_of(type_of(data.memory_cursor_speed_fast)));
	
	file_close(*file);
	
	ini :: initializer_of(Platform_Settings);
	ini(*settings.platform);
	
	ui.settings_platform_view_fps_lock = settings.platform.fps_lock;
}

create_theme_file :: () {
	file, success := file_open(get_asset_path(THEME_FILE_NAME), for_writing = true, keep_existing_content = false);
	assert(success);  // Todo - handle better error messages
	
	setup_file_header(*file);
	
	data: Theming;
	info :: type_info(Theming);
	for info.*.members {
		write_color_to_file(*file, cast(*Col)(cast(*u8)(*data) + it.offset_in_bytes));
	}
	
	file_close(*file);
	
	ini :: initializer_of(Theming);
	ini(*settings.themes);
	ini(*settings.themes_saved_state);
}

parse_options_file :: () {
	file, success := file_open(get_asset_path(SETTINGS_FILE_NAME), for_writing = false);
	assert(success);  // Todo - handle better error messages
	
	maj_version, min_version := get_file_header(*file);
	
	if maj_version == 2 && (min_version == 0 || min_version == 1) {
		parse_settings_version_2(*file);
	} else {
		assert(false, "Unable to read settings file, corrupted");
	}
	
	file_close(*file);
}

parse_theme_file :: () {
	file, success := file_open(get_asset_path(THEME_FILE_NAME), for_writing = false);
	assert(success);  // Todo - handle better error messages
	
	maj_version, min_version := get_file_header(*file);
	
	if maj_version == 2 && (min_version == 0 || min_version == 1) {
		parse_theming_version_2(*file);
	} else {
		assert(false, "Unable to read theming file, corrupted");
	}
	
	file_close(*file);
}

parse_settings_version_2 :: (file: *File) {
	size, success := file_length(file);  // don't move the cursor!
	assert(success, "Unable to read settings file");
	
	using settings.platform;
	
	{
		m, M := enum_range(At_Startup);
		at_startup = xx read_u8_in_range(file, xx m, xx M);
		if at_startup == .OPEN_LAST_FILE {
			file_size: type_of(viewer.file_path.count);
			file_read(file, *file_size, size_of(type_of(viewer.file_path.count)));
			
			total_size := size_of(type_of(viewer.file_path.count)) + file_size + 10;
			assert(size == total_size, "Unable to read settings file, corrupted");
			
			str: string;
			str.data = talloc(file_size);
			str.count = file_size;
			
			file_read(file, str.data, str.count);
			
			if file_exists(str) {
				init_code_viewer(str);
			}
		} else {
			assert(size == 10, "Unable to read settings file, corrupted");
		}
	}
	fps_lock                 = read_u16_in_range(file, 1, 9999);
	code_cursor_speed_slow   = read_u8_in_range(file, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
	code_cursor_speed_fast   = read_u8_in_range(file, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
	memory_cursor_speed_slow = read_u8_in_range(file, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
	memory_cursor_speed_fast = read_u8_in_range(file, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE);
	
	ui.settings_platform_view_fps_lock = fps_lock;
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

write_color_to_file :: inline (f: *File, c: *Col) {
	file_write(f, *c.r, 1);
	file_write(f, *c.g, 1);
	file_write(f, *c.b, 1);
}

read_color_from_file :: inline (f: *File) -> Col {
	c: Col = ---;
	
	file_read(f, *c, 3);
	c.a = 0xFF;
	
	return c;
}

read_u8_in_range :: inline (f: *File, min_v: u8, max_v: u8) -> u8 {
	data: u8 = ---;
	
	file_read(f, *data, 1);
	assert(min_v <= data && data <= max_v, "Unable to read settings file, corrupted");
	
	return data;
}

read_u16_in_range :: inline (f: *File, min_v: u16, max_v: u16) -> u16 {
	data: u16 = ---;
	
	file_read(f, *data, 2);
	assert(min_v <= data && data <= max_v, "Unable to read settings file, corrupted");
	
	return data;
}
