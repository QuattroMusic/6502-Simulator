read_ROM :: (name: string) {
	file, res := file_open(name);
	defer file_close(*file);
	if !res {
		ui.show_popup = true;
		ui.popup_title = "BIN error";
		ui.popup_error_type = .UNABLE_TO_OPEN_BINARY;
		return;
	}
	
	file_seek(file, 0, .END);
	result, size := file_tell(file);

	if size != ROM_SIZE {
		ui.show_popup = true;
		ui.popup_title = "ROM error";
		ui.popup_error_type = .INCOMPATIBLE_ROM_SIZE;
		return;
	}
	file_seek(file, 0, .START);
	
	res = file_read(file, engine.ROM.data, ROM_SIZE);
	if !res then log_error("huh?");
}

PC_advance :: (steps: u8) { engine.PC += steps; }
PC_jump    :: (addr: u16) { engine.PC  = addr;  }

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

handle_input_and_time :: () {
	time := current_time_consensus();
	calendar := to_calendar(time, .LOCAL);
	
	engine.RAM[MEMORY_YEAR_ADDRESS]            = cast,trunc(u8)(calendar.year & 0xFF);
	engine.RAM[MEMORY_YEAR_ADDRESS + 1]        = cast,trunc(u8)((calendar.year >> 8) & 0xFF);
	engine.RAM[MEMORY_MONTH_ADDRESS]           = cast,no_check(u8)calendar.month_starting_at_0;
	engine.RAM[MEMORY_DAY_ADDRESS]             = cast,no_check(u8)calendar.day_of_month_starting_at_0;
	engine.RAM[MEMORY_HOUR_ADDRESS]            = cast,no_check(u8)calendar.hour;
	engine.RAM[MEMORY_MINUTE_ADDRESS]          = cast,no_check(u8)calendar.minute;
	engine.RAM[MEMORY_SECOND_ADDRESS]          = cast,no_check(u8)calendar.second;
	engine.RAM[MEMORY_MILLISECOND_ADDRESS]     = cast,trunc(u8)(calendar.millisecond & 0xFF);
	engine.RAM[MEMORY_MILLISECOND_ADDRESS + 1] = cast,trunc(u8)((calendar.millisecond >> 8) & 0xFF);

	if !ui.display_visible then return;
	
	c := last_pressed_char;
	allowed_chars := (#char "A" <= c && c <= #char "Z") || 
		(KEY_LEFT <= c && c <= KEY_DOWN) ||
		c == KEY_SPACE ||
		#char "0" <= c && c <= #char "9";
	
	if allowed_chars && is_key_down(c) {
		engine.RAM[MEMORY_INPUT_ADDRESS] = c;
	} else {
		engine.RAM[MEMORY_INPUT_ADDRESS] = 0;
	}
}
