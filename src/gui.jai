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
	if !engine.running {
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
		paused := engine.paused;
		if !engine.debug {
			if engine.paused {
				if button("Resume", .{100, 40}, .{80, 25}, FONT_SIZE_SMALL) {
					paused = false;
					editor.focused = true;
				}
			} else {
				if button("Pause", .{100, 40}, .{80, 25}, FONT_SIZE_SMALL) {
					paused = true;
					editor.focused = true;
				}
			}
		}
		engine.paused = paused;
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

get_tab_offset :: (row: u32, col: u32) -> f32 {
	x_offset: f32;
	cursor_start_row: u32 = 0;
	
	for 0 .. cast(s64, row) - 1 cursor_start_row += editor.rows_length[it] + 1;
	
	for cursor_start_row .. (cast(s64, cursor_start_row + col) - 1) {
		c := editor.content[it];
		if c == #char "\t" then x_offset += FONT_SIZE_NORMAL * 3;  // Todo - Quattro - tab size in settings
	}
	
	return x_offset;
}

draw_selected_line :: (row: u32, from_col: u32, to_col: u32, end_padding: f32 = 0) {
	count_bar_width := get_width_of_line_count_bar();

	global_x := editor.pos.x - editor.scrollbar_pos.x + count_bar_width;
	global_y := editor.pos.y - editor.scrollbar_pos.y + 5;

	start_tab_offset := get_tab_offset(row, from_col);
	end_tab_offset   := get_tab_offset(row, to_col);
	
	x := global_x + from_col * FONT_SIZE_NORMAL + start_tab_offset;
	width := (cast(s64, to_col) - cast(s64, from_col)) * FONT_SIZE_NORMAL + (end_tab_offset - start_tab_offset) + end_padding;
	
	p2 := x + width;

	p2 = clamp(p2, count_bar_width + editor.pos.x, editor.editor_content_size.x + editor.pos.x);
	x  = clamp(x,  count_bar_width + editor.pos.x, editor.editor_content_size.x + editor.pos.x);
	
	width = p2 - x;
	
	y := global_y + row * FONT_SIZE_NORMAL;
	
	draw_rect(.{x, y}, .{width, FONT_SIZE_NORMAL}, settings.themes.platform_widget_bg_selected);
}

line_visible :: (row: s64) -> bool {
	first_visible_row: s64 = xx (editor.scrollbar_pos.y / FONT_SIZE_NORMAL);
	last_visible_row:  s64 = xx ((editor.scrollbar_pos.y + editor.editor_content_size.y - editor.TOP_PADDING) / FONT_SIZE_NORMAL);
	
	return first_visible_row <= row && row < last_visible_row;
}

draw_code_editor :: () {
	offset :: Vec2.{10, 74};

	editor.pos = offset;
	editor.size = .{vp.width - START_SCREEN_WIDTH / 2.0 + 20, vp.height - 84.0};

	draw_rect(editor.pos, editor.size, settings.themes.platform_background);

	char_per_lines := floor_positive(editor.size.x / 16) - 2;

	scroll_size := editor.size + .{(editor.visually_longest_line + 1) * FONT_SIZE_NORMAL, editor.rows_length.count * FONT_SIZE_NORMAL};

	min_size: Vec2 = ---;
	min_size.x = (char_per_lines - 0) * FONT_SIZE_NORMAL;
	
	if settings.editor.lock_content_view {
		visible_lines := floor_positive((editor.size.y - 8) / 16);
		min_size.y = visible_lines * FONT_SIZE_NORMAL;
	} else {
		min_size.y = FONT_SIZE_NORMAL;
	}

	x_visible := min_size.x + editor.size.x < scroll_size.x;
	draw_line_count_bar(x_visible);

	// caret
	if editor.file_path {
		w := get_width_of_line_count_bar();

		x_offset := get_tab_offset(editor.caret_row, editor.caret_col);
		
		global_x := editor.pos.x - editor.scrollbar_pos.x + w;
		global_y := editor.pos.y - editor.scrollbar_pos.y + editor.TOP_PADDING;
		
		x := global_x + editor.caret_col * FONT_SIZE_NORMAL + x_offset;
		y := global_y + editor.caret_row * FONT_SIZE_NORMAL;

		size := editor.editor_content_size;
		if editor.pos.y < y && y <= (editor.pos.y + size.y - FONT_SIZE_NORMAL) {
			draw_rect(.{editor.pos.x + w, y}, .{editor.size.x - w, FONT_SIZE_NORMAL}, settings.themes.platform_widget_bg_normal);
			
			if (editor.pos.x + w) <= x && x < (editor.pos.x + size.x) && editor.focused {
				time := (ms_since_init() - editor.caret_time) % 1000;
				if time < 500 then draw_rect(.{x, y}, .{1, FONT_SIZE_NORMAL}, .{255, 255, 255, 255});
			}
		}
		
		// draw selection
		if editor.caret_row != editor.caret_row_selection {
			start_col: u32 = ---;
			end_col:   u32 = ---;
			
			start_row := min(editor.caret_row, editor.caret_row_selection);
			end_row := max(editor.caret_row, editor.caret_row_selection);
			
			if editor.caret_row < editor.caret_row_selection {
				// reverse selection
				start_col = editor.caret_col;
				end_col   = editor.caret_col_selection;
			}
			if editor.caret_row > editor.caret_row_selection {
				// forward selection
				start_col = editor.caret_col_selection;
				end_col   = editor.caret_col;
			}
			
			for row: start_row .. cast(s64, end_row) {
				// Todo - Quattro - perf - iter only the visible rows
				if !line_visible(row) then continue;
				
				if row == start_row {
					draw_selected_line(start_row, start_col, editor.rows_length[start_row], FONT_SIZE_SMALL);
				} else if row == end_row {
					draw_selected_line(end_row, 0, end_col);
				} else {
					draw_selected_line(xx row, 0, editor.rows_length[row], FONT_SIZE_SMALL);
				}
			}
		} else {
			draw_selected_line(editor.caret_row, editor.caret_col, editor.caret_col_selection);
		}
	}
	
	draw_colored_text(x_visible);
	
	true_size := draw_scrollbar(editor.pos, editor.size, *editor.scrollbar_pos, scroll_size, min_size, settings.platform.code_cursor_speed_slow, settings.platform.code_cursor_speed_fast);
	editor.editor_content_size = true_size;

	// This panel has special interactions, so, instead of making a
	// new procedure, we put the fancy stuff here.
	// The interactions in particular:
	// - adds "..." at the end if the file name is too long
	// - adds "*" at the beginning of the file if it's not saved
	
	draw_rect(editor.pos, .{1, editor.size.y}, settings.themes.platform_line);
	draw_rect(editor.pos + .{0, editor.size.y - 1}, .{editor.size.x, 1}, settings.themes.platform_line);
	draw_rect(editor.pos + .{editor.size.x - 1, 0}, .{1, editor.size.y}, settings.themes.platform_line);

	text := editor.file_name;
	m := measure_text(text, FONT_SIZE_SMALL);
	p :: 4;

	draw_rect(editor.pos, .{p, 1}, settings.themes.platform_line);
	
	unsaved_offset := p + 4.0;
	
	if editor.size.x - 36 < m.x {
		p2 :: 3 * FONT_SIZE_SMALL;
	
		characters_to_display := cast(s64, (editor.size.x - 60) / FONT_SIZE_SMALL);
		text.count = characters_to_display;
		
		offx := characters_to_display * FONT_SIZE_SMALL;

		linex := p + 8 + offx + p2;
		linew := editor.size.x - p - 8 - offx - p2;
		
		if editor.file_edited {
			linex += FONT_SIZE_SMALL;
			linew -= FONT_SIZE_SMALL;
		}
		
		draw_rect(editor.pos + .{linex, 0}, .{linew, 1}, settings.themes.platform_line);
		draw_text("...", editor.pos + .{p + 4 + offx, -m.y / 2}, FONT_SIZE_SMALL, settings.themes.platform_line);
		
		unsaved_offset += offx + 3 * FONT_SIZE_SMALL;
	} else {
		linex := p + 8 + m.x;
		linew := editor.size.x - p - 8 - m.x;
		
		if editor.file_edited {
			linex += FONT_SIZE_SMALL;
			linew -= FONT_SIZE_SMALL;
		}
		
		draw_rect(editor.pos + .{linex, 0}, .{linew, 1}, settings.themes.platform_line);
		
		unsaved_offset += m.x;
	}
	
	draw_text(text, editor.pos + .{p + 4, -m.y / 2}, FONT_SIZE_SMALL, settings.themes.platform_line);
	if editor.file_edited {
		draw_character(#char "*", editor.pos + .{unsaved_offset, -m.y / 2}, FONT_SIZE_SMALL, settings.themes.platform_line);
	}
}

draw_RAM_content :: (offset: Vec2, start: s64, end: s64, pos_y: f32, height: f32) {
	chars :: "0123456789ABCDEF";

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
		draw_u32_internal :: (y: s64, data: u32, byte_offset: s64, draw_offset: Vec2) {
			fetch_color :: (y: s64, x: s64, data: u8) -> Col {
				col: Col = ---;
				
				if 16 <= y && y < 32 {
					col = ifx data then settings.themes.memory_stack_used else settings.themes.memory_stack_empty;
				} else if 32 <= y && y < 632 {
					col = ifx data then settings.themes.memory_display_used else settings.themes.memory_display_empty;
				} else if y == 632 && x < 14 {
					col = settings.themes.memory_input;
				} else if data {
					col = settings.themes.memory_normal_used;
				} else {
					col = settings.themes.memory_normal_empty;
				}
				
				return col;
			}
			
			b1 := (data >>  0) & 0xFF;
			b2 := (data >>  8) & 0xFF;
			b3 := (data >> 16) & 0xFF;
			b4 := (data >> 24) & 0xFF;
			
			c1 := fetch_color(y, byte_offset + 0, cast,no_check(u8, b1));
			c2 := fetch_color(y, byte_offset + 1, cast,no_check(u8, b2));
			c3 := fetch_color(y, byte_offset + 2, cast,no_check(u8, b3));
			c4 := fetch_color(y, byte_offset + 3, cast,no_check(u8, b4));
			
			lo1 := (b1 >> 0) & 0xF;
			hi1 := (b1 >> 4) & 0xF;
			lo2 := (b2 >> 0) & 0xF;
			hi2 := (b2 >> 4) & 0xF;
			lo3 := (b3 >> 0) & 0xF;
			hi3 := (b3 >> 4) & 0xF;
			lo4 := (b4 >> 0) & 0xF;
			hi4 := (b4 >> 4) & 0xF;
			
			draw_character(chars[hi1], draw_offset + .{55.0 + (byte_offset + 0) * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, c1, range_check = false);
			draw_character(chars[lo1], draw_offset + .{71.0 + (byte_offset + 0) * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, c1, range_check = false);
			draw_character(chars[hi2], draw_offset + .{55.0 + (byte_offset + 1) * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, c2, range_check = false);
			draw_character(chars[lo2], draw_offset + .{71.0 + (byte_offset + 1) * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, c2, range_check = false);
			draw_character(chars[hi3], draw_offset + .{55.0 + (byte_offset + 2) * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, c3, range_check = false);
			draw_character(chars[lo3], draw_offset + .{71.0 + (byte_offset + 2) * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, c3, range_check = false);
			draw_character(chars[hi4], draw_offset + .{55.0 + (byte_offset + 3) * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, c4, range_check = false);
			draw_character(chars[lo4], draw_offset + .{71.0 + (byte_offset + 3) * (32 + 4), 4.0 + y * 16}, FONT_SIZE_NORMAL, c4, range_check = false);
		}
		
		data_lo: u64 = ---;
		data_hi: u64 = ---;
		{
			// used to grant 8-byte aligntment
			ptr_lo := cast(*u64, y * 16 + engine.RAM.data);
			ptr_hi := cast(*u64, y * 16 + engine.RAM.data + 8);
			
			data_lo = ptr_lo.*;
			data_hi = ptr_hi.*;
		}
		
		draw_u32_internal(y, cast,no_check(u32, (data_lo >>  0) & 0xFFFFFFFF),  0, offset);
		draw_u32_internal(y, cast,no_check(u32, (data_lo >> 32) & 0xFFFFFFFF),  4, offset);
		draw_u32_internal(y, cast,no_check(u32, (data_hi >>  0) & 0xFFFFFFFF),  8, offset);
		draw_u32_internal(y, cast,no_check(u32, (data_hi >> 32) & 0xFFFFFFFF), 12, offset);
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

	rows_on_screen := floor_positive((size.y - 8) / FONT_SIZE_NORMAL);
	scroll_pos     := Scrollbar_Vector.{0, ui.memory_scrollbar_pos};
	min_size       := Vec2.{0, 0};

	draw_scrollbar(pos, size, *scroll_pos, .{0, 2048 * 16}, min_size, settings.platform.memory_cursor_speed_slow, settings.platform.memory_cursor_speed_fast);

	ui.memory_scrollbar_pos = scroll_pos.y;

	offset := pos + .{2, -cast(f32, ui.memory_scrollbar_pos)};
	start: s64 = xx ((ui.memory_scrollbar_pos) / FONT_SIZE_NORMAL);
	end:   s64 = xx ((ui.memory_scrollbar_pos + size.y - 24) / FONT_SIZE_NORMAL);
	draw_RAM_content(offset, start, end, pos.y, size.y);

	draw_panel("memory", pos, size);
}

draw_program_registers :: () {
	panel_internal :: (reg: string, val: $T, offset: Vec2, pos: Vec2, size: Vec2, $negative := false) {
		draw_panel(reg, offset + pos, size);

		s :: size_of(T);

		hex := formatInt(val, base = 16, minimum_digits = (#ifx s == 1 then 2 else 4));
		bin := formatInt(val, base =  2, minimum_digits = (#ifx s == 1 then 8 else 16));

		draw_text(tprint("0x%", hex), offset + pos + .{9,  8}, FONT_SIZE_NORMAL, settings.themes.general_text);
		draw_text(tprint("0b%", bin), offset + pos + .{9, 30}, FONT_SIZE_NORMAL, settings.themes.general_text);

		draw_text(tprint("%", val), offset + pos + .{9, 52}, FONT_SIZE_NORMAL, settings.themes.general_text);
		#if negative {
			draw_text(tprint("/ %", cast,no_check(s8, val)), offset + pos + .{73, 52}, FONT_SIZE_NORMAL, settings.themes.general_text);
		}
	}

	offset := Vec2.{vp.width + 40.0 - START_SCREEN_WIDTH / 2, vp.height + 95.0 - START_SCREEN_HEIGHT / 2};

	draw_panel("Registers", offset, .{START_SCREEN_WIDTH / 2 - 50, START_SCREEN_HEIGHT / 4 - 10});

	panel_internal("A", engine.A, offset, .{ 10, 15}, .{176, 76}, negative = true);
	panel_internal("X", engine.X, offset, .{196, 15}, .{176, 76}, negative = true);
	panel_internal("Y", engine.Y, offset, .{382, 15}, .{176, 76}, negative = true);

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
	if engine.debug && engine.running {
		if button("Step", offset + .{120, 13}, .{60, 25}, FONT_SIZE_SMALL) {
			next_instruction();
		}
	}

	draw_panel("Stack used", offset + .{10, 50}, .{170, 35});
	stack_used := (255.0 - engine.S) / 255;
	
	col := blend(settings.themes.general_debug_stack_full, settings.themes.general_debug_stack_empty, stack_used);

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

	data := engine.RAM[MEMORY_KEYBOARD];

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

	fmt :: #bake_arguments formatInt(minimum_digits = 3, padding = #char " ");

	     if freq < kHz(1) str = tprint(" %Hz", fmt(freq));
	else if freq < MHz(1) str = tprint("%kHz", fmt(freq / 1_000));
	else if freq < GHz(1) str = tprint("%MHz", fmt(freq / 1_000_000));
	else                  str = tprint("%GHz", fmt(freq / 1_000_000_000));

	// A fast approach rather than using array_find.
	// Note that bit_scan_reverse returns the index, except for the 12 and the 22.
	freqs :: s64.[
		            1,           2,           5,
		           10,          20,          50,
		          100,         200,         500,
		        1_000,       2_000,       5_000,
		       10_000,      20_000,      50_000,
		      100_000,     200_000,     500_000,
		    1_000_000,   2_000_000,   5_000_000,
		   10_000_000,  20_000_000,  50_000_000,
		  100_000_000, 200_000_000, 500_000_000,
		1_000_000_000
	];
	
	idx := bit_scan_reverse(freq) - 1;  // zero-normalized
	idx -= cast(s32, idx >= 21);
	idx -= cast(s32, idx >= 11);
	
	draw_step_hslider(offset + .{20, 55}, .{160, 20}, freqs.count, *idx, disabled = engine.metrics.unlock);
	engine.metrics.update_rate = freqs[idx];

	draw_text(str, offset + .{90, 16}, FONT_SIZE_NORMAL, ifx engine.metrics.unlock then settings.themes.platform_disabled else settings.themes.platform_text_normal);
}
