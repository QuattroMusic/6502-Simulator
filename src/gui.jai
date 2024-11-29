draw_header :: () {
	h :: HEADER_HEIGHT;

	draw_rect(.{0, 0}, .{xx vp.width, h}, 0, settings.themes.platform_background);
	draw_rect_lines(.{0, 0}, .{xx vp.width, xx vp.height}, 1, settings.themes.platform_line);
	draw_rect(.{0, h - 1}, .{xx vp.width, 1}, 1, settings.themes.platform_line);

	draw_text("6502 Simulator", .{10, 4}, 1, 3, settings.themes.general_text);

	if button(.REDUCE, .{cast(f32)vp.width - h * 3, 0}, .{h, h}, 1, 2) {
		if !vp.reduced {
			ShowWindow(vp.window, SW_MINIMIZE);
		}
		vp.reduced = !vp.reduced;
	}

	icon: Icon = ifx vp.maximized then .MINIMIZE else .MAXIMIZE;
	if button(icon, .{cast(f32)vp.width - h * 2, 0}, .{h, h}, 1, 2) {
		if !vp.maximized then ShowWindow(vp.window, SW_MAXIMIZE);
		else                  ShowWindow(vp.window, SW_RESTORE);

		vp.maximized = !vp.maximized;
	}
	if button(.CLOSE, .{cast(f32)vp.width - h, 0}, .{h, h}, 1, 2) {
		vp.running = false;
	}
}

draw_buttons_controls :: () {
	t :: 1;
	if !engine.thread_running {
		if button("Compile and run", .{10, 40}, .{170, 25}, 1, t) {
			compile_program();
			if engine.compilation_successful {
				read_ROM("out.bin");
				cpu_reset();
				cpu_start();
			}
		}
		if button("Compile", .{190, 40}, .{100, 25}, 1, t) {
			compile_program();
			if engine.compilation_successful {
				read_ROM("out.bin");
				cpu_reset();
			}
		}
		if engine.compilation_successful && button("Run", .{300, 40}, .{60, 25}, 1, t) {
			cpu_reset();
			cpu_start();
		}
	} else {
		// we're doing this just to update the variable the next cycle
		running := engine.running;
		if !engine.debug {
			if engine.running {
				if button("Pause", .{100, 40}, .{80, 25}, 1, t) {
					running = false;
				}
			} else {
				if button("Resume", .{100, 40}, .{80, 25}, 1, t) {
					running = true;
				}
			}
		}
		engine.running = running;
		if button("Stop", .{10, 40}, .{80, 25}, 1, t) {
			cpu_stop();
		}
	}

	if button("Reset", .{370, 40}, .{80, 25}, 1, t) {
		cpu_reset();
	}

	if button("Display", .{460, 40}, .{80, 25}, 1, t) {
		toggle_panel(ui.display_panel, centered = true);
	}
}

draw_code_viewer :: () {
	offset :: Vec2.{10, 74};

	viewer.pos = offset;
	viewer.size = .{vp.width - MIN_SCREEN_WIDTH / 2.0 + 20, vp.height - 84.0};

	draw_panel(viewer.file_name, viewer.pos, viewer.size, 3);
	draw_rect(viewer.pos, viewer.size, 0, settings.themes.platform_background);

	char_per_lines := floor(viewer.size.x / 16) - 2;

	max_value := Vec2.{(viewer.longest_line) * 16.0, viewer.rows_length.count * 16.0};
	scroll_size := viewer.size + max_value;
	min_size := Vec2.{30 * 16.0, 1 * 16.0};

	draw_scrollbar(viewer.pos, viewer.size, z = 3, *viewer.scrollbar_pos, scroll_size, min_size, max_value, settings.platform.code_cursor_speed_slow + 1, settings.platform.code_cursor_speed_fast + 1);

	x_visible := min_size.x + viewer.size.x < scroll_size.x;
	draw_colored_text(x_visible);
	draw_line_count_bar(x_visible);
}

