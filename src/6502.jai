Theming :: struct {
	// We're using the color picker in HSV.
	// At the end of the chain we're still converting the HSV to RGB for GPU reasons
	// hence, we're storing data as RGB
	general_text:              Col = .{240, 240, 220, 255};
	general_flag_off:          Col = .{202,  45,  31, 255};
	general_flag_on:           Col = .{ 59, 187,  20, 255};
	general_debug_stack_empty: Col = .{ 59, 187,  20, 255};
	general_debug_stack_full:  Col = .{202,  45,  31, 255};
	general_stack_focus:       Col = .{202,  45,  31, 255};
	
	platform_widget_bg_normal:     Col = .{ 73,  62,  51, 255};
	platform_widget_bg_hover:      Col = .{188, 126,  59, 255};
	platform_widget_bg_press:      Col = .{246, 164,  76, 255};
	platform_widget_border_normal: Col = .{196, 126,  43, 255};
	platform_widget_border_hover:  Col = .{ 49,  43,  40, 255};
	platform_widget_border_press:  Col = .{ 80,  77,  73, 255};
	platform_text_normal:          Col = .{246, 151,  48, 255};
	platform_text_hover:           Col = .{216, 210, 206, 255};
	platform_text_press:           Col = .{104,  95,  93, 255};
	platform_background:           Col = .{ 32,  30,  28, 255};
	platform_deep_background:      Col = .{ 10,  10,   5, 255};
	platform_line:                 Col = .{254, 170,  55, 255};
	platform_disabled:             Col = .{ 79,  85,  90, 255};
	
	viewer_text:        Col = .{240, 240, 220, 255};
	viewer_number:      Col = .{ 64, 104, 200, 255};
	viewer_comment:     Col = .{110, 110, 110, 255};
	viewer_dotdir:      Col = .{221, 119,  17, 255};
	viewer_label:       Col = .{234, 191,  21, 255};
	viewer_instruction: Col = .{130, 102, 193, 255};
	viewer_string:      Col = .{ 59, 187,  20, 255};
	
	memory_normal_empty:  Col = .{240, 240, 220, 255};
	memory_normal_used:   Col = .{ 59, 187,  20, 255};
	memory_stack_empty:   Col = .{130, 102, 193, 255};
	memory_stack_used:    Col = .{ 64, 104, 200, 255};
	memory_display_empty: Col = .{238, 210,   5, 255};
	memory_display_used:  Col = .{221, 119,  17, 255};
	memory_input:         Col = .{255, 110, 199, 255};
	
	display_col0:  Col = .{ 12,  12,  12, 255};
	display_col1:  Col = .{ 70,  70,  70, 255};
	display_col2:  Col = .{110, 110, 110, 255};
	display_col3:  Col = .{240, 240, 220, 255};
	display_col4:  Col = .{202,  45,  31, 255};
	display_col5:  Col = .{158,  97,  50, 255};
	display_col6:  Col = .{221, 119,  17, 255};
	display_col7:  Col = .{238, 210,   5, 255};
	display_col8:  Col = .{ 59, 187,  20, 255};
	display_col9:  Col = .{ 71, 148,  81, 255};
	display_col10: Col = .{ 64, 104, 200, 255};
	display_col11: Col = .{ 74, 145, 175, 255};
	display_col12: Col = .{ 51, 201, 187, 255};
	display_col13: Col = .{130, 102, 193, 255};
	display_col14: Col = .{170,  71, 204, 255};
	display_col15: Col = .{255, 110, 199, 255};
}

Platform_Settings :: struct {
	at_startup: enum u8 {
		EMPTY_FILE;
		LAST_FILE;
	} = .EMPTY_FILE;
	
	code_cursor_speed_slow: u8 = 3;
	code_cursor_speed_fast: u8 = 6;
	memory_cursor_speed_slow: u8 = 1;
	memory_cursor_speed_fast: u8 = 8;
}

Editor_Settings :: struct {
	when_to_save: enum u8 {
		MANUALLY;
		EACH_EDIT;
		WHEN_COMPILING;
		EVERY_MS;
	} = .WHEN_COMPILING;
	
	save_interval_in_ms: u16 = 200;
	
	lock_content_view: bool = false;
}

Settings :: struct {
	platform: Platform_Settings;
	
	themes:             Theming;
	themes_saved_state: Theming;
	
	editor: Editor_Settings;
}

