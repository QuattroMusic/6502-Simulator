draw_header :: () {
	h :: HEADER_HEIGHT;

	draw_rect(.{0, 0}, .{xx vp.width, h}, settings.themes.platform_background);
	draw_rect_lines(.{0, 0}, .{xx vp.width, xx vp.height}, settings.themes.platform_line);
	draw_rect(.{0, h - 1}, .{xx vp.width, 1}, settings.themes.platform_line);

	draw_text(TITLE_NAME, .{10, 4}, FONT_SIZE_LARGE, settings.themes.general_text);

	if button(.REDUCE, .{cast(f32)vp.width - h * 3, 0}, .{h, h}, FONT_SIZE_NORMAL) {
		if !vp.reduced {
			ShowWindow(vp.window, SW_MINIMIZE);
		}
		vp.reduced = !vp.reduced;
	}

	icon: Icon = ifx window_maximized() then .MINIMIZE else .MAXIMIZE;
	if button(icon, .{cast(f32)vp.width - h * 2, 0}, .{h, h}, FONT_SIZE_NORMAL) {
		if !window_maximized() then ShowWindow(vp.window, SW_MAXIMIZE);
		else                        ShowWindow(vp.window, SW_RESTORE);
	}
	if button(.CLOSE, .{cast(f32)vp.width - h, 0}, .{h, h}, FONT_SIZE_NORMAL) {
		vp.running = false;
	}
}

draw_buttons_controls :: () {
	if !engine.thread_running {
		if button("Compile and run", .{10, 40}, .{170, 25}, FONT_SIZE_SMALL) {
			compile_program();
			if engine.compilation_successful {
				read_ROM(get_asset_path("out.bin"));  // Todo - robustness
				cpu_reset();
				cpu_start();
			}
		}
		if button("Compile", .{190, 40}, .{100, 25}, FONT_SIZE_SMALL) {
			compile_program();
			if engine.compilation_successful {
				read_ROM(get_asset_path("out.bin"));  // Todo - robustness
				cpu_reset();
			}
		}
		if engine.compilation_successful && button("Run", .{300, 40}, .{60, 25}, FONT_SIZE_SMALL) {
			cpu_reset();
			cpu_start();
		}
	} else {
		// we're doing this just to update the variable the next cycle
		running := engine.running;
		if !engine.debug {
			if engine.running {
				if button("Pause", .{100, 40}, .{80, 25}, FONT_SIZE_SMALL) {
					running = false;
				}
			} else {
				if button("Resume", .{100, 40}, .{80, 25}, FONT_SIZE_SMALL) {
					running = true;
				}
			}
		}
		engine.running = running;
		if button("Stop", .{10, 40}, .{80, 25}, FONT_SIZE_SMALL) {
			cpu_stop();
		}
	}

	if button("Reset", .{370, 40}, .{80, 25}, FONT_SIZE_SMALL) {
		cpu_reset();
	}

	if button("Display", .{460, 40}, .{80, 25}, FONT_SIZE_SMALL) {
		toggle_window(ui.display_window, centered = true);
	}
}