draw_RAM_content :: (offset: Vec2, start: int, end: int, pos_y: f32, height: f32) {
	for y: start..end {
		hex := formatInt(y * 16, base = 16, minimum_digits = 4);
		draw_text(tprint("%:", hex), offset + .{5, 9.0 + y * 16}, 2, 1, settings.themes.platform_text_normal);
		for x: 0..15 {
			data := engine.RAM[y * 16 + x];
			
			col: Col = ---;
			if 16 <= y && y < 32 {
				col = ifx data then settings.themes.memory_stack_used else settings.themes.memory_stack_empty;
			} else if 32 <= y && y < 632 {
				col = ifx data then settings.themes.memory_display_used else settings.themes.memory_display_empty;
			} else if y == 632 && x <= 9 {
				col = settings.themes.memory_input;
			} else if data {
				col = settings.themes.memory_normal_used;
			} else {
				col = settings.themes.memory_normal_empty;
			}

			hex := formatInt(data, base = 16, minimum_digits = 2);
			draw_text(tprint("%", hex), offset + .{55.0 + x * (32 + 4), 4.0 + y * 16}, 2, 2, col);
		}
	}

	pos := offset.y + 276 + (cast(f32)(engine.S / 16)) * 16;
	if (pos_y + 20) <= pos && pos < (pos_y + height) {
		x := 53 + (cast(f32)(engine.S % 16)) * (32 + 4);
		y := 260 + (cast(f32)(engine.S / 16)) * (16);
		w := 16 * 2 + 2;
		h := 18;
		draw_rect_lines(offset + .{xx x, xx y}, .{xx w, xx h}, 3, settings.themes.general_stack_focus, 2);
	}
}

draw_program_memory :: () {
	pos:  Vec2 = .{vp.width + 40.0 - MIN_SCREEN_WIDTH / 2, 74};
	size: Vec2 = .{MIN_SCREEN_WIDTH / 2 - 50.0, vp.height - MIN_SCREEN_HEIGHT / 2.0 + 10};

	child_begin("memory", pos, size, 3);  child_end();

	draw_rect(pos, size, 0, settings.themes.platform_background);
	draw_rect(pos, .{48, size.y}, 1, settings.themes.platform_widget_bg_normal);

	rows_on_screen := floor((size.y - 8) / 16);
	scroll_pos     := Vec2.{0, ui.memory_scrollbar_pos};
	min_size       := Vec2.{0, 0};
	max_value      := Vec2.{0, (2048 - rows_on_screen) * 16};

	draw_scrollbar(pos, size, z = 1, *scroll_pos, .{0, 2048 * 16}, min_size, max_value, settings.platform.memory_cursor_speed_slow + 1, settings.platform.memory_cursor_speed_fast + 1);

	ui.memory_scrollbar_pos = scroll_pos.y;

	offset := pos + .{2, -ui.memory_scrollbar_pos};
	start: int = xx ((ui.memory_scrollbar_pos) / 16);
	end: int = xx ((ui.memory_scrollbar_pos + size.y - 24) / 16);
	draw_RAM_content(offset, start, end, pos.y, size.y);
}