General_UI :: struct {
	memory_scrollbar_pos: f32;

	modal_error_message: string;
	modal_error_type: Error_Type;

	settings_focused_tab: enum {
		PLATFORM;
		THEMING;
		EDITOR;
	}

	settings_platform_scrollbar_edited: bool;
	settings_theming_scroll_pos: Vec2;
	
	// color picker stuff
	internal_selected: *Col;
	internal_selected_saved_state: *Col;
	color_picker_edited: bool;

	cheatsheet_tab: enum {
		ISA;
		ADDRESSING;
	}
	
	cheatsheet_isa_scrollbar: Vec2;
	cheatsheet_isa_packed_checkbox: bool;
	cheatsheet_addressing_scrollbar: Vec2;

	display_window:    *Window;
	modal_window:      *Window;
	settings_window:   *Window;
	cheatsheet_window: *Window;
}

Error_Type :: enum {
	FAILED_COMPILATION;
	UNABLE_TO_OPEN_BINARY;
	INCOMPATIBLE_ROM_SIZE;
	ERROR_OPENING_FILE;
	READING_FILE_TIMED_OUT;
	NO_INPUT_FILE_GIVEN;
	GIVEN_FILE_NOT_VALID;
	UNABLE_TO_FIND_COMPILER;
}

Color_Tokens :: enum u8 {
	INSTRUCTION;
	COMMENT;
	NUMBER;
	DOTDIR;
	LABEL;
	STRING;
	TEXT;
}

Code_Editor :: struct {
	pos:                 Vec2;
	size:                Vec2;
	scrollbar_pos:       Vec2;
	editor_content_size: Vec2;

	file_path: string;
	file_name: string;  // string view
	
	content:     [..]  u8;
	rows_length: [..] u32;
	
	longest_line: u32;
	visually_longest_line: u32;
	row_digits:   u32;
	
	caret_row:  u32 = 0;
	caret_col:  u32 = 0;
	caret_time: s64 = 0;
	
	// coloring, stored as SoA
	text_index:  [..] u32;
	text_length: [..] u32;
	text_line:   [..] u32;
	text_column: [..] u32;
	text_color:  [..] Color_Tokens;
	
	focused: bool;
	
	// when it's set to save every x milliseconds
	asked_to_save: bool;
	last_saved_time: s64;
}

Status_Flags :: struct {
	// Todo - Quattro - Maybe i could just use a single aligned u8.
	// But I need to check for performance first
	N: bool #align 8;
	V: bool #align 8;
	B: bool #align 8;
	D: bool #align 8;
	I: bool #align 8;
	Z: bool #align 8;
	C: bool #align 8;
}

Emulator :: struct {
	// Atomic values needs to be 8 byte aligned on x64 machines.
	// Note that rather filling the whole program with `atomic_read` or `atomic_write`
	// we're just aligning the data.
	// If you look at the implementation, it's just a common read or write.

	ROM: [ROM_SIZE] u8 = --- #align 8;
	RAM: [RAM_SIZE] u8 = --- #align 8;
	
	A:  u8  #align 8;
	X:  u8  #align 8;
	Y:  u8  #align 8;
	S:  u8  #align 8;
	PC: u16 #align 8;

	compilation_successful: bool;
	current_instruction: Opcode #align 8;

	flags: Status_Flags;

	cpu_thread: Thread;
	metrics: struct {
		update_rate: s64 = 1_000 #align 8;
		last_counter: s64;

		unlock: bool #align 8;
	};

	paused:  bool #align 8;
	debug:   bool #align 8;
	running: bool #align 8;
}

Hz  :: (f: type_of(engine.metrics.update_rate)) -> type_of(engine.metrics.update_rate) { return f; }
kHz :: (f: type_of(engine.metrics.update_rate)) -> type_of(engine.metrics.update_rate) { return f * 1_000; }
MHz :: (f: type_of(engine.metrics.update_rate)) -> type_of(engine.metrics.update_rate) { return f * 1_000_000; }
GHz :: (f: type_of(engine.metrics.update_rate)) -> type_of(engine.metrics.update_rate) { return f * 1_000_000_000; }

bit :: (n: s64, i: s64) -> u8 { return cast(u8)((n >> i) & 1); }

set_overflow :: (n1: u8, n2: u8, res: u16) { engine.flags.V = (bit(n1, 7) == bit(n2, 7)) && (bit(n2, 7) != bit(res, 7)); }

branch_if :: (relative: s8, cond: bool) {
	PC_advance(1);
	addr := cast,no_check(u16)(cast(s32)engine.PC + relative);
	if cond then PC_jump(addr);
}

stack_push :: (data: u8) {
	write_data(0x0100 + cast(u16)engine.S, data);
	engine.S -= 1;
}

stack_pop :: () -> u8 {
	engine.S += 1;
	data := read_data(cast(u16)0x0100 + cast(u16)engine.S);
	return data;
}