draw_code_editor :: () {
	offset :: Vec2.{10, 74};

	editor.pos = offset;
	editor.size = .{vp.width - START_SCREEN_WIDTH / 2.0 + 20, vp.height - 84.0};

	draw_rect(editor.pos, editor.size, settings.themes.platform_background);

	char_per_lines := round_down(editor.size.x / 16) - 2;

	scroll_size := editor.size + .{editor.longest_line * FONT_SIZE_NORMAL, editor.rows_length.count * FONT_SIZE_NORMAL};
	// Todo - Quattro - make this '4' more robust.
	// It means how many empty characters for the scroll x before the bar appears
	min_size := Vec2.{(char_per_lines - 4) * FONT_SIZE_NORMAL, 1 * FONT_SIZE_NORMAL};

	x_visible := min_size.x + editor.size.x < scroll_size.x;
	draw_colored_text(x_visible);
	draw_line_count_bar(x_visible);

	true_size := draw_scrollbar(editor.pos, editor.size, *editor.scrollbar_pos, scroll_size, min_size, settings.platform.code_cursor_speed_slow, settings.platform.code_cursor_speed_fast);
	editor.editor_content_size = true_size;

	// caret
	if editor.focused {
		time := (ms_since_init() - editor.caret_time) % 1000;

		if time < 500 {
			// Todo - Quattro - 3 and 5 is padding, make it more robust
			// Also make more robust the 16.0
			w := get_width_of_line_count_bar();
			
			// check if there are tabs in a row, offset the caret accordingly
			x_offset: f32;
			cursor_start_row: u32 = 0;
			for 0 .. cast(s64, editor.caret_row) - 1 cursor_start_row += editor.rows_length[it] + 1;
			for cursor_start_row .. (cast(s64, cursor_start_row + editor.caret_col) - 1) {
				c := editor.content[it];
				if c == #char "\t" then x_offset += FONT_SIZE_NORMAL * 3;  // Todo - Quattro - tab size in settings
			}
			
			x := editor.pos.x + editor.caret_col * 16.0 + 3 - editor.scrollbar_pos.x + w + x_offset;
			y := editor.pos.y + editor.caret_row * 16.0 + 5 - editor.scrollbar_pos.y;

			if x > (editor.pos.x + w) && x < (editor.pos.x + editor.size.x) && y > editor.pos.y && y < (editor.pos.y + editor.size.y - 16) {
				draw_rect(.{x, y}, .{1, 16}, .{255, 255, 255, 255});
			}
		}
	}

	draw_panel(editor.file_name, editor.pos, editor.size);
}

