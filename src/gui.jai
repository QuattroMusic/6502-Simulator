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
				editor.focused = true;
			}
		}
		if button("Compile", .{190, 40}, .{100, 25}, FONT_SIZE_SMALL) {
			compile_program();
			if engine.compilation_successful {
				read_ROM(get_asset_path("out.bin"));  // Todo - robustness
				cpu_reset();
				editor.focused = true;
			}
		}
		if engine.compilation_successful && button("Run", .{300, 40}, .{60, 25}, FONT_SIZE_SMALL) {
			cpu_reset();
			cpu_start();
			editor.focused = true;
		}
	} else {
		// we're doing this just to update the variable the next cycle
		running := engine.running;
		if !engine.debug {
			if engine.running {
				if button("Pause", .{100, 40}, .{80, 25}, FONT_SIZE_SMALL) {
					running = false;
					editor.focused = true;
				}
			} else {
				if button("Resume", .{100, 40}, .{80, 25}, FONT_SIZE_SMALL) {
					running = true;
					editor.focused = true;
				}
			}
		}
		engine.running = running;
		if button("Stop", .{10, 40}, .{80, 25}, FONT_SIZE_SMALL) {
			cpu_stop();
			editor.focused = true;
		}
	}

	if button("Reset", .{370, 40}, .{80, 25}, FONT_SIZE_SMALL) {
		cpu_reset();
		editor.focused = true;
	}

	if button("Display", .{460, 40}, .{80, 25}, FONT_SIZE_SMALL) {
		toggle_window(ui.display_window, centered = true);
	}
	
	if button("cheatsheet", .{550, 40}, .{100, 25}, FONT_SIZE_SMALL) {
		toggle_window(ui.cheatsheet_window, centered = true);
	}
}

draw_code_editor :: () {
	offset :: Vec2.{10, 74};

	editor.pos = offset;
	editor.size = .{vp.width - START_SCREEN_WIDTH / 2.0 + 20, vp.height - 84.0};

	draw_rect(editor.pos, editor.size, settings.themes.platform_background);

	char_per_lines := round_down(editor.size.x / 16) - 2;

	scroll_size := editor.size + .{editor.longest_line * FONT_SIZE_NORMAL, editor.rows_length.count * FONT_SIZE_NORMAL};

	min_size: Vec2 = ---;
	min_size.x = (char_per_lines - 0) * FONT_SIZE_NORMAL;
	
	if settings.editor.lock_content_view {
		visible_lines := round_down((editor.size.y - 8) / 16);
		min_size.y = visible_lines * FONT_SIZE_NORMAL;
	} else {
		min_size.y = FONT_SIZE_NORMAL;
	}

	x_visible := min_size.x + editor.size.x < scroll_size.x;

	draw_colored_text(x_visible);
	draw_line_count_bar(x_visible);
	
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

			if x > (editor.pos.x + w) && x < (editor.pos.x + editor.size.x) && y > editor.pos.y && y < (editor.pos.y + editor.size.y - 18) {
				draw_rect(.{x, y}, .{1, 16}, .{255, 255, 255, 255});
			}
		}
	}
	
	true_size := draw_scrollbar(editor.pos, editor.size, *editor.scrollbar_pos, scroll_size, min_size, settings.platform.code_cursor_speed_slow, settings.platform.code_cursor_speed_fast);
	editor.editor_content_size = true_size;

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

	panel_internal("PC", engine.PC, offset, .{ 10, 104}, .{362, 76});
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
