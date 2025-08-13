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

			internal_scroll :: ($text: string, pos: Vec2, var: *u8, y: f32) {
				draw_text(text, pos + .{20, y}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
				w :: #run measure_text(text, FONT_SIZE_NORMAL).x;

				edit := input_int(pos + .{40 + w, y}, s = FONT_SIZE_NORMAL, var, min_value = 1, max_value = 255, it = xx y);

				if edit then save_options_file();
			}

			h_separator("scrollbars", pos + .{10, 90}, SETTINGS_WIDTH - 20);

			internal_scroll("code editor slow speed",   pos, *settings.platform.code_cursor_speed_slow, 110);
			internal_scroll("code editor fast speed",   pos, *settings.platform.code_cursor_speed_fast, 135);
			internal_scroll("memory viewer slow speed", pos, *settings.platform.memory_cursor_speed_slow, 165);
			internal_scroll("memory viewer fast speed", pos, *settings.platform.memory_cursor_speed_fast, 190);
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
				ui.color_picker_edited = true;
			}
		case .EDITOR;
			{
				t :: "lock content view";
				s :: #run measure_text(t, FONT_SIZE_NORMAL).x + FONT_SIZE_NORMAL;
				draw_text(t, pos + .{20, 80}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
				edit := checkbox("", pos + .{20 + s, 80}, .{20, 20}, *settings.editor.lock_content_view);
				if edit then save_options_file();
			}
			
			t :: "Save";
			draw_text(t, pos + .{20, 50}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
			w :: #run measure_text(t, FONT_SIZE_NORMAL).x;

			edit := combo_box(pos + .{40 + w, 50 - 2}, .{250, 20}, *settings.editor.when_to_save);
			if edit then save_options_file();
			
			if settings.editor.when_to_save == .EVERY_MS {
				edit := input_int(pos + .{40 + w + 260, 50 - 2}, s = FONT_SIZE_NORMAL, *settings.editor.save_interval_in_ms, min_value = 1, max_value = 10000);
				if edit then save_options_file();
			}
			
	}
}