draw_RAM_content :: (offset: Vec2, start: s64, end: s64, pos_y: f32, height: f32) {
	chars :: u8.[
		#char "0", #char "1", #char "2", #char "3", #char "4", #char "5", #char "6", #char "7",
		#char "8", #char "9", #char "A", #char "B", #char "C", #char "D", #char "E", #char "F"
	];

	for y: start..end {
		// draw address
		value := y * 16;
		v1 := (value >>  4) & 0xF;
		v2 := (value >>  8) & 0xF;
		v3 := (value >> 12) & 0xF;

		draw_character(chars[v3], offset + .{5     , 9.0 + y * 16}, FONT_SIZE_SMALL, settings.themes.platform_text_normal, range_check = false);
		draw_character(chars[v2], offset + .{5 +  8, 9.0 + y * 16}, FONT_SIZE_SMALL, settings.themes.platform_text_normal, range_check = false);
		draw_character(chars[v1], offset + .{5 + 16, 9.0 + y * 16}, FONT_SIZE_SMALL, settings.themes.platform_text_normal, range_check = false);
		draw_character(#char "0", offset + .{5 + 24, 9.0 + y * 16}, FONT_SIZE_SMALL, settings.themes.platform_text_normal, range_check = false);
		draw_character(#char ":", offset + .{5 + 32, 9.0 + y * 16}, FONT_SIZE_SMALL, settings.themes.platform_text_normal, range_check = false);

		// draw values
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

			lo := (data     ) & 0xF;
			hi := (data >> 4) & 0xF;

			draw_character(chars[hi], offset + .{55.0 + x * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, col, range_check = false);
			draw_character(chars[lo], offset + .{71.0 + x * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, col, range_check = false);
		}
	}

	pos := offset.y + 279 + (cast(f32)(engine.S / 16)) * 16;
	if (pos_y + 20) <= pos && pos < (pos_y + height) {
		x := 53 + (cast(f32)(engine.S % 16)) * (32 + 4);
		y := 260 + (cast(f32)(engine.S / 16)) * (16);
		w := 16 * 2 + 2;
		h := 18;
		draw_rect_lines(offset + .{xx x, xx y}, .{xx w, xx h}, settings.themes.general_stack_focus, 2);
	}
}

draw_program_memory :: () {
	pos:  Vec2 = .{vp.width + 40.0 - START_SCREEN_WIDTH / 2, 74};
	size: Vec2 = .{START_SCREEN_WIDTH / 2 - 50.0, vp.height - START_SCREEN_HEIGHT / 2.0 + 10};

	draw_rect(pos, size, settings.themes.platform_background);
	draw_rect(pos, .{48, size.y}, settings.themes.platform_widget_bg_normal);

	rows_on_screen := round_down((size.y - 8) / FONT_SIZE_NORMAL);
	scroll_pos     := Vec2.{0, ui.memory_scrollbar_pos};
	min_size       := Vec2.{0, 0};

	draw_scrollbar(pos, size, *scroll_pos, .{0, 2048 * 16}, min_size, settings.platform.memory_cursor_speed_slow, settings.platform.memory_cursor_speed_fast);

	ui.memory_scrollbar_pos = scroll_pos.y;

	offset := pos + .{2, -ui.memory_scrollbar_pos};
	start: s64 = xx ((ui.memory_scrollbar_pos) / FONT_SIZE_NORMAL);
	end:   s64 = xx ((ui.memory_scrollbar_pos + size.y - 24) / FONT_SIZE_NORMAL);
	draw_RAM_content(offset, start, end, pos.y, size.y);

	draw_panel("memory", pos, size);
}

draw_program_registers :: () {
	panel_internal :: (reg: string, val: $T, offset: Vec2, pos: Vec2, size: Vec2) {
		draw_panel(reg, offset + pos, size);

		s :: size_of(T);

		hex := formatInt(val, base = 16, minimum_digits = (#ifx s == 1 then 2 else 4));
		bin := formatInt(val, base =  2, minimum_digits = (#ifx s == 1 then 8 else 16));

		draw_text(tprint("0x%", hex), offset + pos + .{9,  8}, FONT_SIZE_NORMAL, settings.themes.general_text);
		draw_text(tprint("0b%", bin), offset + pos + .{9, 30}, FONT_SIZE_NORMAL, settings.themes.general_text);
		draw_text(tprint("%",   val), offset + pos + .{9, 52}, FONT_SIZE_NORMAL, settings.themes.general_text);
	}

	offset := Vec2.{vp.width + 40.0 - START_SCREEN_WIDTH / 2, vp.height + 95.0 - START_SCREEN_HEIGHT / 2};

	draw_panel("Registers", offset, .{START_SCREEN_WIDTH / 2 - 50, START_SCREEN_HEIGHT / 4 - 10});

	panel_internal("A", engine.A, offset, .{ 10, 15}, .{176, 76});
	panel_internal("X", engine.X, offset, .{196, 15}, .{176, 76});
	panel_internal("Y", engine.Y, offset, .{382, 15}, .{176, 76});

	panel_internal("PC", engine.PC, offset, .{ 10, 104}, .{305, 76});
	panel_internal("S",  engine.S,  offset, .{382, 104}, .{175, 76});

	{
		x :: 570;
		draw_panel("Flags", offset + .{x, 15}, .{68, 165});
		draw_text("N:", offset + .{x + 9,  25},      FONT_SIZE_NORMAL, settings.themes.general_text);
		draw_text("V:", offset + .{x + 9,  45 + 2},  FONT_SIZE_NORMAL, settings.themes.general_text);
		draw_text("B:", offset + .{x + 9,  65 + 4},  FONT_SIZE_NORMAL, settings.themes.general_text);
		draw_text("D:", offset + .{x + 9,  85 + 6},  FONT_SIZE_NORMAL, settings.themes.general_text);
		draw_text("I:", offset + .{x + 9, 105 + 8},  FONT_SIZE_NORMAL, settings.themes.general_text);
		draw_text("Z:", offset + .{x + 9, 125 + 10}, FONT_SIZE_NORMAL, settings.themes.general_text);
		draw_text("C:", offset + .{x + 9, 145 + 12}, FONT_SIZE_NORMAL, settings.themes.general_text);
		using engine.flags;

		draw_text(tprint("%", cast(u8)N), offset + .{x + 45, 25      }, FONT_SIZE_NORMAL, ifx N then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)V), offset + .{x + 45, 45   + 2}, FONT_SIZE_NORMAL, ifx V then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)B), offset + .{x + 45, 65   + 4}, FONT_SIZE_NORMAL, ifx B then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)D), offset + .{x + 45, 85   + 6}, FONT_SIZE_NORMAL, ifx D then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)I), offset + .{x + 45, 105  + 8}, FONT_SIZE_NORMAL, ifx I then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)Z), offset + .{x + 45, 125 + 10}, FONT_SIZE_NORMAL, ifx Z then settings.themes.general_flag_on else settings.themes.general_flag_off);
		draw_text(tprint("%", cast(u8)C), offset + .{x + 45, 145 + 12}, FONT_SIZE_NORMAL, ifx C then settings.themes.general_flag_on else settings.themes.general_flag_off);
	}
}