update_N_and_Z :: (data: u8) {
	engine.flags.N = cast(bool)bit(data, 7);
	engine.flags.Z = (data == 0);
}

pack_P :: () -> u8 {
	n1 := (cast(u8)engine.flags.C) << 0;
	n2 := (cast(u8)engine.flags.Z) << 1;
	n3 := (cast(u8)engine.flags.I) << 2;
	n4 := (cast(u8)engine.flags.D) << 3;
	n5 := (cast(u8)engine.flags.B) << 4;
	n6 := (cast(u8)engine.flags.V) << 6;
	n7 := (cast(u8)engine.flags.N) << 7;

	return n1 | n2 | n3 | n4 | n5 | n6 | n7;
}

unpack_P :: (data: u8) {
	engine.flags.N = cast(bool)((data >> 7) & 1);
	engine.flags.V = cast(bool)((data >> 6) & 1);
	engine.flags.B = cast(bool)((data >> 4) & 1);
	engine.flags.D = cast(bool)((data >> 3) & 1);
	engine.flags.I = cast(bool)((data >> 2) & 1);
	engine.flags.Z = cast(bool)((data >> 1) & 1);
	engine.flags.C = cast(bool)((data >> 0) & 1);
}

cpu_stop :: () {
	engine.paused = true;
	engine.running = false;
	
	engine.current_instruction = 0xFF;  // intentionally out of range
}

cpu_reset :: ($virtual := false) {
	memset(engine.RAM.data, 0, RAM_SIZE);
	memset(*engine.flags, 0, size_of(Status_Flags));
	engine.PC = #ifx virtual then 0x8000 else 0xFFFC;
	engine.S = 0xFF;
	engine.A = 0;
	engine.X = 0;
	engine.Y = 0;
	
	engine.current_instruction = 0xFF;  // intentionally out of range
}

cpu_init :: ($virtual := false) {
	memset(engine.ROM.data, 0, ROM_SIZE);
	memset(engine.RAM.data, 0, RAM_SIZE);
	memset(*engine.flags, 0, size_of(Status_Flags));
	engine.PC = #ifx virtual then 0x8000 else 0xFFFC;
	engine.S = 0xFF;
	engine.A = 0;
	engine.X = 0;
	engine.Y = 0;
	
	engine.current_instruction = 0xFF;  // intentionally out of range
}

next_instruction :: () {
	intrinsic := read_data(engine.PC);
	PC_advance(1);
	exec_operation(xx intrinsic);
}

cpu_start :: () {
	threaded_func :: (t: *Thread) -> s64 {
		handle_time();
		
		PC_jump(read_address(engine.PC));
		while engine.running {
			if !engine.metrics.unlock then lock_frame_rate_6502();
			if !engine.paused && !engine.debug then next_instruction();
		}
		
		focused_uuid = 0;  // some sorta cheat
		
		// Todo - Quattro - Maybe find a way to pause the thread instead of init-deinit
		thread_deinit(*engine.cpu_thread);
		return 0;
	}

	if !engine.running {
		engine.running = true;
		engine.paused = false;
		thread_init(*engine.cpu_thread, threaded_func);
		thread_start(*engine.cpu_thread);
	}
}

lock_frame_rate_6502 :: () {
	lock_frame_rate(cast(f32, engine.metrics.update_rate), engine.metrics.last_counter);
    QueryPerformanceCounter(*engine.metrics.last_counter);
}

compile_program :: () {
	compiler_path := tprint(get_asset_path("vasm6502_oldstyle.exe"));
	out_path := tprint(get_asset_path("out.bin"));
	
	file, success := file_open(compiler_path);  // Todo - robustness
	defer file_close(*file);
	if !success {
		display_error_window(.UNABLE_TO_FIND_COMPILER, "no compiler found");
		return;
	}

	if !editor.file_path {
		display_error_window(.NO_INPUT_FILE_GIVEN, "no input file");
		return;
	}

	path := get_absolute_path(editor.file_path,, temp);
	
	if settings.editor.when_to_save == .WHEN_COMPILING then save_editor_file();
	
	fmt := tprint("% -Fbin -o \"%\" -dotdir \"%\"", compiler_path, out_path, path);
	
	out := break_command_into_strings(fmt);
	res, output_string, error_string := run_command(..out, capture_and_return_output = true,, allocator = temp);

	engine.compilation_successful = false;

	if res.exit_code != 0 {
		ui.modal_error_message = copy_string(error_string);
		display_error_window(.FAILED_COMPILATION, "compilation failed");
		return;
	}

	engine.compilation_successful = true;
}