draw_program_registers :: () {
	panel_internal :: (reg: string, val: $T, offset: Vec2, pos: Vec2, size: Vec2, layer: f32) {
		draw_panel(reg, offset + pos, size, layer);

		s :: size_of(T);

		hex := formatInt(val, base = 16, minimum_digits = (#ifx s == 1 then 2 else 4));
		bin := formatInt(val, base =  2, minimum_digits = (#ifx s == 1 then 8 else 16));

		draw_text(tprint("0x%", hex), offset + pos + .{9,  8}, layer, 2, settings.themes.general_text);
		draw_text(tprint("0b%", bin), offset + pos + .{9, 30}, layer, 2, settings.themes.general_text);
		draw_text(tprint("%",   val), offset + pos + .{9, 52}, layer, 2, settings.themes.general_text);
	}

	layer :: 1;
	offset := Vec2.{vp.width + 40.0 - MIN_SCREEN_WIDTH / 2, vp.height + 95.0 - MIN_SCREEN_HEIGHT / 2};

	draw_panel("Registers", offset, .{MIN_SCREEN_WIDTH / 2 - 50, MIN_SCREEN_HEIGHT / 4 - 10}, layer);

	panel_internal("A", engine.A, offset, .{ 10, 15}, .{176, 76}, layer);
	panel_internal("X", engine.X, offset, .{196, 15}, .{176, 76}, layer);
	panel_internal("Y", engine.Y, offset, .{382, 15}, .{176, 76}, layer);

	panel_internal("PC", engine.PC, offset, .{ 10, 104}, .{305, 76}, layer);
	panel_internal("S", engine.S, offset,   .{382, 104}, .{175, 76}, layer);

	{
		x :: 570;
		draw_panel("Flags", offset + .{x, 15}, .{68, 165}, layer);
		draw_text("N:", offset + .{x + 9,  25},      layer, 2, settings.themes.general_text);
		draw_text("V:", offset + .{x + 9,  45 + 2},  layer, 2, settings.themes.general_text);
		draw_text("B:", offset + .{x + 9,  65 + 4},  layer, 2, settings.themes.general_text);
		draw_text("D:", offset + .{x + 9,  85 + 6},  layer, 2, settings.themes.general_text);
		draw_text("I:", offset + .{x + 9, 105 + 8},  layer, 2, settings.themes.general_text);
		draw_text("Z:", offset + .{x + 9, 125 + 10}, layer, 2, settings.themes.general_text);
		draw_text("C:", offset + .{x + 9, 145 + 12}, layer, 2, settings.themes.general_text);
		using engine.flags;

		fmtBool :: (v: bool) -> string {
			str := tprint("%", v);
			return string.{1, str.data};
		}

		draw_text(tprint("%", cast(u8)N), offset + .{x + 45, 25      }, layer, 2, ifx N then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)V), offset + .{x + 45, 45   + 2}, layer, 2, ifx V then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)B), offset + .{x + 45, 65   + 4}, layer, 2, ifx B then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)D), offset + .{x + 45, 85   + 6}, layer, 2, ifx D then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)I), offset + .{x + 45, 105  + 8}, layer, 2, ifx I then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)Z), offset + .{x + 45, 125 + 10}, layer, 2, ifx Z then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)C), offset + .{x + 45, 145 + 12}, layer, 2, ifx C then settings.themes.general_flag_on else settings.themes.general_flag_off);
	}
}

draw_program_debug :: () {
	offset := Vec2.{vp.width + 40.0 - MIN_SCREEN_WIDTH / 2, vp.height - MIN_SCREEN_HEIGHT / 4 + 95.0};

	draw_panel("Debug", offset, .{240, MIN_SCREEN_HEIGHT / 4 - 105.0}, 1);

	checkbox("Enable debug", offset + .{15, 15}, .{20, 20}, 1, *engine.debug);
	if engine.debug && engine.thread_running {
		if button("Step", offset + .{170, 13}, .{60, 25}, 1, 1) {
			next_instruction();
		}
	}

	draw_panel("Stack used", offset + .{10, 50}, .{170, 35}, 1);
	stack_used := (255.0 - engine.S) / 255;
	col: Col = stack_used * settings.themes.general_debug_stack_full + (1 - stack_used) * settings.themes.general_debug_stack_empty;

	ff := formatFloat(stack_used * 100, trailing_width = 1, zero_removal = .NO);

	draw_text(tprint("%\% - % / 255B", ff, 255 - engine.S), offset + .{20, 63}, 1, 1, col);
}

draw_current_instruction :: () {
	offset := Vec2.{vp.width - MIN_SCREEN_WIDTH / 2 + 290.0, vp.height - MIN_SCREEN_HEIGHT / 4 + 95.0};
	draw_panel("Executing", offset, .{vp.width - 220.0 - offset.x, 40}, 1);

	intrins := intrinsic_to_string(engine.current_instruction);

	draw_text(intrins, offset + .{12, 11}, 1, 2, settings.themes.general_text);
}