draw_program_debug :: () {
	offset := Vec2.{vp.width + 40.0 - START_SCREEN_WIDTH / 2, vp.height - START_SCREEN_HEIGHT / 4 + 95.0};

	draw_panel("Debug", offset, .{190, START_SCREEN_HEIGHT / 4 - 105.0});

	checkbox("debugger", offset + .{15, 15}, .{20, 20}, *engine.debug);
	if engine.debug && engine.thread_running {
		if button("Step", offset + .{120, 13}, .{60, 25}, FONT_SIZE_SMALL) {
			next_instruction();
		}
	}

	draw_panel("Stack used", offset + .{10, 50}, .{170, 35});
	stack_used := (255.0 - engine.S) / 255;
	col: Col = stack_used * settings.themes.general_debug_stack_full + (1 - stack_used) * settings.themes.general_debug_stack_empty;

	ff := formatFloat(stack_used * 100, trailing_width = 1, zero_removal = .NO);

	draw_text(tprint("%\% - % / 255B", ff, 255 - engine.S), offset + .{20, 63}, FONT_SIZE_SMALL, col);
}

draw_current_instruction :: () {
	offset := Vec2.{vp.width - START_SCREEN_WIDTH / 2 + 240.0, vp.height - START_SCREEN_HEIGHT / 4 + 95.0};
	draw_panel("Executing", offset, .{vp.width - 220.0 - offset.x, 40});

	intrins := intrinsic_to_string(engine.current_instruction);

	draw_text(intrins, offset + .{12, 11}, FONT_SIZE_NORMAL, settings.themes.general_text);
}

draw_input :: () {
	offset := Vec2.{vp.width - START_SCREEN_WIDTH / 2 + 240.0, vp.height - START_SCREEN_HEIGHT / 4 + 150.0};
	draw_panel("Input", offset, .{vp.width - 220.0 - offset.x, 40});

	data := engine.RAM[MEMORY_INPUT_ADDRESS];

	fmt: string = ---;
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

	draw_text(fmt, offset + .{12, 11}, FONT_SIZE_NORMAL, settings.themes.general_text);
}

