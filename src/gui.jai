draw_header :: () {
	h :: HEADER_HEIGHT;
	
	draw_rect(.{0, 0}, .{xx vp.width, h}, 0, COLOR_BACKGROUND);
	draw_rect_lines(.{0, 0}, .{xx vp.width, xx vp.height}, 1, COLOR_LINE);
	draw_rect(.{0, h - 1}, .{xx vp.width, 1}, 1, COLOR_LINE);
	
	draw_text("6502 Simulator", .{10, 4}, 1, 3, WHITE);
	
	// Todo - use this only after disabling windows header
	/*if button(.CLOSE, .{cast(float)vp.width - h, 0}, .{h, h}, 1, 2) {
		exit(0);
	}
	if button(.MAXIMIZE, .{cast(float)vp.width - h * 2, 0}, .{h, h}, 1, 2) {
		// Todo - switch between maximize and minimize
	}
	if button(.REDUCE, .{cast(float)vp.width - h * 3, 0}, .{h, h}, 1, 2) {
		
	}*/
}

draw_buttons_controls :: () {
	t :: 1;
	if !engine.thread_running {
		if button("Compile and run", .{10, 40}, .{170, 25}, 1, t) {
			log_info("Compile and run");
		}
		if button("Compile", .{190, 40}, .{100, 25}, 1, t) {
			
		}
		if engine.compilation_successful && button("Run", .{300, 40}, .{60, 25}, 1, t) {
			
		}
	} else {
		// we're doing this just to update the variable the next cycle
		running := engine.running;
		if !engine.in_debug {
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
		if button("Stop", .{10, 40}, .{80, 25}, 1, t) {
			cpu_stop();
			cpu_reset();
		}
		engine.running = running;
	}
}

draw_code_viewer :: () {
	offset :: Vec2.{10, 74};
	// Todo - for the scissoring effect, take a look at this
	// https://stackoverflow.com/questions/53287628/directx-11-render-to-specific-area
	
	engine.code_viewer_pos = offset;
	engine.code_viewer_size = .{vp.width - MIN_SCREEN_WIDTH / 2.0, vp.height - 84.0};
	
	draw_panel("test", engine.code_viewer_pos, engine.code_viewer_size, 1);
	draw_rect(engine.code_viewer_pos, engine.code_viewer_size, 0, COLOR_BACKGROUND);
}

draw_program_memory :: () {
	pos:  Vec2 = .{vp.width + 20.0 - MIN_SCREEN_WIDTH / 2, 74};
	size: Vec2 = .{MIN_SCREEN_WIDTH / 2 - 30.0, vp.height - MIN_SCREEN_HEIGHT / 2 - 15.0};
	
	draw_panel("Memory", pos, size, 2);
	draw_rect(pos, size, 0, COLOR_BACKGROUND);
	
	draw_rect(pos, .{70, size.y}, 1, COLOR_BASE_NORMAL);
}

draw_program_registers :: () {
	panel_internal :: (reg: string, val: $T, offset: Vec2, pos: Vec2, size: Vec2, layer: float) {
		draw_panel(reg, offset + pos, size, layer);
		
		s :: size_of(T);
		
		hex := formatInt(val, base = 16, minimum_digits = (#ifx s == 1 then 2 else 4));
		bin := formatInt(val, base =  2, minimum_digits = (#ifx s == 1 then 8 else 16));
		
		draw_text(tprint("0x%", hex), offset + pos + .{10, 12}, 1, layer, WHITE);
		draw_text(tprint("0b%", bin), offset + pos + .{10, 32}, 1, layer, WHITE);
		draw_text(tprint("%",   val), offset + pos + .{10, 52}, 1, layer, WHITE);
	}
	
	layer :: 1;
	offset := Vec2.{vp.width + 20.0 - MIN_SCREEN_WIDTH / 2, vp.height + 70.0 - MIN_SCREEN_HEIGHT / 2};
	
	draw_panel("Registers", offset, .{MIN_SCREEN_WIDTH / 2 - 30, MIN_SCREEN_HEIGHT / 4 - 25}, layer);

	panel_internal("A", engine.A, offset, .{10, 15}, .{125, 70}, layer);
	panel_internal("X", engine.X, offset, .{145, 15}, .{125, 70}, layer);
	panel_internal("Y", engine.Y, offset, .{280, 15}, .{125, 70}, layer);
	// {
		// draw_panel("Key", offset + .{415, 15}, .{85, 50}, layer);
	// }
	
	panel_internal("PC", engine.PC, offset, .{10, 95}, .{210, 70}, layer);
	panel_internal("S", engine.S, offset, .{230, 95}, .{125, 70}, layer);
	{
		draw_panel("Executing", offset + .{365, 130}, .{135, 35}, layer);
	}
	{
		draw_panel("Flags", offset + .{510, 15}, .{150, 150}, layer);
		draw_text("N:", offset + .{520, 25},  layer, 1, WHITE);
		draw_text("V:", offset + .{520, 45},  layer, 1, WHITE);
		draw_text("B:", offset + .{520, 65},  layer, 1, WHITE);
		draw_text("D:", offset + .{520, 85},  layer, 1, WHITE);
		draw_text("I:", offset + .{520, 105}, layer, 1, WHITE);
		draw_text("Z:", offset + .{520, 125}, layer, 1, WHITE);
		draw_text("C:", offset + .{520, 145}, layer, 1, WHITE);
		using engine.flags;
		draw_text(tprint("% / %", cast(u8)N, N), offset + .{545, 25},  layer, 1, ifx N then GREEN else RED);
		draw_text(tprint("% / %", cast(u8)V, V), offset + .{545, 45},  layer, 1, ifx V then GREEN else RED);
		draw_text(tprint("% / %", cast(u8)B, B), offset + .{545, 65},  layer, 1, ifx B then GREEN else RED);
		draw_text(tprint("% / %", cast(u8)D, D), offset + .{545, 85},  layer, 1, ifx D then GREEN else RED);
		draw_text(tprint("% / %", cast(u8)I, I), offset + .{545, 105}, layer, 1, ifx I then GREEN else RED);
		draw_text(tprint("% / %", cast(u8)Z, Z), offset + .{545, 125}, layer, 1, ifx Z then GREEN else RED);
		draw_text(tprint("% / %", cast(u8)C, C), offset + .{545, 145}, layer, 1, ifx C then GREEN else RED);
	}
}

draw_program_debug :: () {
	offset := Vec2.{vp.width + 20.0 - MIN_SCREEN_WIDTH / 2, vp.height - MIN_SCREEN_HEIGHT / 4 + 55.0};
	
	// draw_panel("Debug", offset, .{MIN_SCREEN_WIDTH / 2 - 450.0, MIN_SCREEN_HEIGHT / 4 - 65.0}, 1);
	draw_panel("Debug", offset, .{MIN_SCREEN_WIDTH / 2 - 240.0, MIN_SCREEN_HEIGHT / 4 - 65.0}, 1);
	
	checkbox(*engine.in_debug, "Enable debug", offset + .{15, 15}, .{20, 20}, 1);
	if engine.in_debug && engine.thread_running {
		if button("Step", offset + .{170, 13}, .{60, 25}, 1, 1) {
			next_instruction();
		}
	}
	
	draw_panel("Stack used", offset + .{10, 90}, .{200, 35}, 1);
	stack_used := (255.0 - engine.S) / 255;
	col: Col = stack_used * RED + (1 - stack_used) * GREEN;
	
	ff := formatFloat(stack_used * 100, trailing_width = 1, zero_removal = .NO);
	
	draw_text(tprint("%\% - % / 255B", ff, 255 - engine.S), offset + .{20, 103}, 1, 1, col);
}

draw_program_frequency :: () {
	offset := Vec2.{vp.width - 210.0, vp.height - MIN_SCREEN_HEIGHT / 4 + 55.0};
	draw_panel("Frequency", offset, .{200, MIN_SCREEN_HEIGHT / 4 - 65.0}, 1);
	
	checkbox(*engine.unlock, "unlock", offset + .{10, 15}, .{20, 20}, 1);
	
	str: string;
	if !engine.unlock {
		freq := engine.update_rate;
		if freq < kHz(1) {
			str = tprint("Freq: %Hz", freq);
		} else if freq < MHz(1) {
			str = tprint("Freq: %kHz", freq / 1_000);
		} else if freq < GHz(1) {
			str = tprint("Freq: %MHz", freq / 1_000_000);
		} else {
			str = tprint("Freq: %GHz", freq / 1_000_000_000);
		}
		
		if button(.LEFT_ARROW, offset + .{130, 40}, .{20, 20}, 1, 1) && engine.update_rate > 1{
			v := tprint("%", engine.update_rate);
			if v[0] == {
				case #char "1"; engine.update_rate /= 2;
				case #char "2"; engine.update_rate /= 2;
				case #char "5"; engine.update_rate = engine.update_rate / 5 * 2;
			}
		}
		if button(.RIGHT_ARROW, offset + .{150, 40}, .{20, 20}, 1, 1) && engine.update_rate < GHz(10) {
			v := tprint("%", engine.update_rate);
			if v[0] == {
				case #char "1"; engine.update_rate *= 2;
				case #char "2"; engine.update_rate = engine.update_rate / 2 * 5;
				case #char "5"; engine.update_rate *= 2;
			}
		}
	}
	
	draw_text(str, offset + .{10, 45}, 1, 1, COLOR_TEXT_NORMAL);
}