indirect_X :: (addr: u16) -> u16 {
	return read_address(cast(u16)read_data(addr) + cast(u16)engine.X);
}

indirect_Y :: (addr: u16) -> u16 {
	return read_address(read_data(addr)) + cast(u16)engine.Y;
}

compact_immediate :: (func: (u8)) {
	func(read_data(engine.PC));
	PC_advance(1);
}

compact_absolute_data :: (func: (u8)) {
	func(read_data(read_address(engine.PC)));
	PC_advance(2);
}

compact_zero_page_data :: (func: (u8)) {
	func(read_data(cast(u16)read_data(engine.PC)));
	PC_advance(1);
}

compact_ind_X_data :: (func: (u8)) {
	func(read_data(indirect_X(engine.PC)));
	PC_advance(1);
}

compact_ind_Y_data :: (func: (u8)) {
	func(read_data(indirect_Y(engine.PC)));
	PC_advance(1);
}

compact_zero_page_X_data :: (func: (u8)) {
	func(read_data((cast(u16)read_data(engine.PC) + cast(u16)engine.X) & 0xFF));
	PC_advance(1);
}

compact_zero_page_Y_data :: (func: (u8)) {
	func(read_data(cast(u16)read_data(engine.PC) + cast(u16)engine.Y));
	PC_advance(1);
}

compact_absolute_X_data :: (func: (u8)) {
	func(read_data(read_address(engine.PC) + cast(u16)engine.X));
	PC_advance(2);
}

compact_absolute_Y_data :: (func: (u8)) {
	func(read_data(read_address(engine.PC) + cast(u16)engine.Y));
	PC_advance(2);
}

compact_absolute_address :: (func: (u16)) {
	func(read_address(engine.PC));
	PC_advance(2);
}

compact_zero_page_address :: (func: (u16)) {
	func(cast(u16)read_data(engine.PC));
	PC_advance(1);
}

compact_indirect_address :: (func: (u16)) {
	func(read_address(read_address(engine.PC)));
	PC_advance(2);
}

compact_ind_X_address :: (func: (u16)) {
	func(indirect_X(engine.PC));
	PC_advance(1);
}

compact_ind_Y_address :: (func: (u16)) {
	func(indirect_Y(engine.PC));
	PC_advance(1);
}

compact_zero_page_X_address :: (func: (u16)) {
	func((cast(u16)read_data(engine.PC) + cast(u16)engine.X) & 0xFF);
	PC_advance(1);
}

compact_zero_page_Y_address :: (func: (u16)) {
	func(cast(u16)read_data(engine.PC) + cast(u16)engine.Y);
	PC_advance(1);
}

compact_absolute_X_address :: (func: (u16)) {
	func(read_address(engine.PC) + cast(u16)engine.X);
	PC_advance(2);
}

compact_absolute_Y_address :: (func: (u16)) {
	func(read_address(engine.PC) + cast(u16)engine.Y);
	PC_advance(2);
}

intrinsic_to_string :: (code: Opcode) -> string {
	info :: type_info(Opcode);
	
	c := cast(u8, code);
	s: string = ---;

	for info.values if it == c then s = info.names[it_index];

	if s.count == 3 then return s;
	else {
		t := s;
		t.data += 4;
		t.count -= 4;
		s.count = 3;
		// Todo - Quattro - check performance with `make_u24`
		if t == {
			case "IMM"; return tprint("% #n",     s);
			case "ZPG"; return tprint("% n",      s);
			case "ZPX"; return tprint("% n, X",   s);
			case "ZPY"; return tprint("% n, Y",   s);
			case "ABS"; return tprint("% nn",     s);
			case "ABX"; return tprint("% nn, X",  s);
			case "ABY"; return tprint("% nn, Y",  s);
			case "INX"; return tprint("% (n, X)", s);
			case "INY"; return tprint("% (n), Y", s);
			case "ACC"; return tprint("% A",      s);
			case;       return "";
		}
	}
}