draw_input :: () {
	offset := Vec2.{vp.width - MIN_SCREEN_WIDTH / 2 + 290.0, vp.height - MIN_SCREEN_HEIGHT / 4 + 150.0};
	draw_panel("Input", offset, .{vp.width - 220.0 - offset.x, 40}, 1);

	data := engine.RAM[MEMORY_INPUT_ADDRESS];

	fmt: string;
	if data == {
		case 0;         fmt = "NONE";
		case KEY_SPACE; fmt = "32 / SPACE";
		case KEY_LEFT;  fmt = "37 / LEFT";
		case KEY_UP;    fmt = "38 / UP";
		case KEY_RIGHT; fmt = "39 / RIGHT";
		case KEY_DOWN;  fmt = "40 / DOWN";
		case;
			fmt = tprint("% / KEY_%", data, string.{1, *data});
	}

	draw_text(fmt, offset + .{12, 11}, 1, 2, settings.themes.general_text);
}

draw_program_frequency :: () {
	offset := Vec2.{vp.width - 210.0, vp.height - MIN_SCREEN_HEIGHT / 4 + 95.0};
	draw_panel("Frequency", offset, .{200, MIN_SCREEN_HEIGHT / 4 - 105.0}, 1);

	checkbox("free", offset + .{10, 15}, .{20, 20}, 1, *engine.metrics.unlock);

	str: string;
	freq := engine.metrics.update_rate;

	     if freq < kHz(1) str = tprint(" %Hz", formatInt(freq,                 minimum_digits = 3, padding = #char " "));
	else if freq < MHz(1) str = tprint("%kHz", formatInt(freq / 1_000,         minimum_digits = 3, padding = #char " "));
	else if freq < GHz(1) str = tprint("%MHz", formatInt(freq / 1_000_000,     minimum_digits = 3, padding = #char " "));
	else                  str = tprint("%GHz", formatInt(freq / 1_000_000_000, minimum_digits = 3, padding = #char " "));

	freqs :: #run int.[
		1,          2,      5,      10,      20,      50,      100,      200,      500,
		kHz(1), kHz(2), kHz(5), kHz(10), kHz(20), kHz(50), kHz(100), kHz(200), kHz(500),
		MHz(1), MHz(2), MHz(5), MHz(10), MHz(20), MHz(50), MHz(100), MHz(200), MHz(500), GHz(1)
	];

	found, idx := array_find(freqs, freq);
	draw_step_hslider(offset + .{20, 55}, .{160, 20}, 1, freqs.count, *idx, disabled = engine.metrics.unlock);
	engine.metrics.update_rate = freqs[idx];

	draw_text(str, offset + .{90, 16}, 1, 2, ifx engine.metrics.unlock then settings.themes.platform_disabled else settings.themes.platform_text_normal);
}

draw_display :: () {

	handle_input_and_time();

	padding :: 4;

	p := fetch_parent();
	draw_rect_lines(p.pos + .{padding, padding}, .{DISPLAY_WIDTH * 8, DISPLAY_HEIGHT * 8}, p.z + 1, settings.themes.platform_widget_border_normal, 1);

	width: int;
	row_data: u8 = engine.RAM[0x0200];  // first value
	row_x := p.pos.x + padding;
	row_y := p.pos.y + padding;

	DISPLAY_COLOR : [16]Col;
	memcpy(DISPLAY_COLOR.data, *settings.themes.display_col0, size_of(type_of(DISPLAY_COLOR)));

	draw_internal :: () #expand {
		col: Col = ifx `data >= 0 && `data < DISPLAY_COLOR.count then DISPLAY_COLOR[`row_data] else DISPLAY_COLOR[0];
		draw_rect(.{`row_x, `row_y}, .{8.0 * `width, 8}, `p.z + 1, col);
		`row_x = (((`it - 0x0200) % DISPLAY_WIDTH) * 8) + p.pos.x + padding;
		`row_y = (((`it - 0x0200) / DISPLAY_WIDTH) * 8) + p.pos.y + padding;
	}

	for 0x0200..(0x0200 + DISPLAY_WIDTH * DISPLAY_HEIGHT - 1) {
		data := engine.RAM[it];

		// some sort of greedy meshing (not advanced, works rows per rows)
		if data != row_data {
			draw_internal();
			width = 1;
			row_data = data;
		} else if ((it - 0x0200) % DISPLAY_WIDTH) == 0 {
			draw_internal();
			width = 1;
		} else width += 1;
	}
	col: Col = DISPLAY_COLOR[row_data];
	draw_rect(.{row_x, row_y}, .{8.0 * width, 8}, p.z + 1, col);
}

draw_modal :: () {
	x := (vp.width  - MODAL_WIDTH)  / 2.0;
	y := (vp.height - MODAL_HEIGHT) / 2.0;

	parent := fetch_parent();
	p := parent.pos;
	z := 1 + parent.z;

	if #complete ui.modal_error_type == {
		case .FAILED_COMPILATION;
			draw_text(ui.modal_error_message, p + .{10, 10}, z, 2, settings.themes.general_text, wrap = MODAL_WIDTH - 20);
		case .UNABLE_TO_OPEN_BINARY;
			draw_text("Unable to open binary file <out.bin> for reading", p + .{10, 10}, z, 2, settings.themes.general_text);
		case .INCOMPATIBLE_ROM_SIZE;
			draw_text("Incompatible ROM size", p + .{10, 10}, z, 2, settings.themes.general_text);
			draw_text("ROM size must to be 32kB", p + .{10, 26}, z, 2, settings.themes.general_text);
		case .ERROR_OPENING_FILE;
			draw_text("An error has occured while opening the file", p + .{10, 10}, z, 2, settings.themes.general_text);
		case .READING_FILE_TIMED_OUT;
			draw_text("Reading file timed out", p + .{10, 10}, z, 2, settings.themes.general_text);
		case .NO_INPUT_FILE_GIVEN;
			draw_text("No input file given", p + .{10, 10}, z, 2, settings.themes.general_text);
		case .GIVEN_FILE_NOT_VALID;
			draw_text("Unsupported given file", p + .{10, 10}, z, 2, settings.themes.general_text);
			draw_text("File must to have the '.s' extension", p + .{10, 26}, z, 2, settings.themes.general_text);
		case .UNABLE_TO_FIND_COMPILER;
			draw_text("Unable to find 'vasm6502_oldstyle.exe', aborting", p + .{10, 10}, z, 2, settings.themes.general_text);
	}
	
	engine.compilation_successful = false;
}

draw_settings :: () {
	p := fetch_parent();
	
	tab: int = xx ui.settings_focused_tab;
	tab_bar(.{10, 10}, SETTINGS_WIDTH - 20, 1, .["platform", "theming"], *tab);
	ui.settings_focused_tab = xx tab;
	
	// ui.settings_focused_tab = .THEMING;
	
	if ui.settings_focused_tab == {
		case .PLATFORM;
			draw_text("at startup, open: ", p.pos + .{20, 50}, p.z + 1, 2, settings.themes.platform_text_normal);
			w :: #run measure_text("at startup, open", 2).x;
			
			value := cast(int)settings.platform.at_startup;
			edit := combo_box(.{40 + w, 50 - 2}, .{190, 20}, 1, .["empty file", "last file"], *value, *ui.settings_combo_box_open);
			settings.platform.at_startup = xx value;
			
			if edit then save_options_file();
			
			internal_scroll :: ($text: string, p: Panel, var: *u8, y: f32) {
				draw_text(text, p.pos + .{20, y}, p.z + 1, 2, settings.themes.platform_text_normal);
				w :: #run measure_text(text, 2).x;
				
				slider_val := cast(int)var.*;
				edit := draw_step_hslider(.{40 + w, y}, .{150, 20}, CURSOR_SCROLLBAR_MIN_VALUE, CURSOR_SCROLLBAR_MAX_VALUE, *slider_val, it = xx y);
				var.* = cast,trunc(u8)slider_val;
				
				draw_text(tprint("%", var.* + 1), p.pos + .{200 + w, y}, p.z + 1, 2, settings.themes.platform_text_normal);

				if edit then ui.settings_platform_scrollbar_edited = true;
			}
			
			h_separator("scrollbars", .{10, 80}, SETTINGS_WIDTH - 20, 1);
			
			internal_scroll("code viewer scroll slow speed", p, *settings.platform.code_cursor_speed_slow, 100);
			internal_scroll("code viewer scroll fast speed", p, *settings.platform.code_cursor_speed_fast, 125);
			internal_scroll("memory viewer scroll slow speed", p, *settings.platform.memory_cursor_speed_slow, 155);
			internal_scroll("memory viewer scroll fast speed", p, *settings.platform.memory_cursor_speed_fast, 180);
			
			if ui.settings_platform_scrollbar_edited && is_mouse_released(0) {
				ui.settings_platform_scrollbar_edited = false;
				save_options_file();
			}
		case .THEMING;
			internal_selectable :: ($text: string, x: f32, y: *f32, col: *Col, loc := #caller_location) {
				defer y.* += 16;
				
				y_off := y.*;
				y_off -= ui.settings_theming_scroll_pos.y;
				if y_off < 40 || y_off > 550 then return;
				s :: #run measure_text(text, 2);
				
				box_pos := Vec2.{x, y_off + 2};
				box_size :: Vec2.{14, 14};
				
				state, _, _ := create_selectable_region(.TEXT, loc, 0, .{10, y_off}, s, 2);
				state       |= create_selectable_region(.BUTTON, loc, 1, box_pos, box_size, 2);

				_, border_col, text_col := fetch_colors(state);
				
				draw_widget_text(text, .{10, y_off}, 1, 2, text_col);
				
				draw_widget_rect(box_pos, box_size, 1, col.*);
				draw_widget_rect_lines(box_pos, box_size, 2, border_col);
				
				if state != .NORMAL && (is_mouse_inside_widget_rect(box_pos, box_size) || is_mouse_inside_widget_rect(.{10, y_off}, .{s.x, 16})) {
					if is_mouse_pressed(0) {
						ui.internal_edit = RGB_to_HSV(col.*);
						ui.internal_selected = col;
					}
					if is_mouse_pressed(1) {
						// horrible hack (or is it?)
						// get the offset using `settings.themes` as the base (it will always be positive)
						// then apply the offset to `settings.themes_saved_state`
						offset := cast(u64)col - cast(u64)(*settings.themes);
						#if DEBUG then assert(!(offset >> 63), "Offset strangely become negative, how so?");
						new_pos := cast(*Col)((cast(*u8)*settings.themes_saved_state) + offset);
						memcpy(col, new_pos, size_of(Col));
						
						ui.internal_edit = RGB_to_HSV(col.*);
						ui.internal_selected = col;
						
						save_theme_file();
					}
				}
			}
			
			internal_separator :: ($text: string, y: *f32) {
				y.* += 20;
				defer y.* += 5;
				
				y_off := y.*;
				y_off -= ui.settings_theming_scroll_pos.y;
				if y_off < 40 || y_off > 555 then return;
				
				h_separator(text, .{10, y_off}, SETTINGS_WIDTH - 280, 1);
			}
			
			draw_rect(p.pos + .{SETTINGS_WIDTH - 240, 40}, .{1, SETTINGS_HEIGHT - 70}, p.z + 1, settings.themes.platform_line);
			
			{
				draw_scrollbar(.{10, 40}, .{SETTINGS_WIDTH - 260, SETTINGS_HEIGHT - 83}, z = 1, *ui.settings_theming_scroll_pos, .{0, 16 * 55}, .{0, 0}, .{0, 16 * (55 - 32)}, 1, 1);
				draw_rect_lines(p.pos + .{SETTINGS_WIDTH - 250 - WIDGET_SCROLLBAR_SIZE, 40}, .{WIDGET_SCROLLBAR_SIZE, SETTINGS_HEIGHT - 80}, p.z + 3, settings.themes.platform_line);

				using settings.themes;
				y: f32 = 25;
				
				internal_separator("general",                  *y);
				internal_selectable("text",              300,  *y, *general_text);
				internal_selectable("flag off",          300,  *y, *general_flag_off);
				internal_selectable("flag on",           300,  *y, *general_flag_on);
				internal_selectable("debug stack empty", 300,  *y, *general_debug_stack_empty);
				internal_selectable("debug stack full",  300,  *y, *general_debug_stack_full);
				internal_selectable("stack focus",       300,  *y, *general_stack_focus);

				internal_separator("platform",                       *y);
				internal_selectable("widget background normal", 410, *y, *platform_widget_bg_normal);
				internal_selectable("widget background hover",  410, *y, *platform_widget_bg_hover);
				internal_selectable("widget background press",  410, *y, *platform_widget_bg_press);
				internal_selectable("widget border normal",     410, *y, *platform_widget_border_normal);
				internal_selectable("widget border hover",      410, *y, *platform_widget_border_hover);
				internal_selectable("widget border press",      410, *y, *platform_widget_border_press);
				internal_selectable("text normal",              410, *y, *platform_text_normal);
				internal_selectable("text hover",               410, *y, *platform_text_hover);
				internal_selectable("text press",               410, *y, *platform_text_press);
				internal_selectable("background",               410, *y, *platform_background);
				internal_selectable("deep background",          410, *y, *platform_deep_background);
				internal_selectable("line",                     410, *y, *platform_line);
				internal_selectable("disabled",                 410, *y, *platform_disabled);
				
				internal_separator("code viewer",       *y);
				internal_selectable("text",        210, *y, *viewer_text);
				internal_selectable("number",      210, *y, *viewer_number);
				internal_selectable("comment",     210, *y, *viewer_comment);
				internal_selectable("dotdir",      210, *y, *viewer_dotdir);
				internal_selectable("label",       210, *y, *viewer_label);
				internal_selectable("instruction", 210, *y, *viewer_instruction);
				internal_selectable("string",      210, *y, *viewer_string);
				
				internal_separator("memory",              *y);
				internal_selectable("normal empty",  230, *y, *memory_normal_empty);
				internal_selectable("normal used",   230, *y, *memory_normal_used);
				internal_selectable("stack empty",   230, *y, *memory_stack_empty);
				internal_selectable("stack used",    230, *y, *memory_stack_used);
				internal_selectable("display empty", 230, *y, *memory_display_empty);
				internal_selectable("display used",  230, *y, *memory_display_used);
				internal_selectable("input",         230, *y, *memory_input);
				
				internal_separator("display",      *y);
				internal_selectable("col 1",  130, *y, *display_col0);
				internal_selectable("col 2",  130, *y, *display_col1);
				internal_selectable("col 3",  130, *y, *display_col2);
				internal_selectable("col 4",  130, *y, *display_col3);
				internal_selectable("col 5",  130, *y, *display_col4);
				internal_selectable("col 6",  130, *y, *display_col5);
				internal_selectable("col 7",  130, *y, *display_col6);
				internal_selectable("col 8",  130, *y, *display_col7);
				internal_selectable("col 9",  130, *y, *display_col8);
				internal_selectable("col 10", 130, *y, *display_col9);
				internal_selectable("col 11", 130, *y, *display_col10);
				internal_selectable("col 12", 130, *y, *display_col11);
				internal_selectable("col 13", 130, *y, *display_col12);
				internal_selectable("col 14", 130, *y, *display_col13);
				internal_selectable("col 15", 130, *y, *display_col14);
				internal_selectable("col 16", 130, *y, *display_col15);
			}

			{
				pos := p.pos + .{SETTINGS_WIDTH - 233, 275};
				h_separator("info", .{SETTINGS_WIDTH - 233, 275}, 225, 1);
				
				draw_text("- left click the colored box", pos + .{0, 20}, p.z + 1, 1, settings.themes.platform_text_normal);
				draw_text("  or the text to select",      pos + .{0, 30}, p.z + 1, 1, settings.themes.platform_text_normal);
				draw_text("  the color",                  pos + .{0, 40}, p.z + 1, 1, settings.themes.platform_text_normal);
				draw_text("- right click to revert to",   pos + .{0, 60}, p.z + 1, 1, settings.themes.platform_text_normal);
				draw_text("  default value",              pos + .{0, 70}, p.z + 1, 1, settings.themes.platform_text_normal);
				draw_text("- enjoy!",                     pos + .{0, 90}, p.z + 1, 1, settings.themes.platform_text_normal);
			}
			
			if(color_picker(.{SETTINGS_WIDTH - 225, 45}, 1, *ui.internal_edit, ui.internal_selected)) {
				ui.settings_theming_color_edited = true;  // Todo - memcmp?
			}
			
			if(ui.settings_theming_color_edited && is_mouse_released(0)) {
				ui.settings_theming_color_edited = false;
				save_theme_file();
			}
	}
}
