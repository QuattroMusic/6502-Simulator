init_settings :: () {
	init_theming();
	init_options();
}

save_theme_file :: () {
	file, success := file_open(THEME_FILE_NAME, for_writing = true, keep_existing_content = false);
	assert(success);  // Todo - handle better error messages
	
	write_theme_content(*file);
	
	file_close(*file);
}

save_options_file :: () {
	file, success := file_open(SETTINGS_FILE_NAME, for_writing = true, keep_existing_content = false);
	assert(success);  // Todo - handle better error messages
	
	write_options_content(*file);
	
	file_close(*file);
}

#scope_file
init_options :: () {
	success := file_exists(SETTINGS_FILE_NAME);
	
	if !success {
		create_options_file();
		return;
	}
	
	parse_options_file();
}

init_theming :: () {
	success := file_exists(THEME_FILE_NAME);
	
	if !success {
		create_theme_file();
		return;
	}
	
	parse_theme_file();
}

setup_file_header :: (f: *File) {
	maj_version: u8 = APP_MAJOR_VERSION;
	min_version: u16 = APP_MINOR_VERSION;
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
	
	file_write(file, *settings.platform.at_startup,               size_of(type_of(settings.platform.at_startup)));
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
	file, success := file_open(SETTINGS_FILE_NAME, for_writing = true, keep_existing_content = false);
	assert(success);  // Todo - handle better error messages
	
	setup_file_header(*file);
	
	data: Platform_Settings;
	
	file_write(*file, *data.at_startup,               size_of(type_of(data.at_startup)));
	file_write(*file, *data.code_cursor_speed_slow,   size_of(type_of(data.code_cursor_speed_slow)));
	file_write(*file, *data.code_cursor_speed_fast,   size_of(type_of(data.code_cursor_speed_fast)));
	file_write(*file, *data.memory_cursor_speed_slow, size_of(type_of(data.memory_cursor_speed_slow)));
	file_write(*file, *data.memory_cursor_speed_fast, size_of(type_of(data.memory_cursor_speed_fast)));
	
	file_close(*file);
	
	ini :: initializer_of(Platform_Settings);
	ini(*settings.platform);
}

create_theme_file :: () {
	file, success := file_open(THEME_FILE_NAME, for_writing = true, keep_existing_content = false);
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
	file, success := file_open(SETTINGS_FILE_NAME, for_writing = false);
	assert(success);  // Todo - handle better error messages
	
	maj_version, min_version := get_file_header(*file);
	
	if maj_version == 2 && min_version == 0 {
		parse_settings_version_2(*file);
	} else {
		assert(false, "Unable to read settings file, corrupted");
	}
	
	file_close(*file);
}

parse_theme_file :: () {
	file, success := file_open(THEME_FILE_NAME, for_writing = false);
	assert(success);  // Todo - handle better error messages
	
	maj_version, min_version := get_file_header(*file);
	
	if maj_version == 2 && min_version == 0 {
		parse_theming_version_2(*file);
	} else {
		assert(false, "Unable to read theming file, corrupted");
	}
	
	file_close(*file);
}

parse_settings_version_2 :: (file: *File) {
	size, success := file_length(file);  // don't move the cursor!
	assert(success, "Unable to read settings file");
	assert(size == 8, "Unable to read settings file, corrupted");
	
	using settings.platform;
	
	{
		m, M := enum_range(At_Startup);
		at_startup = xx read_u8_in_range(file, xx m, xx M);
	}
	code_cursor_speed_slow   = read_u8_in_range(file, CURSOR_SCROLLBAR_MIN_VALUE - 1, CURSOR_SCROLLBAR_MAX_VALUE - 1);
	code_cursor_speed_fast   = read_u8_in_range(file, CURSOR_SCROLLBAR_MIN_VALUE - 1, CURSOR_SCROLLBAR_MAX_VALUE - 1);
	memory_cursor_speed_slow = read_u8_in_range(file, CURSOR_SCROLLBAR_MIN_VALUE - 1, CURSOR_SCROLLBAR_MAX_VALUE - 1);
	memory_cursor_speed_fast = read_u8_in_range(file, CURSOR_SCROLLBAR_MIN_VALUE - 1, CURSOR_SCROLLBAR_MAX_VALUE - 1);
}

parse_theming_version_2 :: (file: *File) {
	size, success := file_length(file);  // don't move the cursor!
	assert(success, "Unable to read theming file");
	assert(size == 99, "Unable to read theming file, corrupted");

	using settings.themes;

	general_text              = read_color_from_file(file);
	general_flag_off          = read_color_from_file(file);
	general_flag_on           = read_color_from_file(file);
	general_debug_stack_empty = read_color_from_file(file);
	general_debug_stack_full  = read_color_from_file(file);
	
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
