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
	layer :: 1;
	offset := Vec2.{vp.width + 20.0 - MIN_SCREEN_WIDTH / 2, vp.height + 70.0 - MIN_SCREEN_HEIGHT / 2};
	
	draw_panel("Registers", offset, .{MIN_SCREEN_WIDTH / 2 - 30, MIN_SCREEN_HEIGHT / 4 - 25}, layer);
	{
		draw_panel("A", offset + .{10, 15}, .{125, 70}, layer);
	}
	{
		draw_panel("X", offset + .{145, 15}, .{125, 70}, layer);
	}
	{
		draw_panel("Y", offset + .{280, 15}, .{125, 70}, layer);
	}
	{
		draw_panel("Key", offset + .{415, 15}, .{85, 50}, layer);
	}
	{
		draw_panel("PC", offset + .{10, 95}, .{210, 70}, layer);
	}
	{
		draw_panel("S", offset + .{230, 95}, .{125, 70}, layer);
	}
	{
		draw_panel("Executing", offset + .{365, 130}, .{135, 35}, layer);
	}
	{
		draw_panel("Flags", offset + .{510, 15}, .{150, 150}, layer);
	}
}
