draw_header :: () {
	h :: HEADER_HEIGHT;

	draw_rect(.{0, 0}, .{xx vp.width, h}, 0, COLOR_BACKGROUND);
	draw_rect_lines(.{0, 0}, .{xx vp.width, xx vp.height}, 1, COLOR_LINE);
	draw_rect(.{0, h - 1}, .{xx vp.width, 1}, 1, COLOR_LINE);

	draw_text("6502 Simulator", .{10, 4}, 1, 3, WHITE);

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
	draw_rect(viewer.pos, viewer.size, 0, COLOR_BACKGROUND);

	char_per_lines := floor(viewer.size.x / 16) - 2;

	max_value := Vec2.{(viewer.longest_line) * 16.0, viewer.rows_length.count * 16.0};
	scroll_size := viewer.size + max_value;
	min_size := Vec2.{30 * 16.0, 1 * 16.0};

	draw_scrollbar(viewer.pos, viewer.size, z = 3, *viewer.scrollbar_pos, scroll_size, min_size, max_value, settings.code_cursor_speed_slow + 1, settings.code_cursor_speed_fast + 1);

	x_visible := min_size.x + viewer.size.x < scroll_size.x;
	draw_colored_text(x_visible);
	draw_line_count_bar(x_visible);
}

draw_RAM_content :: (offset: Vec2, start: int, end: int, pos_y: f32, height: f32) {
	for y: start..end {
		hex := formatInt(y * 16, base = 16, minimum_digits = 4);
		draw_text(tprint("%:", hex), offset + .{5, 9.0 + y * 16}, 2, 1, COLOR_TEXT_NORMAL);
		for x: 0..15 {
			col := WHITE;
			data := engine.RAM[y * 16 + x];
			if 16 <= y && y < 32 {
				col = ifx data then BLUE else PURPLE;
			} else if 32 <= y && y < 632 {
				col = ifx data then ORANGE else YELLOW;
			} else if y == 632 && x <= 9 {
				col = PINK;
			} else if data {
				col = GREEN;
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
		draw_rect_lines(offset + .{xx x, xx y}, .{xx w, xx h}, 3, RED, 2);
	}
}

draw_program_memory :: () {
	pos:  Vec2 = .{vp.width + 40.0 - MIN_SCREEN_WIDTH / 2, 74};
	size: Vec2 = .{MIN_SCREEN_WIDTH / 2 - 50.0, vp.height - MIN_SCREEN_HEIGHT / 2.0 + 10};

	child_begin("memory", pos, size, 3);  child_end();

	draw_rect(pos, size, 0, COLOR_BACKGROUND);
	draw_rect(pos, .{48, size.y}, 1, COLOR_WIDGET_BG_NORMAL);

	rows_on_screen := floor((size.y - 8) / 16);
	scroll_pos     := Vec2.{0, ui.memory_scrollbar_pos};
	min_size       := Vec2.{0, 0};
	max_value      := Vec2.{0, (2048 - rows_on_screen) * 16};

	draw_scrollbar(pos, size, z = 1, *scroll_pos, .{0, 2048 * 16}, min_size, max_value, settings.memory_cursor_speed_slow + 1, settings.memory_cursor_speed_fast + 1);

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

		draw_text(tprint("0x%", hex), offset + pos + .{9,  8}, layer, 2, WHITE);
		draw_text(tprint("0b%", bin), offset + pos + .{9, 30}, layer, 2, WHITE);
		draw_text(tprint("%",   val), offset + pos + .{9, 52}, layer, 2, WHITE);
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
		draw_text("N:", offset + .{x + 9,  25},  layer, 2, WHITE);
		draw_text("V:", offset + .{x + 9,  45 + 2},  layer, 2, WHITE);
		draw_text("B:", offset + .{x + 9,  65 + 4},  layer, 2, WHITE);
		draw_text("D:", offset + .{x + 9,  85 + 6},  layer, 2, WHITE);
		draw_text("I:", offset + .{x + 9, 105 + 8}, layer, 2, WHITE);
		draw_text("Z:", offset + .{x + 9, 125 + 10}, layer, 2, WHITE);
		draw_text("C:", offset + .{x + 9, 145 + 12}, layer, 2, WHITE);
		using engine.flags;

		fmtBool :: (v: bool) -> string {
			str := tprint("%", v);
			return string.{1, str.data};
		}

		draw_text(tprint("%", cast(u8)N), offset + .{x + 45, 25},  layer, 2, ifx N then GREEN else RED);
		draw_text(tprint("%", cast(u8)V), offset + .{x + 45, 45 + 2},  layer, 2, ifx V then GREEN else RED);
		draw_text(tprint("%", cast(u8)B), offset + .{x + 45, 65 + 4},  layer, 2, ifx B then GREEN else RED);
		draw_text(tprint("%", cast(u8)D), offset + .{x + 45, 85 + 6},  layer, 2, ifx D then GREEN else RED);
		draw_text(tprint("%", cast(u8)I), offset + .{x + 45, 105 + 8}, layer, 2, ifx I then GREEN else RED);
		draw_text(tprint("%", cast(u8)Z), offset + .{x + 45, 125 + 10}, layer, 2, ifx Z then GREEN else RED);
		draw_text(tprint("%", cast(u8)C), offset + .{x + 45, 145 + 12}, layer, 2, ifx C then GREEN else RED);
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
	col: Col = stack_used * RED + (1 - stack_used) * GREEN;

	ff := formatFloat(stack_used * 100, trailing_width = 1, zero_removal = .NO);

	draw_text(tprint("%\% - % / 255B", ff, 255 - engine.S), offset + .{20, 63}, 1, 1, col);
}

draw_current_instruction :: () {
	offset := Vec2.{vp.width - MIN_SCREEN_WIDTH / 2 + 290.0, vp.height - MIN_SCREEN_HEIGHT / 4 + 95.0};
	draw_panel("Executing", offset, .{vp.width - 220.0 - offset.x, 40}, 1);

	intrins := intrinsic_to_string(engine.current_instruction);

	draw_text(intrins, offset + .{12, 11}, 1, 2, WHITE);
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

	draw_text(fmt, offset + .{12, 11}, 1, 2, WHITE);
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

	draw_text(str, offset + .{90, 16}, 1, 2, ifx engine.metrics.unlock then GRAY else COLOR_TEXT_NORMAL);
}

draw_display :: () {

	handle_input_and_time();

	padding :: 4;

	p := fetch_parent();
	draw_rect_lines(p.pos + .{padding, padding}, .{DISPLAY_WIDTH * 8, DISPLAY_HEIGHT * 8}, p.z + 1, COLOR_WIDGET_BORDER_NORMAL, 1);

	width: int;
	row_data: u8 = engine.RAM[0x0200];  // first value
	row_x := p.pos.x + padding;
	row_y := p.pos.y + padding;

	draw_internal :: () #expand {
		col: Col = ifx `data >= 0 && `data < DISPLAY_COLOR.count then DISPLAY_COLOR[`row_data] else BLACK;
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
			draw_text(ui.modal_error_message, p + .{10, 10}, z, 2, WHITE, wrap = MODAL_WIDTH - 20);
		case .UNABLE_TO_OPEN_BINARY;
			draw_text("Unable to open binary file <out.bin> for reading", p + .{10, 10}, z, 2, WHITE);
		case .INCOMPATIBLE_ROM_SIZE;
			draw_text("Incompatible ROM size", p + .{10, 10}, z, 2, WHITE);
			draw_text("ROM size must to be 32kB", p + .{10, 26}, z, 2, WHITE);
		case .ERROR_OPENING_FILE;
			draw_text("An error has occured while opening the file", p + .{10, 10}, z, 2, WHITE);
		case .READING_FILE_TIMED_OUT;
			draw_text("Reading file timed out", p + .{10, 10}, z, 2, WHITE);
		case .NO_INPUT_FILE_GIVEN;
			draw_text("No input file given", p + .{10, 10}, z, 2, WHITE);
		case .GIVEN_FILE_NOT_VALID;
			draw_text("Unsupported given file", p + .{10, 10}, z, 2, WHITE);
			draw_text("File must to have the '.s' extension", p + .{10, 26}, z, 2, WHITE);
		case .UNABLE_TO_FIND_COMPILER;
			draw_text("Unable to find 'vasm6502_oldstyle.exe', aborting", p + .{10, 10}, z, 2, WHITE);
	}
	
	engine.compilation_successful = false;
}

draw_settings :: () {
	p := fetch_parent();
	
	tab_bar(.{10, 10}, SETTINGS_WIDTH - 20, 1, .["platform", "theming"], *ui.settings_focused_tab);
	
	if ui.settings_focused_tab == {
		case 0;  // platform
			draw_text("at startup, open: ", p.pos + .{20, 50}, p.z + 1, 2, COLOR_TEXT_NORMAL);
			w :: #run measure_text("at startup, open", 2).x;
			
			value := cast(int)settings.at_startup;
			combo_box(.{40 + w, 50 - 2}, .{190, 20}, 1, .["empty file", "last file"], *value, *ui.settings_combo_box_open);
			settings.at_startup = xx value;
			
			internal_scroll :: ($text: string, p: Panel, var: *int, y: f32) {
				draw_text(text, p.pos + .{20, y}, p.z + 1, 2, COLOR_TEXT_NORMAL);
				w :: #run measure_text(text, 2).x;
				draw_step_hslider(.{40 + w, y}, .{150, 20}, 1, 20, var, it = xx y);
				draw_text(tprint("%", var.* + 1), p.pos + .{200 + w, y}, p.z + 1, 2, COLOR_TEXT_NORMAL);
			}
			
			h_separator("scrollbars", p.pos + .{10, 80}, SETTINGS_WIDTH - 20, p.z + 1);
			
			internal_scroll("code viewer scroll slow speed", p, *settings.code_cursor_speed_slow, 100);
			internal_scroll("code viewer scroll fast speed", p, *settings.code_cursor_speed_fast, 125);
			internal_scroll("memory viewer scroll slow speed", p, *settings.memory_cursor_speed_slow, 150);
			internal_scroll("memory viewer scroll fast speed", p, *settings.memory_cursor_speed_fast, 175);
		case 1;  // theming
	}
	
}