draw_cheatsheet :: (window: *Window) {
	pos := window.pos + .{0, WIDGET_HEADER_HEIGHT};
	
	tab_bar(pos + .{10, 10}, CHEATSHEET_WIDTH - 20, *ui.cheatsheet_tab);
	
	if #complete ui.cheatsheet_tab == {
		case .ISA;
			internal_text :: inline ($instruction: string, $addressing: string, $description: string, y: *f32, pos: Vec2, $$packed := false) {
				v := ui.cheatsheet_isa_scrollbar.y;
			
				// text + space
				s :: #run measure_text(instruction, FONT_SIZE_NORMAL).x + FONT_SIZE_NORMAL;
			
				lo := y.* - CHEATSHEET_HEIGHT + 120;
				hi := y.*;
			
				if lo <= v && v <= hi then draw_text(instruction, pos + .{ 20, 71 + y.* - v}, FONT_SIZE_NORMAL, settings.themes.viewer_instruction);
				#if addressing != "" {
					if !packed {
						if lo <= v && v <= hi then draw_text(addressing, pos + .{ 20 + s, 71 + y.* - v}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
					}
				}
				
				x := ifx packed then 94.0 else 190.0;
				if lo <= v && v <= hi then draw_text(description, pos + .{x, 71 + y.* - v}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
				y.* += 16.0;
			}
			internal_separator :: inline (y: *f32, pos: Vec2) {
				v := ui.cheatsheet_isa_scrollbar.y;
				
				if y.* - CHEATSHEET_HEIGHT + 120 <= v && v <= y.* then h_separator("", pos + .{15, 81 + y.* - v}, CHEATSHEET_WIDTH - 40);
				y.* += 16.0;
			}
			
			checkbox("packed", pos + .{14, 40}, .{20, 20}, *ui.cheatsheet_isa_packed_checkbox);
			
			packed := ui.cheatsheet_isa_packed_checkbox;
			internal_height := 16.0 * ifx packed then 89 else 184;
			
			draw_scrollbar(pos  + .{10, 66}, .{CHEATSHEET_WIDTH - 20, CHEATSHEET_HEIGHT - 100}, *ui.cheatsheet_isa_scrollbar, .{0, internal_height}, .{0, 0}, 1, 1);
			
			y := 0.0;
			
			internal_text("adc", "#n", "Add with carry to A", *y, pos, packed);
			if !packed {
				internal_text("adc", "nn",    "Add with carry to A", *y, pos);
				internal_text("adc", "n",     "Add with carry to A", *y, pos);
				internal_text("adc", "(n,x)", "Add with carry to A", *y, pos);
				internal_text("adc", "(n),y", "Add with carry to A", *y, pos);
				internal_text("adc", "n,x",   "Add with carry to A", *y, pos);
				internal_text("adc", "nn,x",  "Add with carry to A", *y, pos);
				internal_text("adc", "nn,y",  "Add with carry to A", *y, pos);
			} internal_separator(*y, pos);
			internal_text("and", "#n",    "AND to A", *y, pos, packed);
			if !packed {
				internal_text("and", "nn",    "AND to A", *y, pos);
				internal_text("and", "n",     "AND to A", *y, pos);
				internal_text("and", "(n,x)", "AND to A", *y, pos);
				internal_text("and", "(n),y", "AND to A", *y, pos);
				internal_text("and", "n,x",   "AND to A", *y, pos);
				internal_text("and", "nn,x",  "AND to A", *y, pos);
				internal_text("and", "nn,y",  "AND to A", *y, pos);
			} internal_separator(*y, pos);
			internal_text("asl", "nn",   "Arithmetic shift left", *y, pos, packed);
			if !packed {
				internal_text("asl", "n",    "Arithmetic shift left", *y, pos);
				internal_text("asl", "A",    "Arithmetic shift left", *y, pos);
				internal_text("asl", "n,x",  "Arithmetic shift left", *y, pos);
				internal_text("asl", "nn,x", "Arithmetic shift left", *y, pos);
			} internal_separator(*y, pos);
			internal_text("bcc", "n", "Branch if carry clear (C=0)", *y, pos, packed);
			internal_text("bcs", "n", "Branch if carry set   (C=1)", *y, pos, packed);
			internal_text("beq", "n", "Branch if equal       (Z=1)", *y, pos, packed);
			internal_text("bne", "n", "Branch if not equal   (Z=0)", *y, pos, packed);
			internal_text("bmi", "n", "Branch if minus       (N=1)", *y, pos, packed);
			internal_text("bpl", "n", "Branch if plus        (N=0)", *y, pos, packed);
			internal_text("bvc", "n", "Branch if ovfl clear  (V=0)", *y, pos, packed);
			internal_text("bvs", "n", "Branch if ovfl set    (V=1)", *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("bit", "nn", "AND with A (A unchanged)", *y, pos, packed);
			if !packed {
				internal_text("bit", "n",  "AND with A (A unchanged)", *y, pos);
			} internal_separator(*y, pos);
			internal_text("brk", "",  "Break (force interrupt)", *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("clc", "", "Clear carry",        *y, pos, packed);
			internal_text("cld", "", "Clear decimal mode", *y, pos, packed);
			internal_text("cli", "", "Clear IRQ disable",  *y, pos, packed);
			internal_text("clv", "", "Clear overflow",     *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("cmp", "#n",    "Compare with A", *y, pos, packed);
			if !packed {
				internal_text("cmp", "nn",    "Compare with A", *y, pos);
				internal_text("cmp", "n",     "Compare with A", *y, pos);
				internal_text("cmp", "(n,x)", "Compare with A", *y, pos);
				internal_text("cmp", "(n),y", "Compare with A", *y, pos);
				internal_text("cmp", "n,x",   "Compare with A", *y, pos);
				internal_text("cmp", "nn,x",  "Compare with A", *y, pos);
				internal_text("cmp", "nn,y",  "Compare with A", *y, pos);
			} internal_separator(*y, pos);
			internal_text("cpx", "#n", "Compare with X", *y, pos, packed);
			if !packed {
				internal_text("cpx", "nn", "Compare with X", *y, pos);
				internal_text("cpx", "n",  "Compare with X", *y, pos);
			} internal_separator(*y, pos);
			internal_text("cpy", "#n", "Compare with y", *y, pos, packed);
			if !packed {
				internal_text("cpy", "nn", "Compare with y", *y, pos);
				internal_text("cpy", "n",  "Compare with y", *y, pos);
			} internal_separator(*y, pos);
			internal_text("dec", "nn",   "Decrement by one", *y, pos, packed);
			if !packed {
				internal_text("dec", "n",    "Decrement by one", *y, pos);
				internal_text("dec", "n,x",  "Decrement by one", *y, pos);
				internal_text("dec", "nn,x", "Decrement by one", *y, pos);
			} internal_separator(*y, pos);
			internal_text("dex", "", "Decrement X by one", *y, pos, packed);
			internal_text("dey", "", "Decrement Y by one", *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("eor", "#n",    "XOR to A", *y, pos, packed);
			if !packed {
				internal_text("eor", "nn",    "XOR to A", *y, pos);
				internal_text("eor", "n",     "XOR to A", *y, pos);
				internal_text("eor", "(n,x)", "XOR to A", *y, pos);
				internal_text("eor", "(n),y", "XOR to A", *y, pos);
				internal_text("eor", "n,x",   "XOR to A", *y, pos);
				internal_text("eor", "nn,x",  "XOR to A", *y, pos);
				internal_text("eor", "nn,y",  "XOR to A", *y, pos);
			} internal_separator(*y, pos);
			internal_text("inc", "nn",   "Increment by one", *y, pos, packed);
			if !packed {
				internal_text("inc", "n",    "Increment by one", *y, pos);
				internal_text("inc", "n,x",  "Increment by one", *y, pos);
				internal_text("inc", "nn,x", "Increment by one", *y, pos);
			} internal_separator(*y, pos);
			internal_text("inx", "", "Increment X by one", *y, pos, packed);
			internal_text("iny", "", "Increment Y by one", *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("jmp", "nn",   "Jump to new location", *y, pos, packed);
			if !packed then internal_text("jmp", "(nn)", "Jump to new location", *y, pos);
			internal_separator(*y, pos);
			internal_text("jsr", "nn", "Jump to subroutine", *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("lda", "#n",    "Load A", *y, pos, packed);
			if !packed {
				internal_text("lda", "nn",    "Load A", *y, pos);
				internal_text("lda", "n",     "Load A", *y, pos);
				internal_text("lda", "(n,x)", "Load A", *y, pos);
				internal_text("lda", "(n),y", "Load A", *y, pos);
				internal_text("lda", "n,x",   "Load A", *y, pos);
				internal_text("lda", "nn,x",  "Load A", *y, pos);
				internal_text("lda", "nn,y",  "Load A", *y, pos);
			} internal_separator(*y, pos);
			internal_text("ldx", "#n",   "Load X", *y, pos, packed);
			if !packed {
				internal_text("ldx", "nn",   "Load X", *y, pos);
				internal_text("ldx", "n",    "Load X", *y, pos);
				internal_text("ldx", "nn,y", "Load X", *y, pos);
				internal_text("ldx", "n,y",  "Load X", *y, pos);
			} internal_separator(*y, pos);
			internal_text("ldy", "#n",   "Load Y", *y, pos, packed);
			if !packed {
				internal_text("ldy", "nn",   "Load Y", *y, pos);
				internal_text("ldy", "n",    "Load Y", *y, pos);
				internal_text("ldy", "n,x",  "Load Y", *y, pos);
				internal_text("ldy", "nn,x", "Load Y", *y, pos);
			} internal_separator(*y, pos);
			internal_text("lsr", "nn",   "Logical shift right", *y, pos, packed);
			if !packed {
				internal_text("lsr", "n",    "Logical shift right", *y, pos);
				internal_text("lsr", "A",    "Logical shift right", *y, pos);
				internal_text("lsr", "n,x",  "Logical shift right", *y, pos);
				internal_text("lsr", "nn,x", "Logical shift right", *y, pos);
			} internal_separator(*y, pos);
			internal_text("nop", "", "No operation", *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("ora", "#n",    "OR to A", *y, pos, packed);
			if !packed {
				internal_text("ora", "nn",    "OR to A", *y, pos);
				internal_text("ora", "n",     "OR to A", *y, pos);
				internal_text("ora", "(n,x)", "OR to A", *y, pos);
				internal_text("ora", "(n),y", "OR to A", *y, pos);
				internal_text("ora", "n,x",   "OR to A", *y, pos);
				internal_text("ora", "nn,x",  "OR to A", *y, pos);
				internal_text("ora", "nn,y",  "OR to A", *y, pos);
			} internal_separator(*y, pos);
			internal_text("pha", "", "Push       A onto stack", *y, pos, packed);
			internal_text("php", "", "Push       P onto stack", *y, pos, packed);
			internal_text("pla", "", "Pull (pop) A from stack", *y, pos, packed);
			internal_text("plp", "", "Pull (pop) P from stack", *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("rol", "nn",   "rotate left through carry", *y, pos, packed);
			if !packed {
				internal_text("rol", "n",    "rotate left through carry", *y, pos);
				internal_text("rol", "A",    "rotate left through carry", *y, pos);
				internal_text("rol", "n,x",  "rotate left through carry", *y, pos);
				internal_text("rol", "nn,x", "rotate left through carry", *y, pos);
			} internal_separator(*y, pos);
			internal_text("ror", "nn",   "rotate right through carry", *y, pos, packed);
			if !packed {
				internal_text("ror", "n",    "rotate right through carry", *y, pos);
				internal_text("ror", "A",    "rotate right through carry", *y, pos);
				internal_text("ror", "n,x",  "rotate right through carry", *y, pos);
				internal_text("ror", "nn,x", "rotate right through carry", *y, pos);
			} internal_separator(*y, pos);
			internal_text("rti", "", "return from interrupt",  *y, pos, packed);
			internal_text("rts", "", "return from subroutine", *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("sbc", "#n",    "Subtract with borrow from A", *y, pos, packed);
			if !packed {
				internal_text("sbc", "nn",    "Subtract with borrow from A", *y, pos);
				internal_text("sbc", "n",     "Subtract with borrow from A", *y, pos);
				internal_text("sbc", "(n,x)", "Subtract with borrow from A", *y, pos);
				internal_text("sbc", "(n),y", "Subtract with borrow from A", *y, pos);
				internal_text("sbc", "n,x",   "Subtract with borrow from A", *y, pos);
				internal_text("sbc", "nn,x",  "Subtract with borrow from A", *y, pos);
				internal_text("sbc", "nn,y",  "Subtract with borrow from A", *y, pos);
			} internal_separator(*y, pos);
			internal_text("sec", "", "Set carry",        *y, pos, packed);
			internal_text("sed", "", "Set decimal mode", *y, pos, packed);
			internal_text("sei", "", "Set IRQ disable",  *y, pos, packed);
			internal_separator(*y, pos);
			internal_text("sta", "nn",    "Store A", *y, pos, packed);
			if !packed {
				internal_text("sta", "n",     "Store A", *y, pos);
				internal_text("sta", "(n,x)", "Store A", *y, pos);
				internal_text("sta", "(n),y", "Store A", *y, pos);
				internal_text("sta", "n,x",   "Store A", *y, pos);
				internal_text("sta", "nn,x",  "Store A", *y, pos);
				internal_text("sta", "nn,y",  "Store A", *y, pos);
			} internal_separator(*y, pos);
			internal_text("stx", "nn",  "Store X", *y, pos, packed);
			if !packed {
				internal_text("stx", "n",   "Store X", *y, pos);
				internal_text("stx", "n,y", "Store X", *y, pos);
			} internal_separator(*y, pos);
			internal_text("sty", "nn",  "Store Y", *y, pos, packed);
			if !packed {
				internal_text("sty", "n",   "Store Y", *y, pos);
				internal_text("sty", "n,x", "Store Y", *y, pos);
			} internal_separator(*y, pos);
			internal_text("tax", "", "Transfer A to X", *y, pos, packed);
			internal_text("tay", "", "Transfer A to Y", *y, pos, packed);
			internal_text("tsx", "", "Transfer S to X", *y, pos, packed);
			internal_text("txa", "", "Transfer X to A", *y, pos, packed);
			internal_text("txs", "", "Transfer X to S", *y, pos, packed);
			internal_text("tya", "", "Transfer Y to A", *y, pos, packed);
			
			draw_rect_lines(pos + .{10, 66}, .{CHEATSHEET_WIDTH - 20, CHEATSHEET_HEIGHT - 100}, settings.themes.platform_line);
			draw_rect(pos + .{CHEATSHEET_WIDTH - WIDGET_SCROLLBAR_SIZE - 10, 66}, .{1, CHEATSHEET_HEIGHT - 100}, settings.themes.platform_line);
			
			x := ifx packed then 84.0 else 180.0;
			draw_rect(pos + .{x, 70}, .{1, CHEATSHEET_HEIGHT - 110}, settings.themes.platform_line);
		case .ADDRESSING;
			internal_text :: (text: string, pos: Vec2, y_off: f32) {
				lo := y_off - CHEATSHEET_HEIGHT + 120;
				hi := y_off;
				
				v := ui.cheatsheet_addressing_scrollbar.y;
				
				if lo <= v && v <= hi then draw_text(text, pos + .{0, y_off + 75 - v}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
			}
			internal_separator :: inline (y: *f32, pos: Vec2) {
				v := ui.cheatsheet_addressing_scrollbar.y;
				
				lo := y.* - CHEATSHEET_HEIGHT + 120;
				hi := y.*;
				
				if lo <= v && v <= hi then h_separator("", pos + .{15, 83 + y.* - v}, CHEATSHEET_WIDTH - 40);
				y.* += 16.0;
			}
			
			x1 :: 5 + 15;
			x2 :: 5 + 127;
			x3 :: 5 + 335;
			
			y := 0.0;
			
			draw_scrollbar(pos  + .{10, 66}, .{CHEATSHEET_WIDTH - 20, CHEATSHEET_HEIGHT - 100}, *ui.cheatsheet_addressing_scrollbar, .{0, 43 * FONT_SIZE_NORMAL}, .{0, 0}, 1, 1);
			draw_rect_lines(pos + .{10, 66}, .{CHEATSHEET_WIDTH - 20, CHEATSHEET_HEIGHT - 100}, settings.themes.platform_line);
			draw_rect(pos + .{CHEATSHEET_WIDTH - WIDGET_SCROLLBAR_SIZE - 10, 66}, .{1, CHEATSHEET_HEIGHT - 100}, settings.themes.platform_line);
			
			draw_rect(pos + .{x2 - 16, 70}, .{1, CHEATSHEET_HEIGHT - 110}, settings.themes.platform_line);
			draw_rect(pos + .{x3 - 16, 70}, .{1, CHEATSHEET_HEIGHT - 110}, settings.themes.platform_line);
			
			draw_text("form",        pos + .{x1, 40}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
			draw_text("Addressing",  pos + .{x2, 40}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
			draw_text("Description", pos + .{x3, 40}, FONT_SIZE_NORMAL, settings.themes.platform_text_normal);
			
			internal_text("nn",          pos + .{x1, 0}, y);
			internal_text("absolute",    pos + .{x2, 0}, y);
			internal_text("Location nn", pos + .{x3, 0}, y);  y += 16;
			internal_text("holds data",  pos + .{x3, 0}, y);  y += 16;
			internal_separator(*y, pos);
			
			internal_text("nn,x",          pos + .{x1, 0}, y);
			internal_text("absolute x",    pos + .{x2, 0}, y);
			internal_text("location nn+x", pos + .{x3, 0}, y); y += 16;
			internal_text("holds data",    pos + .{x3, 0}, y); y += 16;
			internal_separator(*y, pos);
			
			internal_text("nn,y", pos + .{x1, 0}, y);
			internal_text("absolute y", pos + .{x2, 0}, y);
			internal_text("location nn+y", pos + .{x3, 0}, y);  y += 16;
			internal_text("holds data", pos + .{x3, 0}, y);  y += 16;
			internal_separator(*y, pos);
			
			internal_text("A",          pos + .{x1, 0}, y);
			internal_text("Accumulator",    pos + .{x2, 0}, y);
			internal_text("Accumulator", pos + .{x3, 0}, y); y += 16;
			internal_text("holds data",    pos + .{x3, 0}, y); y += 16;
			internal_separator(*y, pos);
			
			internal_text("#n",          pos + .{x1, 0}, y);
			internal_text("Immediate",    pos + .{x2, 0}, y);
			internal_text("n is data", pos + .{x3, 0}, y); y += 16;
			internal_separator(*y, pos);
			
			internal_text("(n,x)",          pos + .{x1, 0}, y);
			internal_text("indirect x",    pos + .{x2, 0}, y);
			internal_text("location n+x and", pos + .{x3, 0}, y); y += 16;
			internal_text("next of page 0", pos + .{x3, 0}, y); y += 16;
			internal_text("hold address", pos + .{x3, 0}, y); y += 16;
			internal_text("of data", pos + .{x3, 0}, y); y += 16;
			internal_separator(*y, pos);
			
			internal_text("(n),y",          pos + .{x1, 0}, y);
			internal_text("indirect y",    pos + .{x2, 0}, y);
			internal_text("address of data is", pos + .{x3, 0}, y); y += 16;
			internal_text("y + address held", pos + .{x3, 0}, y); y += 16;
			internal_text("by location n and", pos + .{x3, 0}, y); y += 16;
			internal_text("next of page 0", pos + .{x3, 0}, y); y += 16;
			internal_separator(*y, pos);
			
			internal_text("(nn)",          pos + .{x1, 0}, y);
			internal_text("indirect",    pos + .{x2, 0}, y);
			internal_text("location nn and", pos + .{x3, 0}, y); y += 16;
			internal_text("next hold address", pos + .{x3, 0}, y); y += 16;
			internal_text("to jump to", pos + .{x3, 0}, y); y += 16;
			internal_separator(*y, pos);
			
			internal_text("n",          pos + .{x1, 0}, y);
			internal_text("relative",    pos + .{x2, 0}, y);
			internal_text("address to jump to", pos + .{x3, 0}, y); y += 16;
			internal_text("is n + address of", pos + .{x3, 0}, y); y += 16;
			internal_text("next instruction", pos + .{x3, 0}, y); y += 16;
			internal_text("with n treated as", pos + .{x3, 0}, y); y += 16;
			internal_text("a signed number", pos + .{x3, 0}, y); y += 16;
			internal_separator(*y, pos);
			
			internal_text("n",          pos + .{x1, 0}, y);
			internal_text("zero page",    pos + .{x2, 0}, y);
			internal_text("location n of page", pos + .{x3, 0}, y); y += 16;
			internal_text("0 holds data", pos + .{x3, 0}, y); y += 16;
			internal_separator(*y, pos);
			
			internal_text("n,x",          pos + .{x1, 0}, y);
			internal_text("zero page x",    pos + .{x2, 0}, y);
			internal_text("location n+x of", pos + .{x3, 0}, y); y += 16;
			internal_text("page 0 holds data", pos + .{x3, 0}, y); y += 16;
			internal_separator(*y, pos);
			
			internal_text("n,y",          pos + .{x1, 0}, y);
			internal_text("zero page y",    pos + .{x2, 0}, y);
			internal_text("location n+y of", pos + .{x3, 0}, y); y += 16;
			internal_text("page 0 holds data", pos + .{x3, 0}, y); y += 16;
	}
}
