read_ROM :: (name: string) {
	file, res := file_open(name);
	defer file_close(*file);
	if !res {
		display_error_window(.UNABLE_TO_OPEN_BINARY, "bin error");
		return;
	}
	
	size:, res = file_length(file);
	if size != ROM_SIZE {
		display_error_window(.INCOMPATIBLE_ROM_SIZE, "rom error");
		return;
	}
	
	res = file_read(file, engine.ROM.data, ROM_SIZE);
	if !res then log_error("An error occured while reading the ROM.");
}

PC_advance :: inline (steps: u8) { engine.PC += steps; }
PC_jump    :: inline (addr: u16) { engine.PC  = addr;  }

read_data :: (addr: u16) -> u8 {
	if addr < RAM_SIZE then return engine.RAM[addr];
	return engine.ROM[addr & (RAM_SIZE - 1)];
}

write_data :: (addr: u16, data: u8) {
	if addr >= RAM_SIZE {
		log_error("Cannot write in ROM space");
		return;
	}
	engine.RAM[addr] = data;
}

virtual_write_ROM :: (addr: u16, data: u8) {
	assert(addr >= RAM_SIZE);
	engine.ROM[addr & (RAM_SIZE - 1)] = data;
}

read_address :: (addr: u16) -> u16 {
	d1 := read_data(addr);
	d2 := read_data(addr + 1);
	return ((cast(u16)d2) << 8) | cast(u16)d1;
}

handle_time :: () {
	byte_control := engine.RAM[MEMORY_LOCK];
	if byte_control then return;

	time     := current_time_consensus();
	calendar := to_calendar(time, .LOCAL);
	
	hi_ptr_as_u64 := cast(*u64, engine.RAM.data + MEMORY_TIME_AND_INPUT_HI);
	
	hi: u64 = 0;
	// lock control should be left unchanged, but since we're here, it's zero.
	hi |= cast(u64, (calendar.year >> 0) & 0xFF)             << MEMORY_YEAR_OFFSET_LO;
	hi |= cast(u64, (calendar.year >> 8) & 0xFF)             << MEMORY_YEAR_OFFSET_HI;
	hi |= cast(u64, calendar.month_starting_at_0 + 1)        << MEMORY_MONTH_OFFSET;
	hi |= cast(u64, calendar.day_of_month_starting_at_0 + 1) << MEMORY_DAY_OFFSET;
	hi |= cast(u64, calendar.hour)                           << MEMORY_HOUR_OFFSET;
	hi |= cast(u64, calendar.minute)                         << MEMORY_MINUTE_OFFSET;
	hi |= cast(u64, calendar.second)                         << MEMORY_SECOND_OFFSET;
	hi_ptr_as_u64.* = hi;
	
	lo_ptr_as_u64 := cast(*u64, engine.RAM.data + MEMORY_TIME_AND_INPUT_LO);
	lo := lo_ptr_as_u64.*;
	
	lo &= ~(MEMORY_MILLI_LO_MASK | MEMORY_MILLI_HI_MASK);
	lo |= cast(u64, (calendar.millisecond >> 0) & 0xFF) << MEMORY_MILLI_OFFSET_LO;
	lo |= cast(u64, (calendar.millisecond >> 8) & 0xFF) << MEMORY_MILLI_OFFSET_HI;

	lo_ptr_as_u64.* = lo;
}

handle_input :: () {
	ptr := cast(*u64, engine.RAM.data + MEMORY_TIME_AND_INPUT_LO);
	
	if editor.focused {
		data := ptr.*;
		
		// left untouched common memory and milli
		data &= ~(MEMORY_KEYBOARD_MASK | MEMORY_MOUSE_X_MASK | MEMORY_MOUSE_Y_MASK | MEMORY_MOUSE_INPUT_MASK);
		
		ptr.* = data;
		return;
	}
	
	c := last_down_key;
	
	input_allowed_chars :=
		(#char "A" <= c && c <= #char "Z") || 
		(KEY_LEFT <= c && c <= KEY_DOWN)   ||
		c == KEY_SPACE                     ||
		#char "0" <= c && c <= #char "9";

	char: u8 = ifx is_key_down(c) && input_allowed_chars then c;
	
	{
		data := ptr.*;
		data &= ~MEMORY_KEYBOARD_MASK;
		data |= cast(u64, char) << MEMORY_KEYBOARD_OFFSET;
		ptr.* = data;
	}
	
	if ui.display_window.visible {
		pos      := ui.display_window.pos + .{4, 4} + .{0, WIDGET_HEADER_HEIGHT};  // 4 is padding
		delta    := Vec2.{xx mouse_x, xx mouse_y} - pos;
		relative := delta / FONT_SIZE_SMALL;
		
		x := floor(relative.x);
		y := floor(relative.y);
		input := cast(u64, is_mouse_down(0)) | (cast(u64, is_mouse_down(1)) << 1) | (cast(u64, is_mouse_down(2)) << 2);
		
		data := ptr.*;
		data &= ~(MEMORY_MOUSE_X_MASK | MEMORY_MOUSE_Y_MASK | MEMORY_MOUSE_INPUT_MASK);
		
		if x >= 0 && x < DISPLAY_WIDTH && y >= 0 && y < DISPLAY_HEIGHT {
			data |= cast(u64, x)     << MEMORY_MOUSE_X_OFFSET;
			data |= cast(u64, y)     << MEMORY_MOUSE_Y_OFFSET;
			data |= cast(u64, input) << MEMORY_MOUSE_INPUT_OFFSET;
		}
		
		ptr.* = data;
	}
}