Opcode :: enum u8 {
	BRK :: 0x00;
	NOP :: 0xEA;

	CLC :: 0x18; CLD :: 0xD8; CLI :: 0x58; CLV :: 0xB8;
	SEC :: 0x38; SED :: 0xF8; SEI :: 0x78;

	DEX :: 0xCA; DEY :: 0x88;
	INX :: 0xE8; INY :: 0xC8;

	PHA :: 0x48; PHP :: 0x08; PLA :: 0x68; PLP :: 0x28;

	RTI :: 0x40; RTS :: 0x60;

	TAX :: 0xAA; TAY :: 0xA8; TSX :: 0xBA; TXA :: 0x8A; TXS :: 0x9A; TYA :: 0x98;

	BIT_ABS :: 0x2C; BIT_ZPG :: 0x24;

	JMP_ABS :: 0x4C; JMP_IND :: 0x6C;
	JSR_ABS :: 0x20;

	BCC :: 0x90; BCS :: 0xB0; BEQ :: 0xF0; BNE :: 0xD0; BMI :: 0x30; BPL :: 0x10; BVC :: 0x50; BVS :: 0x70;

	INC_ABS :: 0xEE; INC_ZPG :: 0xE6; INC_ZPX :: 0xF6; INC_ABX :: 0xFE;
	DEC_ABS :: 0xCE; DEC_ZPG :: 0xC6; DEC_ZPX :: 0xD6; DEC_ABX :: 0xDE;

	STA_ABS :: 0x8D; STA_ZPG :: 0x85; STA_INX :: 0x81; STA_INY :: 0x91; STA_ZPX :: 0x95; STA_ABX :: 0x9D; STA_ABY :: 0x99;
	STX_ABS :: 0x8E; STX_ZPG :: 0x86; STX_ZPY :: 0x96;
	STY_ABS :: 0x8C; STY_ZPG :: 0x84; STY_ZPX :: 0x94;

	ADC_IMM :: 0x69; ADC_ABS :: 0x6D; ADC_ZPG :: 0x65; ADC_INX :: 0x61; ADC_INY :: 0x71; ADC_ZPX :: 0x75; ADC_ABX :: 0x7D; ADC_ABY :: 0x79;
	AND_IMM :: 0x29; AND_ABS :: 0x2D; AND_ZPG :: 0x25; AND_INX :: 0x21; AND_INY :: 0x31; AND_ZPX :: 0x35; AND_ABX :: 0x3D; AND_ABY :: 0x39;
	CMP_IMM :: 0xC9; CMP_ABS :: 0xCD; CMP_ZPG :: 0xC5; CMP_INX :: 0xC1; CMP_INY :: 0xD1; CMP_ABX :: 0xDD; CMP_ABY :: 0xD9;
	CPX_IMM :: 0xE0; CPX_ABS :: 0xEC; CPX_ZPG :: 0xE4;
	CPY_IMM :: 0xC0; CPY_ABS :: 0xCC; CPY_ZPG :: 0xC4;
	EOR_IMM :: 0x49; EOR_ABS :: 0x4D; EOR_ZPG :: 0x45; EOR_INX :: 0x41; EOR_INY :: 0x51; EOR_ZPX :: 0x55; EOR_ABX :: 0x5D; EOR_ABY :: 0x59;
	LDA_IMM :: 0xA9; LDA_ABS :: 0xAD; LDA_ZPG :: 0xA5; LDA_INX :: 0xA1; LDA_INY :: 0xB1; LDA_ZPX :: 0xB5; LDA_ABX :: 0xBD; LDA_ABY :: 0xB9;
	ORA_IMM :: 0x09; ORA_ABS :: 0x0D; ORA_ZPG :: 0x05; ORA_INX :: 0x01; ORA_INY :: 0x11; ORA_ZPX :: 0x15; ORA_ABX :: 0x1D; ORA_ABY :: 0x19;
	SBC_IMM :: 0xE9; SBC_ABS :: 0xED; SBC_ZPG :: 0xE5; SBC_INX :: 0xE1; SBC_INY :: 0xF1; SBC_ZPX :: 0xF5; SBC_ABX :: 0xFD; SBC_ABY :: 0xF9;

	LDX_IMM :: 0xA2; LDX_ABS :: 0xAE; LDX_ZPG :: 0xA6; LDX_ABY :: 0xBE; LDX_ZPY :: 0xB6;
	LDY_IMM :: 0xA0; LDY_ABS :: 0xAC; LDY_ZPG :: 0xA4; LDY_ZPX :: 0xB4; LDY_ABX :: 0xBC;

	ROR_ABS :: 0x6E; ROR_ZPG :: 0x66; ROR_ACC :: 0x6A; ROR_ZPX :: 0x76; ROR_ABX :: 0x7E;
	ROL_ABS :: 0x2E; ROL_ZPG :: 0x26; ROL_ACC :: 0x2A; ROL_ZPX :: 0x36; ROL_ABX :: 0xE3;
	LSR_ABS :: 0x4E; LSR_ZPG :: 0x46; LSR_ACC :: 0x4A; LSR_ZPX :: 0x56; LSR_ABX :: 0x5E;
	ASL_ABS :: 0x0E; ASL_ZPG :: 0x06; ASL_ACC :: 0x0A; ASL_ZPX :: 0x16; ASL_ABX :: 0x1E;
}