draw_program_frequency :: () {
	offset := Vec2.{vp.width - 210.0, vp.height - START_SCREEN_HEIGHT / 4 + 95.0};
	draw_panel("Frequency", offset, .{200, START_SCREEN_HEIGHT / 4 - 105.0});

	checkbox("free", offset + .{10, 15}, .{20, 20}, *engine.metrics.unlock);

	str: string;
	freq := engine.metrics.update_rate;

	     if freq < kHz(1) str = tprint(" %Hz", formatInt(freq,                 minimum_digits = 3, padding = #char " "));
	else if freq < MHz(1) str = tprint("%kHz", formatInt(freq / 1_000,         minimum_digits = 3, padding = #char " "));
	else if freq < GHz(1) str = tprint("%MHz", formatInt(freq / 1_000_000,     minimum_digits = 3, padding = #char " "));
	else                  str = tprint("%GHz", formatInt(freq / 1_000_000_000, minimum_digits = 3, padding = #char " "));

	freqs :: #run s64.[
		1,          2,      5,      10,      20,      50,      100,      200,      500,
		kHz(1), kHz(2), kHz(5), kHz(10), kHz(20), kHz(50), kHz(100), kHz(200), kHz(500),
		MHz(1), MHz(2), MHz(5), MHz(10), MHz(20), MHz(50), MHz(100), MHz(200), MHz(500), GHz(1)
	];

	found, idx := array_find(freqs, freq);
	draw_step_hslider(offset + .{20, 55}, .{160, 20}, freqs.count, *idx, disabled = engine.metrics.unlock);
	engine.metrics.update_rate = freqs[idx];

	draw_text(str, offset + .{90, 16}, FONT_SIZE_NORMAL, ifx engine.metrics.unlock then settings.themes.platform_disabled else settings.themes.platform_text_normal);
}

draw_display :: (panel: *Window) {
	padding :: 4;

	parent := fetch_parent();
	draw_rect_lines(parent + .{padding, padding}, .{DISPLAY_WIDTH * 8, DISPLAY_HEIGHT * 8}, settings.themes.platform_widget_border_normal, 1);

	width: s64;
	row_data: u8 = engine.RAM[0x0200];  // first value
	row_x := parent.x + padding;
	row_y := parent.y + padding;

	DISPLAY_COLOR : [16]Col;
	memcpy(DISPLAY_COLOR.data, *settings.themes.display_col0, size_of(type_of(DISPLAY_COLOR)));

	draw_internal :: () #expand {
		col: Col = ifx `data >= 0 && `data < DISPLAY_COLOR.count then DISPLAY_COLOR[`row_data] else DISPLAY_COLOR[0];
		draw_rect(.{`row_x, `row_y}, .{FONT_SIZE_GRANULARITY * `width, FONT_SIZE_GRANULARITY}, col);
		`row_x = (((`it - 0x0200) % DISPLAY_WIDTH) * FONT_SIZE_GRANULARITY) + parent.x + padding;
		`row_y = (((`it - 0x0200) / DISPLAY_WIDTH) * FONT_SIZE_GRANULARITY) + parent.y + padding;
	}

	for 0x0200 .. (0x0200 + DISPLAY_WIDTH * DISPLAY_HEIGHT - 1) {
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
	draw_rect(.{row_x, row_y}, .{8.0 * width, 8}, col);
}

draw_modal :: (panel: *Window) {
	pos := panel.pos + .{0, WIDGET_HEADER_HEIGHT};

	x := (vp.width  - MODAL_WIDTH)  / 2.0;
	y := (vp.height - MODAL_HEIGHT) / 2.0;

	if #complete ui.modal_error_type == {
		case .FAILED_COMPILATION;
			draw_text(ui.modal_error_message, pos + .{10, 10}, FONT_SIZE_NORMAL, settings.themes.general_text, wrap = MODAL_WIDTH - 20);
		case .UNABLE_TO_OPEN_BINARY;
			draw_text("Unable to open binary file <out.bin> for reading", pos + .{10, 10}, FONT_SIZE_NORMAL, settings.themes.general_text);
		case .INCOMPATIBLE_ROM_SIZE;
			draw_text("Incompatible ROM size", pos + .{10, 10}, FONT_SIZE_NORMAL, settings.themes.general_text);
			draw_text("ROM size must to be 32kB", pos + .{10, 26}, FONT_SIZE_NORMAL, settings.themes.general_text);
		case .ERROR_OPENING_FILE;
			draw_text("An error has occured while opening the file", pos + .{10, 10}, FONT_SIZE_NORMAL, settings.themes.general_text);
		case .READING_FILE_TIMED_OUT;
			draw_text("Reading file timed out", pos + .{10, 10}, FONT_SIZE_NORMAL, settings.themes.general_text);
		case .NO_INPUT_FILE_GIVEN;
			draw_text("No input file given", pos + .{10, 10}, FONT_SIZE_NORMAL, settings.themes.general_text);
		case .GIVEN_FILE_NOT_VALID;
			draw_text("Unsupported given file", pos + .{10, 10}, FONT_SIZE_NORMAL, settings.themes.general_text);
			draw_text("File must to have the '.s' extension", pos + .{10, 26}, FONT_SIZE_NORMAL, settings.themes.general_text);
		case .UNABLE_TO_FIND_COMPILER;
			draw_text("Unable to find 'vasm6502_oldstyle.exe', aborting", pos + .{10, 10}, FONT_SIZE_NORMAL, settings.themes.general_text);
	}

	engine.compilation_successful = false;
}

draw_settings :: (panel: *Window) {
	pos := panel.pos + .{0, WIDGET_HEADER_HEIGHT};

	tab_bar(pos + .{10, 10}, SETTINGS_WIDTH - 20, *ui.settings_focused_tab);

	if #complete ui.settings_focused_tab == {
		case .PLATFORM;
			t :: "at startup, open:";
			draw_text(t, pos + .{20, 50}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
			w :: #run measure_text(t, FONT_SIZE_NORMAL).x;

			edit := combo_box(pos + .{40 + w, 50 - 2}, .{205, 20}, *settings.platform.at_startup);
			if edit then save_options_file();

			{
				draw_text("fps lock:", pos + .{20, 70}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
				changed_value := input_int(pos + .{165, 70}, FONT_SIZE_NORMAL, *ui.settings_platform_view_fps_lock, 1, 3000);

				if changed_value {
					settings.platform.fps_lock = ui.settings_platform_view_fps_lock;
					save_options_file();
				}
			}

			internal_scroll :: ($text: string, pos: Vec2, var: *u8, y: f32) {
				draw_text(text, pos + .{20, y}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
				w :: #run measure_text(text, FONT_SIZE_NORMAL).x;

				edit := input_int(pos + .{40 + w, y}, s = FONT_SIZE_NORMAL, var, min_value = 1, max_value = 255, it = xx y);

				if edit then save_options_file();
			}

			h_separator("scrollbars", pos + .{10, 110}, SETTINGS_WIDTH - 20);

			internal_scroll("code editor scroll slow speed",   pos, *settings.platform.code_cursor_speed_slow, 130);
			internal_scroll("code editor scroll fast speed",   pos, *settings.platform.code_cursor_speed_fast, 155);
			internal_scroll("memory viewer scroll slow speed", pos, *settings.platform.memory_cursor_speed_slow, 185);
			internal_scroll("memory viewer scroll fast speed", pos, *settings.platform.memory_cursor_speed_fast, 210);
		case .THEMING;
			internal_selectable :: ($text: string, pos: Vec2, x: f32, y: *f32, col: *Col, loc := #caller_location) {
				defer y.* += 16;

				y_off := y.*;
				y_off -= ui.settings_theming_scroll_pos.y;
				if y_off < 40 || y_off > SETTINGS_HEIGHT - 50 then return;
				s :: #run measure_text(text, FONT_SIZE_NORMAL);

				box_pos := Vec2.{x, y_off + 2};
				box_size :: Vec2.{14, 14};

				state1 := create_selectable_region(.TEXT,   pos + .{10, y_off}, s, loc, 0);
				state2 := create_selectable_region(.BUTTON, pos + box_pos, box_size, loc, 1);

				border_col: Col = ---;
				text_col:   Col = ---;

				// even if it's an enum and not a flag (or bool), we have two separated areas, so an OR is totally fine
				if (state1 | state2) == {
					case .RELEASE_NON_HOVER; #through;
					case .NORMAL;
						border_col = settings.themes.platform_widget_border_normal;
						text_col   = settings.themes.platform_text_normal;
					case .PRESSED; #through;
					case .HOLD;
						border_col = settings.themes.platform_widget_border_press;
						text_col   = settings.themes.platform_text_press;
					case .RELEASE; #through;
					case .HOVER; #through;
					case .HOLD_NON_HOVER;
						border_col = settings.themes.platform_widget_border_hover;
						text_col   = settings.themes.platform_text_hover;
				}

				draw_text(text, pos + .{10, y_off}, FONT_SIZE_NORMAL, text_col);

				draw_rect(pos + box_pos, box_size, col.*);
				draw_rect_lines(pos + box_pos, box_size, border_col);

				if state1 == .PRESSED || state2 == .PRESSED {
					ui.internal_selected = col;

					// horrible hack (or is it?)
					// get the offset using `settings.themes` as the base (it will always be positive)
					// then apply the offset to `settings.themes_saved_state`
					offset := cast(u64)col - cast(u64)(*settings.themes);
					#if DEBUG then assert((offset >> 63) == 0, "Offset strangely become negative, how so?");
					new_pos := cast(*Col)((cast(*u8)*settings.themes_saved_state) + offset);

					ui.internal_selected_saved_state = new_pos;
				}
			}

			internal_separator :: ($text: string, pos: Vec2, y: *f32) {
				y.* += 20;
				defer y.* += 5;

				y_off := y.*;
				y_off -= ui.settings_theming_scroll_pos.y;
				if y_off < 40 || y_off > SETTINGS_HEIGHT - 45 then return;

				h_separator(text, pos + .{10, y_off}, SETTINGS_WIDTH - 280);
			}

			// vertical bar
			draw_rect(pos + .{SETTINGS_WIDTH - 240, 40}, .{1, SETTINGS_HEIGHT - 70}, settings.themes.platform_line);

			{
				draw_scrollbar( pos + .{10, 40}, .{SETTINGS_WIDTH - 260, SETTINGS_HEIGHT - 81}, *ui.settings_theming_scroll_pos, .{0, 16 * 56}, .{0, 0}, 1, 1);
				draw_rect_lines(pos + .{SETTINGS_WIDTH - 250 - WIDGET_SCROLLBAR_SIZE, 40}, .{WIDGET_SCROLLBAR_SIZE, SETTINGS_HEIGHT - 80}, settings.themes.platform_line);

				using settings.themes;
				y: f32 = 25;

				internal_separator("general",            pos,       *y);
				internal_selectable("text",              pos, 300,  *y, *general_text);
				internal_selectable("flag off",          pos, 300,  *y, *general_flag_off);
				internal_selectable("flag on",           pos, 300,  *y, *general_flag_on);
				internal_selectable("debug stack empty", pos, 300,  *y, *general_debug_stack_empty);
				internal_selectable("debug stack full",  pos, 300,  *y, *general_debug_stack_full);
				internal_selectable("stack focus",       pos, 300,  *y, *general_stack_focus);

				internal_separator("platform",                  pos,      *y);
				internal_selectable("widget background normal", pos, 410, *y, *platform_widget_bg_normal);
				internal_selectable("widget background hover",  pos, 410, *y, *platform_widget_bg_hover);
				internal_selectable("widget background press",  pos, 410, *y, *platform_widget_bg_press);
				internal_selectable("widget border normal",     pos, 410, *y, *platform_widget_border_normal);
				internal_selectable("widget border hover",      pos, 410, *y, *platform_widget_border_hover);
				internal_selectable("widget border press",      pos, 410, *y, *platform_widget_border_press);
				internal_selectable("text normal",              pos, 410, *y, *platform_text_normal);
				internal_selectable("text hover",               pos, 410, *y, *platform_text_hover);
				internal_selectable("text press",               pos, 410, *y, *platform_text_press);
				internal_selectable("background",               pos, 410, *y, *platform_background);
				internal_selectable("deep background",          pos, 410, *y, *platform_deep_background);
				internal_selectable("line",                     pos, 410, *y, *platform_line);
				internal_selectable("disabled",                 pos, 410, *y, *platform_disabled);

				internal_separator("code viewer",  pos,      *y);
				internal_selectable("text",        pos, 210, *y, *viewer_text);
				internal_selectable("number",      pos, 210, *y, *viewer_number);
				internal_selectable("comment",     pos, 210, *y, *viewer_comment);
				internal_selectable("dotdir",      pos, 210, *y, *viewer_dotdir);
				internal_selectable("label",       pos, 210, *y, *viewer_label);
				internal_selectable("instruction", pos, 210, *y, *viewer_instruction);
				internal_selectable("string",      pos, 210, *y, *viewer_string);

				internal_separator("memory",         pos,      *y);
				internal_selectable("normal empty",  pos, 230, *y, *memory_normal_empty);
				internal_selectable("normal used",   pos, 230, *y, *memory_normal_used);
				internal_selectable("stack empty",   pos, 230, *y, *memory_stack_empty);
				internal_selectable("stack used",    pos, 230, *y, *memory_stack_used);
				internal_selectable("display empty", pos, 230, *y, *memory_display_empty);
				internal_selectable("display used",  pos, 230, *y, *memory_display_used);
				internal_selectable("input",         pos, 230, *y, *memory_input);

				internal_separator("display", pos,      *y);
				internal_selectable("col 1",  pos, 130, *y, *display_col0);
				internal_selectable("col 2",  pos, 130, *y, *display_col1);
				internal_selectable("col 3",  pos, 130, *y, *display_col2);
				internal_selectable("col 4",  pos, 130, *y, *display_col3);
				internal_selectable("col 5",  pos, 130, *y, *display_col4);
				internal_selectable("col 6",  pos, 130, *y, *display_col5);
				internal_selectable("col 7",  pos, 130, *y, *display_col6);
				internal_selectable("col 8",  pos, 130, *y, *display_col7);
				internal_selectable("col 9",  pos, 130, *y, *display_col8);
				internal_selectable("col 10", pos, 130, *y, *display_col9);
				internal_selectable("col 11", pos, 130, *y, *display_col10);
				internal_selectable("col 12", pos, 130, *y, *display_col11);
				internal_selectable("col 13", pos, 130, *y, *display_col12);
				internal_selectable("col 14", pos, 130, *y, *display_col13);
				internal_selectable("col 15", pos, 130, *y, *display_col14);
				internal_selectable("col 16", pos, 130, *y, *display_col15);
			}

			draw_color_picker_buttons :: (pos: Vec2) -> bool {
				pos2 := pos + .{SETTINGS_WIDTH - 215, SETTINGS_HEIGHT - WIDGET_HEADER_HEIGHT - 150};
				pos3 := pos + .{SETTINGS_WIDTH - 215, SETTINGS_HEIGHT - WIDGET_HEADER_HEIGHT - 30};

				update := false;

				if ui.color_picker_edited {
					if memcmp(*settings.themes, *settings.themes_saved_state, size_of(Theming)) == 0 {
						ui.color_picker_edited = false;
						return update;
					}
					if button("save all", pos3, .{180, 20}) {
						save_theme_file();
						ui.color_picker_edited = false;
					}
					if button("reset all", pos2, .{180, 20}) {
						update = true;
						ui.color_picker_edited = false;
						memcpy(*settings.themes, *settings.themes_saved_state, size_of(Theming));
					}

					if ui.internal_selected.* != ui.internal_selected_saved_state.* {
						if button("reset", pos2 + .{0, 30}, .{180, 20}) {
							ui.internal_selected.* = ui.internal_selected_saved_state.*;
							update = true;
							if memcmp(*settings.themes, *settings.themes_saved_state, size_of(Theming)) == 0 {
								ui.color_picker_edited = false;
							}
						}
					}
				}

				return update;
			}

			external_update := draw_color_picker_buttons(pos);

			if color_picker(pos + .{SETTINGS_WIDTH - 225, 45}, ui.internal_selected, external_update) {
				// called only when the mouse button is released
				// save_theme_file();
				ui.color_picker_edited = true;
			}
		case .EDITOR;
			t :: "Save";
			draw_text(t, pos + .{20, 50}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
			w :: #run measure_text(t, FONT_SIZE_NORMAL).x;

			// Todo - Quattro - save data to file
			combo_box(pos + .{40 + w, 50 - 2}, .{250, 20}, *settings.editor.when_to_save);
			if settings.editor.when_to_save == .EVERY_MS {
				input_int(pos + .{40 + w + 260, 50 - 2}, s = FONT_SIZE_NORMAL, *settings.editor.save_interval_in_ms, min_value = 1, max_value = 10000);
			}
	}
}
